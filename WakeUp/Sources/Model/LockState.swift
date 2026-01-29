//
//  LockState.swift
//  WakeUp
//
//  Created by 이세민 on 12/14/25.
//

import Foundation
import ManagedSettings
import FamilyControls

struct LockState: Codable {
    let endTime: Date
    let selection: FamilyActivitySelection
}
