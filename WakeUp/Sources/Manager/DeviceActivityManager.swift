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

    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    
    var lockDuration: TimeInterval { .minutes(15) }

    // 사용자가 선택 중인 상태
    @Published var selection = FamilyActivitySelection(includeEntireCategory: true)
    // 사용자 선택 확정 상태
    @Published private(set) var committedSelection = FamilyActivitySelection()
    // 남은 잠금 시간과 비율
    @Published var remainingTime: TimeInterval = .zero
    @Published var percent: Double = 0
    
    // 잠금 종료 시간
    private var endTime = Date()
    // 잠금 기준 스냅샷
    private(set) var currentLockedSnapshot: Set<ApplicationToken> = []
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    
    /// 잠금 여부
    var isLockingNow: Bool { Date() < endTime }
    
    /// 확정 상태의 선택된 앱
    var selectedApps: [ApplicationToken] { Array(committedSelection.applicationTokens) }
    
    /// 확정 상태의 선택된 앱 존재 여부
    var hasSelectedApps: Bool { !committedSelection.applicationTokens.isEmpty }
    
    /// 잠금 중 selection 변경 시 완료 버튼 활성화 여부
    var canSaveSelectionWhileLocking: Bool {
        let current = selection.applicationTokens
        return currentLockedSnapshot.isSubset(of: current) && current != currentLockedSnapshot
    }
    
    // MARK: - Initializer
    
    private init() {
        restoreLockState()
        bindAppGroupStorage()
    }
    
    // MARK: - 앱 선택 관리
    
    /// 사용자 선택 완료 시 잠금 앱 저장, 잠금 중 여부에 따라 즉시 적용
    func saveSelection(applyImmediately: Bool = false) {
        committedSelection = selection
        currentLockedSnapshot = selection.applicationTokens
        
        if let container = UserDefaults.sharedAppGroup {
            container.appLockState = AppLockState(endTime: endTime, selection: selection)
        }
        
        if applyImmediately {
            applyShield()
        }
    }
    
    /// 잠금 앱 초기화
    func clearSelection() {
        stopMonitoring()
        if let container = UserDefaults.sharedAppGroup {
            container.saveAppLockSelection(AppSelection(selection: .init()))
        }
        selection = .init()
    }
    
    /// 잠금 앱 불러오기
    private func bindAppGroupStorage() {
        guard let container = UserDefaults.sharedAppGroup else { return }
        
        if container.loadAppLockSelection() == nil {
            container.saveAppLockSelection(AppSelection(selection: .init()))
        }
        
        container.publisher(for: \.appLockSelectionData)
            .decode(type: AppSelection.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { model in
                    self.committedSelection = model.selection
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 잠금 관리
    
    /// 모니터링 시작
    func startMonitoring(startAt date: Date) {
        center.stopMonitoring([.appLockActivity])
        
        let end = date.addingTimeInterval(lockDuration)
        let startComponents = date.fullComponents
        let endComponents = end.fullComponents
        
        endTime = end
        saveSelection()
        persistLockState()
        
        do {
            try center.startMonitoring(
                .appLockActivity,
                during: DeviceActivitySchedule(
                    intervalStart: startComponents,
                    intervalEnd: endComponents,
                    repeats: false
                ),
                events: [:]
            )
        } catch {
            print("DeviceActivity 모니터링 실패:", error)
        }
    }
    
    /// 모니터링 중지
    func stopMonitoring() {
        center.stopMonitoring([.appLockActivity])
        stopLockTimer()
        if let container = UserDefaults.sharedAppGroup {
            container.appLockState = nil
        }
        currentLockedSnapshot = []
        print("DeviceActivity 모니터링 중단")
    }
    
    // 앱 잠금 적용
    private func applyShield() {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }
    
    // 잠금 상태 지속
    private func persistLockState() {
        if let container = UserDefaults.sharedAppGroup {
            container.appLockState = AppLockState(endTime: endTime, selection: selection)
        }
    }
    
    // 잠금 상태 복구
    private func restoreLockState() {
        guard let container = UserDefaults.sharedAppGroup, let state = container.appLockState else { return }
        guard state.endTime > Date() else {
            container.appLockState = nil
            return
        }
        
        endTime = state.endTime
        selection = state.selection
        currentLockedSnapshot = state.selection.applicationTokens
    }
    
    // MARK: - 타이머 및 UI 표시
    
    /// 잠금 타이머 시작
    func startLockTimer() {
        stopLockTimer()
        
        let totalTime = lockDuration
        
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
    
    /// 잠금 타이머 종료
    func stopLockTimer() {
        timer?.cancel()
        timer = nil
    }
}

extension DeviceActivityName {
    static let appLockActivity = Self("appLockActivity")
}
