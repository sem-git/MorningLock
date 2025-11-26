//
//  RootView.swift
//  WakeUp
//
//  Created by a on 10/24/25.
//

import SwiftUI

struct UserDefaultKey {
    static let isOnboarding = "isOnboarding"
}

struct RootView: View {
    @AppStorage(UserDefaultKey.isOnboarding) private var isOnboarding = true        
    
    var body: some View {
        Group {
            if isOnboarding {
                OnboardingView()                
            } else {
                MainView()                    
            }
        }
    }
}

#Preview {
    RootView()
}
