//
//  Alarm+Mapper.swift
//  WakeUp
//
//  Created by a on 11/22/25.
//

extension Array where Element == Alarm {
    func toEntities() -> [AlarmEntity] {
        map {
            AlarmEntity(
                id: $0.id,
                time: $0.time,
                isActive: $0.isActive,
                repeatDay: $0.repeatDay.map({
                    Weekday(rawValue: $0)!
                })
            )
        }
    }
}

