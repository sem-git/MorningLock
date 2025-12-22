//
//  AlarmScheduler.swift
//  WakeUp
//
//  Created by a on 12/20/25.
//

import Combine

protocol AlarmScheduler {
    var scheduledAlarm: CurrentValueSubject<AlarmEntity?, Never> { get }

    func buildQueue(with alarms: [AlarmEntity])
    func schedule()
    func insert(_ alarm: AlarmEntity)
}

extension AlarmScheduler where Self == DefaultAlarmScheduler {
    static var `default`: Self { DefaultAlarmScheduler() }
}
extension AlarmScheduler where Self == TestAlarmScheduler {
    static var test: Self { TestAlarmScheduler() }
}
