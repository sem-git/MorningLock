//
//  AlarmSettingViewModel.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import Combine
import SwiftUI

final class AlarmSettingViewModel: ObservableObject {
    @Published private(set) var weekDays: Set<Weekday> = []
    @Published private(set) var isEditing: Bool = false
    @Published var alarm: AlarmEntity
    
    private let alarmManager: AlarmManager
    private let savedAlarm: AlarmEntity
    
    // 시간, 반복날짜 비교
    var buttonDisabled: Bool {
        isEditing && (weekDays == Set(savedAlarm.repeatDay) && alarm.fireDate == savedAlarm.fireDate)
    }
    
    init(
        alarm: AlarmEntity? = nil,
        alarmManager: AlarmManager = .shared
    ) {
        self.alarmManager = alarmManager
        self.isEditing = alarm != nil
        let alarm = alarm ?? .init()
        self.alarm = alarm
        self.weekDays = Set(alarm.repeatDay)
        self.savedAlarm = alarm
    }
    
    func selecteDay(_ day: Weekday) {
        if weekDays.contains(day) {
            weekDays.remove(day)
        } else {
            weekDays.insert(day)
        }
    }
    
    func saveAlarm() async {
        alarm.repeatDay = Array(weekDays)
        await alarmManager.addAlarm(alarm)
    }
    
    func updateAlarm() {
        // 날짜를 수정한 경우
        let oldWeekDays = Set(alarm.repeatDay)
        let removedWeekDay = oldWeekDays.subtracting(weekDays)
        let addWeekDay = weekDays.union(oldWeekDays).subtracting(removedWeekDay)
        
        alarm.repeatDay = Array(addWeekDay)
        alarmManager.updateAlarm(alarm)
        
    }
}
