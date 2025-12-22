//
//  Day.swift
//  WakeUp
//
//  Created by a on 10/15/25.
//

import Foundation

enum Weekday: Int, CaseIterable {
    case sun = 1, mon, tue, wed, thu, fri, sat
}

extension Weekday {
    
    static var allCases: [Weekday] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return Calendar.current.weekdaySymbols.enumerated().compactMap { index, _ in
            return Weekday(rawValue: index + 1) // 1부터 시작해야 함
        }
    }
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        return formatter.veryShortWeekdaySymbols[self.rawValue - 1]
    }
}

extension Array where Element == Weekday {
    var hasToday: Bool {
        let today = Calendar.current.dateComponents([.weekday], from: Date()).weekday ?? 0
           return self.map { $0.rawValue }.contains(today)
    }
}

