//
//  TimeInterval+.swift
//  WakeUp
//
//  Created by 이세민 on 11/21/25.
//

import Foundation

extension TimeInterval {
    func toHHMM() -> String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        return String(format: "%02dh%02dm", hours, minutes)
    }
}
