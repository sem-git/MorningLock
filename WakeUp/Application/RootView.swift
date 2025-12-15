//
//  RootView.swift
//  WakeUp
//
//  Created by a on 10/24/25.
//

import SwiftUI

struct RootView: View {
    @AppStorage(StringLiteral.UserDefaultKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = true
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                OnboardingView()
            } else {
                MainView()
                    .transition(.move(edge: .trailing))
            }
        }
        .background(Color.gray800)
        .animation(.easeInOut, value: hasCompletedOnboarding)
    }
}

#Preview {
    RootView()
}
