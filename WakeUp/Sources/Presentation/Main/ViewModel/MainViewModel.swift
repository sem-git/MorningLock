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
    @Published var path: [MainRoute] = []
    @Published var isAlarmSheetPresented = false
    @Published var snoozeCount = 1
    @Published var snoozeTime: TimeInterval = .minutes(5)
    @Published var snoozeDisabled: Bool = false
    @Published var isWebViewPresented: Bool = false
    @Published var isAppSelectionPresented: Bool = false
    
    private let dataManager: CoreDataManager
    private let alarmManager: AlarmManager
    private let notificationManager: NotificationManager
    private let deviceActivityManager: DeviceActivityManager
    private let store: StoreKitManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.dataManager = .shared
        self.alarmManager = .shared
        self.notificationManager = .shared
        self.deviceActivityManager = .shared
        self.store = .shared
        bind()
    }
    
    func bind() {
        // 알람이 재생중이면서 isOpenSheet 보임여부에 따라서 Sheet열기
        alarmManager.$isAlarmPlaying
            .receive(on: RunLoop.main)
            .assign(to: \.isAlarmSheetPresented, on: self)
            .store(in: &cancellables)
        
        // 스누즈 횟수
        alarmManager.$snoozeCount
            .receive(on: RunLoop.main)
            .assign(to: \.snoozeCount, on: self)
            .store(in: &cancellables)
        
        // 알람이 울리는 중이거나 스누즈 횟수가 3회이상 초과시 버튼 disable
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
    
    func navigateToAlarmSetting(_ alarm: AlarmEntity? = nil) {
        path.append(.alarmSetting(alarm))
    }
    
    // 데이터를 가져왔을 때 isActive 상태에 따라서 초기값 바인딩
    func fetchAlarm() {
        alarmList = dataManager
            .fetchAlarm()
            .toEntities()
            .sorted { $0.fireDate.nextOccurrenceIncludingSeconds < $1.fireDate.nextOccurrenceIncludingSeconds }
    }
    
    func updateAlarm(_ alarm: AlarmEntity) {
        if alarm.isActive, deviceActivityManager.selectedApp == nil {
            isAppSelectionPresented = true
        }
        alarmManager.updateAlarm(alarm)
    }
    
    func deleteAlarm(withId id: UUID) {
        alarmManager.removeAlarm(withId: id)
    }
    
    func deactiveAlarm() {
        alarmManager.deactiveAlarm()
        if deviceActivityManager.selectedApp != nil {
            deviceActivityManager.startMonitoring(startAt: .now)
            notificationManager.postDelayNotification(
                after: .minutes(15),
                title: NSLocalizedString("MorningUnlockedNotificationTitle", comment: "의지가 깨어나는 시간"),
                body: NSLocalizedString("MorningUnlockedNotificationSubTitle", comment: "설정된 시간이 지나 앱 잠금이 해제되었습니다. 오늘의 시작을 응원할게요.")
            )
        }
    }
    
    func snoozeAlarm() {
        alarmManager.snoozeAlarm(by: snoozeTime)
    }
    
    func toggleWebView() {
        isWebViewPresented.toggle()
    }
    
    func toggleAppSelection() {
        isAppSelectionPresented.toggle()
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
    func handleAppLockTap(
        permissionManager: PermissionManager,
        onAuthorized: @escaping () -> Void
    ) async {
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
        
        guard let product = store.products.first(
            where: { $0.id == type.productId }
        ) else {
            print("Product 없음:", type.productId)
            return
        }
        
        await store.purchase(product)
    }
}

