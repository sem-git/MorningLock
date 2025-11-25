//
//  AppItem.swift
//  WakeUp
//
//  Created by 이세민 on 11/20/25.
//

import Foundation

struct AppItem: Identifiable {
    let id = UUID()
    let name: String
    var isSelected: Bool = false
}
