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
    @Published var alarmSheetPresented = false
    
    private let dataManager: CoreDataManager
    private let alarmManager: AlarmManager
    private let notificationManager: NotificationManager
    
    private var cancellables = Set<AnyCancellable>()
    
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
        alarmManager.$isAlarmPlaying
            .receive(on: RunLoop.main)
            .assign(to: \.alarmSheetPresented, on: self)
            .store(in: &cancellables)
    }
    
    func navigateToAlarmSetting(_ alarm: AlarmEntity? = nil) {
        path.append(.alarmSetting(alarm))
    }
    
    func requestPermission() {
        Task {
            await notificationManager.requestAuthorization()
        }
    }
    
    // 데이터를 가져왔을떄 -> isActive 상태에 따라서 초기값 바인딩
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
    
    func snoozeAlarm(by interval: TimeInterval) {
        alarmManager.snoozeAlarm(by: interval)
    }
}

