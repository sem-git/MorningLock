//
//  MainViewModel.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import Combine
import SwiftUI

enum MainRoute: Hashable {
    case alarmSetting(AlarmEntity?)
}

class MainViewModel: ObservableObject {
    @Published var alarmList: [AlarmEntity] = []
    @Published var path: [MainRoute] = []
    @Published var isAlarmSheetPresented = false
    @Published var snoozeCount = 1
    @Published var snoozeTime: TimeInterval = .minutes(5)
    @Published var snoozeDisabled: Bool = false
    @Published var isWebViewPresented: Bool = false
    
    private let dataManager: CoreDataManager
    private let alarmManager: AlarmManager
    private let notificationManager: NotificationManager
    private let deviceActivityManager: DeviceActivityManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        dataManager: CoreDataManager = .shared,
        alarmManager: AlarmManager = .shared,
        notificationManager: NotificationManager = .shared,
        deviceActivityManager: DeviceActivityManager = .shared
    ) {
        self.dataManager = dataManager
        self.alarmManager = alarmManager
        self.notificationManager = notificationManager
        self.deviceActivityManager = deviceActivityManager
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
        alarmManager.updateAlarm(alarm)
    }
    
    func deleteAlarm(withId id: UUID) {
        alarmManager.removeAlarm(withId: id)
    }
        
    func deactiveAlarm() {
        alarmManager.deactiveAlarm()
        if deviceActivityManager.selectedApp != nil {
            deviceActivityManager.startMonitoring(startAt: .now)
            deviceActivityManager.commitSelectionWhileLocking()
        }
    }
    
    func snoozeAlarm() {
        alarmManager.snoozeAlarm(by: snoozeTime)
    }
    
    func toggleWebView() {
        isWebViewPresented.toggle()
    }
}

