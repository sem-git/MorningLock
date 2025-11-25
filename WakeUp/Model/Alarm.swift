//
//  Alarm.swift
//  WakeUp
//
//  Created by a on 10/20/25.
//

import Foundation
import UserNotifications
import SwiftUI

struct AlarmEntity: Hashable, Identifiable {
    var id: UUID
    var time: Date
    var isActive: Bool
    var repeatDay: [Weekday]
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm"
        let dateString = formatter.string(from: time)
        return dateString
    }
    
    var meridiem: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "a"
        let meridiem = formatter.string(from: time)
        return meridiem
    }
    
    var isDueToday: Bool {
        repeatDay.hasToday || repeatDay.isEmpty
    }
}

extension AlarmEntity: Comparable {
    static func < (lhs: AlarmEntity, rhs: AlarmEntity) -> Bool {
        lhs.time < rhs.time
    }
}
