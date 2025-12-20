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
    var fireDate: Date
    var isActive: Bool
    var repeatDay: [Weekday]
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm"
        let dateString = formatter.string(from: fireDate)
        return dateString
    }
    
    var meridiem: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "a"
        let meridiem = formatter.string(from: fireDate)
        return meridiem
    }
    
    init(
        id: UUID = .init(),
        fireDate: Date = .now,
        isActive: Bool = true,
        repeatDay: [Weekday] = []
    ) {
        self.id = id
        self.fireDate = fireDate
        self.isActive = isActive
        self.repeatDay = repeatDay
    }
}

extension AlarmEntity: Comparable {
    static func < (lhs: AlarmEntity, rhs: AlarmEntity) -> Bool {
        lhs.fireDate < rhs.fireDate
    }        
}
