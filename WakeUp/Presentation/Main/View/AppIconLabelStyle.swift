//
//  AppIconLabelStyle.swift
//  WakeUp
//
//  Created by a on 12/3/25.
//

import SwiftUI

struct AppIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.icon
            .scaleEffect(2.5)
    }
}
