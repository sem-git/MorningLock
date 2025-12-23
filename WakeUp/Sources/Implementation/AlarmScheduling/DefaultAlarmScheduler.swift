//
//  DefaultAlarmScheduler.swift
//  WakeUp
//
//  Created by a on 12/19/25.
//

import Combine
import Foundation

final class DefaultAlarmScheduler: AlarmScheduler {
        
    private var alarmQueue: AlarmQueue!
    
    private(set) var scheduledAlarm = CurrentValueSubject<AlarmEntity?, Never>(nil)
    
    init() {}
 
    func buildQueue(with alarms: [AlarmEntity]) {
        alarmQueue = AlarmQueue(sort: .upcomingDate)
        alarms.forEach { alarm in
            guard alarm.isActive else { return }
            var updated = alarm
            updated.fireDate = calculateNextFireDate(for: alarm)
            alarmQueue.insert(updated)
        }
    }
    
    func schedule() {
        if let currentAlarm = alarmQueue.delete() {
            scheduledAlarm.send(currentAlarm)
        } else {
            scheduledAlarm.send(nil)
        }
    }
    
    func insert(_ alarm: AlarmEntity) {
        guard alarm.isActive else { return }
        var updated = alarm
        updated.fireDate = calculateNextFireDate(for: alarm)
        alarmQueue.insert(updated)
        schedule()
    }
    
    // 오늘을 기준으로 가장 빠르게 울리는 알람 시간을 계산합니다.
    private func calculateNextFireDate(for alarm: AlarmEntity) -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        // fireDate의 시간, 분, 초를 오늘 날짜 시간으로 지정
        let fireDateComponents = calendar.dateComponents([.hour, .minute, .second],from: alarm.fireDate)
        var todayComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        todayComponents.calendar = calendar
        todayComponents.hour = fireDateComponents.hour
        todayComponents.minute = fireDateComponents.minute
        todayComponents.second = fireDateComponents.second
        
        let currentDate = todayComponents.date!
        
        // 반복여부가 없는 경우 현재 날짜를 그대로 리턴
        if alarm.repeatDay.isEmpty {
            return currentDate > now ? currentDate : calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        let todayWeekday = calendar.component(.weekday, from: now)
        let repeatDays = alarm.repeatDay.map({ $0.rawValue })
        var minDiff: Int?

        // 오늘을 기준으로 가장 가까운 요일 선택
        for day in repeatDays {
            var diff = (day - todayWeekday + 7) % 7
            
            if diff == 0 && currentDate <= now {
                diff = 7
            }

            minDiff = min(minDiff ?? diff, diff)
        }

        return calendar.date(
            byAdding: .day,
            value: minDiff ?? 0,
            to: currentDate
        )!
    }
}



