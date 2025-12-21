//
//  LockState.swift
//  WakeUp
//
//  Created by a on 12/21/25.
//

import Foundation
import ManagedSettings

struct LockState: Codable {
    let endTime: Date
    let lockedApps: Set<ApplicationToken>
}
