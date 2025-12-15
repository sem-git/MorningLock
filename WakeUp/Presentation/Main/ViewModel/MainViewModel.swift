//
//  MainViewModel.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import Combine
import SwiftUI
import AppTrackingTransparency

enum MainRoute: Hashable {
    case alarmSetting(AlarmEntity?)
}

class MainViewModel: ObservableObject {
    @Published var alarmList: [AlarmEntity] = []
    @Published var path: [MainRoute] = []
    @Published var alarmSheetPresented = false
    @Published var snoozeCount = 1
    @Published var snoozeTime: TimeInterval = .minutes(5)
    
    private let dataManager: CoreDataManager
    private let alarmManager: AlarmManager
    private let notificationManager: NotificationManager
    
    private var cancellables = Set<AnyCancellable>()
    
    var snoozeDisabled: Bool { snoozeCount == 3 }
    
    init(
        dataManager: CoreDataManager = .shared,
        alarmManager: AlarmManager = .shared,
        notificationManager: NotificationManager = .shared
    ) {
        self.dataManager = dataManager
        self.alarmManager = alarmManager
        self.notificationManager = notificationManager
        bind()
    }
    
    func bind() {
        Publishers.CombineLatest(
            alarmManager.$isAlarmPlaying,
            alarmManager.$isOpenSheet
        )
        .receive(on: RunLoop.main)
        .map { $0 && $1 }
        .assign(to: \.alarmSheetPresented, on: self)
        .store(in: &cancellables)
        
        alarmManager.$snoozeCount
            .receive(on: RunLoop.main)
            .assign(to: \.snoozeCount, on: self)
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
            .sorted { $0.time.getTime < $1.time.getTime }
    }
    
    func updateAlarm(_ alarm: AlarmEntity) {
        alarmManager.updateAlarm(alarm)
    }
    
    func deleteAlarm(_ id: UUID) {
        alarmManager.removeAlarm(id)
    }
    
    func deactiveAlarm() {
        alarmManager.deactiveAlarm()
    }
    
    func snoozeAlarm() {
        alarmManager.snoozeAlarm(by: snoozeTime)
    }
    
    func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { _ in
            
        }
    }
}

