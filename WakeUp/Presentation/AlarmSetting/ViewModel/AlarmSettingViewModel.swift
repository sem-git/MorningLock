//
//  AlarmSettingViewModel.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import Combine
import SwiftUI

final class AlarmSettingViewModel: ObservableObject {
    @Published var weekDays: Set<Weekday> = []
    @Published var time = Date()
    
    var alarm: AlarmEntity?
        
    private let alarmManager: AlarmManager
    
    init(alarm: AlarmEntity? = nil, alarmManager: AlarmManager = AlarmManager.shared) {
        self.alarmManager = alarmManager
        self.alarm = alarm
        self.time = alarm?.time ?? Date()
        self.weekDays = Set(alarm?.repeatDay ?? [])
    }
    
    func selecteDay(_ day: Weekday) {
        if weekDays.contains(day) {
            weekDays.remove(day)
        } else {
            weekDays.insert(day)
        }
    }
    
    func saveAlarm() async {
        let alarmEntity = AlarmEntity(
            id: UUID(),
            time: time,
            isActive: true,
            repeatDay: Array(weekDays)
        )
                
        await alarmManager.addAlarm(alarmEntity)        
    }
    
    func updateAlarm() {
        if let alarm {
            var updateAlarm = alarm
            updateAlarm.time = time
            
            // 날짜를 수정한경우
            let oldWeekDays = Set(updateAlarm.repeatDay)
            let removedWeekDay = oldWeekDays.subtracting(weekDays)
            let addWeekDay = weekDays.union(oldWeekDays).subtracting(removedWeekDay)
            
            updateAlarm.repeatDay = Array(addWeekDay)
                       
            alarmManager.updateAlarm(updateAlarm)
        }
    }
}
