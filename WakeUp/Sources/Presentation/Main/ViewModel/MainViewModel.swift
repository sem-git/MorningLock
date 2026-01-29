//
//  MainViewModel.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import Combine
import SwiftUI
import AppTrackingTransparency
import StoreKit

enum MainRoute: Hashable {
    case alarmSetting(AlarmEntity?)
}

@MainActor
class MainViewModel: ObservableObject {
    @Published var alarmList: [AlarmEntity] = []
    @Published var isAlarmSheetPresented = false
    @Published var snoozeCount = 1
    @Published var snoozeTime: TimeInterval = .minutes(5)
    @Published var snoozeDisabled: Bool = false
    
    @Published var path: [MainRoute] = []
    
    @Published var isContactFormPresented: Bool = false
    @Published var showLockSuggestionSheet: Bool = false
    @Published var isLockSkipSheetPresented: Bool = false
    
    private let coreDataManager: CoreDataManager
    private let alarmManager: AlarmManager
    private let notificationManager: NotificationManager
    private let deviceActivityManager: DeviceActivityManager
    private let storeKitManager: StoreKitManager
    
    private var cancellables = Set<AnyCancellable>()
    
    private var alarmTimeoutTask: Task<Void, Never>?
    private let alarmMaxWaitingTime: TimeInterval = .minutes(20) // 1시간으로 변경 예정
    
    init() {
        self.coreDataManager = .shared
        self.alarmManager = .shared
        self.notificationManager = .shared
        self.deviceActivityManager = .shared
        self.storeKitManager = .shared
        
        bind()
    }
    
    // MARK: - 알람
    
    func bind() {
        // 알람이 재생 중이면서 isOpenSheet 보임 여부에 따라서 Sheet 열기
        alarmManager.$isAlarmPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] isPlaying in
                guard let self else { return }
                self.isAlarmSheetPresented = isPlaying
                
                if isPlaying {
                    self.startAlarmTimeout()
                } else {
                    self.cancelAlarmTimeout()
                }
            }
            .store(in: &cancellables)
        
        // 스누즈 횟수
        alarmManager.$snoozeCount
            .receive(on: RunLoop.main)
            .assign(to: \.snoozeCount, on: self)
            .store(in: &cancellables)
        
        // 알람이 울리는 중이거나 스누즈 횟수가 3회 이상 초과 시 버튼 disabled
        Publishers.CombineLatest(
            alarmManager.$isSnoozeActive,
            alarmManager.$snoozeCount
        )
        .receive(on: RunLoop.main)
        .map { isSnoozeActive, snoozeCount in
            isSnoozeActive || snoozeCount >= 3
        }
        .assign(to: \.snoozeDisabled, on: self)
        .store(in: &cancellables)
    }
    
    /// 데이터를 가져왔을 때 isActive 상태에 따라서 초기 값 바인딩
    func fetchAlarm() {
        alarmList = coreDataManager
            .fetchAlarm()
            .toEntities()
            .sorted { $0.fireDate.nextOccurrenceIncludingSeconds < $1.fireDate.nextOccurrenceIncludingSeconds }
    }
    
    func updateAlarm(_ alarm: AlarmEntity) {
        if alarm.isActive, !deviceActivityManager.hasSelectedApps {
            showLockSuggestionSheet = true
        }
        alarmManager.updateAlarm(alarm)
    }
    
    func deleteAlarm(withId id: UUID) {
        alarmManager.removeAlarm(withId: id)
    }
    
    func deactiveAlarm() {
        alarmManager.deactiveAlarm()
        if deviceActivityManager.hasSelectedApps {
            deviceActivityManager.startMonitoring(startAt: .now)
            notificationManager.postDelayNotification(
                after: .minutes(15),
                title: String(localized: "의지가 깨어나는 시간"),
                body: String(localized: "설정된 시간이 지나 앱 잠금이 해제되었습니다 오늘의 시작을 응원할게요")
            )
        }
    }
    
    func snoozeAlarm() {
        alarmManager.snoozeAlarm(by: snoozeTime)
    }
    
    // MARK: - 그 외
    
    func navigateToAlarmSetting(_ alarm: AlarmEntity? = nil) {
        path.append(.alarmSetting(alarm))
    }
    
    func requestTrackingAuthorization() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .notDetermined:
                    print("App Tracking Transparency: notDetermined")
                case .restricted:
                    print("App Tracking Transparency: restricted")
                case .denied:
                    print("App Tracking Transparency: denied")
                case .authorized:
                    print("App Tracking Transparency: authorized")
                @unknown default:
                    print("Unknow")
                }
            }
        }
    }
    
    @MainActor
    func handleAppLockTap(permissionManager: PermissionManager, onAuthorized: @escaping () -> Void) async {
        switch permissionManager.screenTimeStatus {
        case .authorized:
            onAuthorized()
            
        case .unknown, .denied:
            await permissionManager.requestScreenTime()
            if permissionManager.screenTimeStatus == .authorized {
                onAuthorized()
            }
        }
    }
    
    @MainActor
    func purchaseSubscription(type: SubscriptionType?) async {
        guard let type else { return }
        
        guard let product = storeKitManager.products.first(
            where: { $0.id == type.productId }
        ) else {
            print("Product 없음:", type.productId)
            return
        }
        
        await storeKitManager.purchase(product)
    }
    
    private func startAlarmTimeout() {
        cancelAlarmTimeout()
        
        alarmTimeoutTask = Task { [weak self] in
            guard let self else { return }
            
            try? await Task.sleep(
                nanoseconds: UInt64(alarmMaxWaitingTime * 1_000_000_000)
            )
            
            if self.isAlarmSheetPresented {
                self.deactiveAlarmWithoutLock()
            }
        }
    }
    
    private func cancelAlarmTimeout() {
        alarmTimeoutTask?.cancel()
        alarmTimeoutTask = nil
    }
    
    private func deactiveAlarmWithoutLock() {
        alarmManager.deactiveAlarm()
        
        isAlarmSheetPresented = false
        isLockSkipSheetPresented = true
    }
}
