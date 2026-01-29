//
//  DeviceActivityManager.swift
//  WakeUp
//
//  Created by 이세민 on 1/30/26.
//

import Combine
import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

final class DeviceActivityManager: ObservableObject {
    static let shared = DeviceActivityManager()
    
    // MARK: - AppGruop Store
    
    // 앱그룹 저장소
    private let sharedContainer = UserDefaults(suiteName: "group.com.awayke")
    //
    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    private let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
        .encouraged: DeviceActivityEvent(
            threshold: DateComponents(minute: 15)
        )
    ]
    /// 기본 앱 잠금 시간
    private let appLockDurationMinutes = 15
    
    // MARK: - Properties
    
    /// 앱 잠금 종료 시간 기록
    private var endTime = Date()
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    
    /// 앱 잠금 여부
    var isLockingNow: Bool { Date() < endTime }
    /// 앱 잠금 저장 버튼 활성화 여부
    var canSaveSelectionWhileLocking: Bool {
        let current = selection.applicationTokens
        let base = currentLockedSnapshot
        
        guard base.isSubset(of: current) else {
            return false
        }
        
        guard current != base else {
            return false
        }
        
        return true
    }
    
    // MARK: - State
    
    var selectedApps: [ApplicationToken] {
        Array(selection.applicationTokens)
    }

    var hasSelectedApps: Bool {
        !selection.applicationTokens.isEmpty
    }

    /// 사용자가 선택한 앱
    @Published var selection = FamilyActivitySelection(includeEntireCategory: true)
    /// 앱 잠금 남은 시간
    @Published var remainingTime: TimeInterval = .zero
    /// 앱 잠금 남은 시간 표시용
    @Published var percent: Double = 0
    /// 잠금 중 기준이 되는 현재 잠금 앱 스냅샷
    private(set) var currentLockedSnapshot: Set<ApplicationToken> = []
    
    private init() {
        restoreLockState()
        dataBind()
    }
    
    // MARK: - 선택 관리
    
    /// 앱그룹 저장소에 잠금 앱 저장
    func save() {
        let model = AppModel(selection: selection)
        do {
            let data = try JSONEncoder().encode(model)
            sharedContainer?.set(data, forKey: StringLiteral.UserDefaultKeys.appGroupStorageKey)
            print("앱 잠금 선택 저장 완료")
        } catch {
            print("선택 저장 실패:", error)
        }
    }
    
    /// 잠금 앱 초기화
    func clear() {
        stopMonitoring()
        sharedContainer?.removeObject(forKey: StringLiteral.UserDefaultKeys.appGroupStorageKey)
        selection = .init()
    }
    
    /// 잠금 앱 불러오기
    private func dataBind() {
        if let container = sharedContainer {
            if container.value(forKey: StringLiteral.UserDefaultKeys.appGroupStorageKey) == nil {
                // 처음에 저장소가 존재하지 않는 경우 초기화
                let defaultAppModel = AppModel(selection: .init())
                if let data = try? JSONEncoder().encode(defaultAppModel) {
                    container.set(data, forKey: StringLiteral.UserDefaultKeys.appGroupStorageKey)
                }
            }
            
            container
                .publisher(for: \.appGroupStorageKey)
                .decode(type: AppModel.self, decoder: JSONDecoder())
                .map { Array($0.selection.applicationTokens) }
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { value in
                    self.selection.applicationTokens = Set(value)
                })
                .store(in: &cancellables)
        }
    }
    
    // MARK: - 잠금 시작과 종료
    
    /// 모니터링 시작
    func startMonitoring(startAt date: Date) {
        center.stopMonitoring([.testName])
        let end = Calendar.current.date(byAdding: .minute, value: appLockDurationMinutes, to: date)!
        
        let startComponents = fullDateComponents(from: date)
        let endComponents = fullDateComponents(from: end)
        
        // 스냅샷에 현재 선택한 앱 토큰을 저장하고
        currentLockedSnapshot = selection.applicationTokens
        endTime = end
        persistLockState()
        
        do {
            try center.startMonitoring(
                .testName,
                during: DeviceActivitySchedule(
                    intervalStart: startComponents,
                    intervalEnd: endComponents,
                    repeats: false
                ),
                events: events
            )
            endTime = end
        } catch {
            print("DeviceActivity 모니터링 실패:", error)
        }
    }
    
    /// 모니터링 중지
    func stopMonitoring() {
        center.stopMonitoring([.testName])
        timer = nil
        sharedContainer?.removeObject(forKey: StringLiteral.UserDefaultKeys.appLockStateKey)
        currentLockedSnapshot = []
        print("DeviceActivity 모니터링 중단")
    }
    
    // MARK: - 잠금 중 앱 추가
    
    /// 추가 잠금 앱 스냅샷 갱신
    func commitSelectionWhileLocking() {
        save()
        applyShieldImmediately()
        currentLockedSnapshot = selection.applicationTokens
        persistLockState()
    }
    
    func unblockApps() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
    
    /// 추가 잠금 앱 바로 적용
    func applyShieldImmediately() {
        store.shield.applications =
        selection.applicationTokens.isEmpty
        ? nil
        : selection.applicationTokens
        
        store.shield.applicationCategories =
        selection.categoryTokens.isEmpty
        ? nil
        : .specific(selection.categoryTokens)
        
        store.shield.webDomains =
        selection.webDomainTokens.isEmpty
        ? nil
        : selection.webDomainTokens
    }
    
    // MARK: - 상태 저장 및 복구
    
    /// 잠금 상태를 앱그룹에 저장
    private func persistLockState() {
        let state = LockState(
            endTime: endTime,
            selection: selection
        )
        
        if let data = try? JSONEncoder().encode(state) {
            sharedContainer?.set(data, forKey: StringLiteral.UserDefaultKeys.appLockStateKey)
        }
    }
    
    /// 앱 재실행 시 잠금 상태 복구
    private func restoreLockState() {
        guard
            let data = sharedContainer?.data(forKey: StringLiteral.UserDefaultKeys.appLockStateKey),
            let state = try? JSONDecoder().decode(LockState.self, from: data)
        else { return }
        
        guard state.endTime > Date() else {
            sharedContainer?.removeObject(forKey: StringLiteral.UserDefaultKeys.appLockStateKey)
            return
        }
        
        endTime = state.endTime
        selection = state.selection
        currentLockedSnapshot = state.selection.applicationTokens
    }
    
    // MARK: - 타이머 및 UI 표시
    
    /// 남은 잠금 시간 계산
    func startLockTimer() {
        stopLockTimer()
        
        let totalTime = TimeInterval(minutes: appLockDurationMinutes)
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                
                self.remainingTime = max(self.endTime.timeIntervalSinceNow, 0)
                self.percent = (self.remainingTime / totalTime) * 100
                
                if self.remainingTime <= 0 {
                    self.stopLockTimer()
                }
            }
    }
    
    /// 타이머 종료
    func stopLockTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func fullDateComponents(from date: Date) -> DateComponents {
        Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
    }
}

extension DeviceActivityName {
    static let testName = Self("testName")
}

extension DeviceActivityEvent.Name {
    static let encouraged = Self("encouraged")
}

extension UserDefaults {
    @objc var appGroupStorageKey: Data {
        get {
            return data(forKey: StringLiteral.UserDefaultKeys.appGroupStorageKey) ?? Data()
        }
        set {
            set(newValue, forKey: StringLiteral.UserDefaultKeys.appGroupStorageKey)
        }
    }
}
