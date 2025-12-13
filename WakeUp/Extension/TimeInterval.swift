//
//  TimeInterval.swift
//  WakeUp
//
//  Created by a on 11/24/25.
//

import Foundation

extension TimeInterval {
    static let second: Self = 1
    static let minute: Self = .second * 60
    static let hour: Self = .minute * 60
    static let day: Self = .hour * 24
    
    init(seconds: Int) {
        self = TimeInterval(seconds)
    }
    
    init(minutes: Int) {
        self = TimeInterval(minutes) * .minute
    }
    
    init(hours: Int) {
        self = TimeInterval(hours) * .hour
    }
    
    init(days: Int) {
        self = TimeInterval(days) * .day
    }
    
    static func seconds(_ seconds: Int) -> Self {
        .init(seconds: seconds)
    }
    
    static func minutes(_ minutes: Int) -> Self {
        .init(minutes: minutes)
    }
    
    static func hours(_ hours: Int) -> Self {
        .init(hours: hours)
    }
        
    var formatToHourMinute: String {
        let minute = (Int(self) / 60) % 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minute, seconds)
    }
}
