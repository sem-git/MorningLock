//
//  DefaultAlarmScheduler.swift
//  WakeUp
//
//  Created by a on 12/19/25.
//

import Combine

protocol AlarmScheduler {
    var scheduledAlarm: CurrentValueSubject<AlarmEntity?, Never> { get }

    func buildQueue(with alarms: [AlarmEntity])
    func scheduleAlarm()
    func insert(_ alarm: AlarmEntity)
}

final class DefaultAlarmScheduler: AlarmScheduler {
    
    private let sortOption: QueueSortOption
        
    private var alarmQueue: AlarmQueue!
    
    private(set) var scheduledAlarm = CurrentValueSubject<AlarmEntity?, Never>(nil)
    
    init(sortOption: QueueSortOption = .upcoming) {
        self.alarmQueue = AlarmQueue(sort: sortOption)
        self.sortOption = sortOption
    }
 
    func buildQueue(with alarms: [AlarmEntity]) {
        alarmQueue = AlarmQueue(sort: sortOption)
        alarms.forEach { alarmQueue.insert($0) }
    }
        
    func scheduleAlarm() {
        // 가장 빠른 알람 가져오기
        while let currentAlarm = alarmQueue.delete() {
            if currentAlarm.isActive {
                scheduledAlarm.send(currentAlarm)
                break
            }
        }
    }
    
    func insert(_ alarm: AlarmEntity) {
        alarmQueue.insert(alarm)
        scheduleAlarm()
    }        
}

extension AlarmScheduler where Self == DefaultAlarmScheduler {
    static var `default`: Self { DefaultAlarmScheduler() }
}
