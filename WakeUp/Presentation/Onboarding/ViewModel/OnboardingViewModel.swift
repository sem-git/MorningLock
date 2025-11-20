//
//  OnboardingViewModel.swift
//  WakeUp
//
//  Created by a on 11/14/25.
//

import Combine
import SwiftUI

enum OnboardingPath: Hashable {
    case permissionGuide
    case screenTimePermission
    case appRecommendation
}

class OnboardingViewModel: ObservableObject {
    @Published var navigationPath: [OnboardingPath] = []
    @Published var isRequestingPermission = false
    @Published var isOnboarding = UserDefaults.standard.bool(forKey: "isOnboarding")
    
    func navigate(to path: OnboardingPath) {
        navigationPath.append(path)
    }
        
    func pop() {
        navigationPath.popLast()
    }
    
    func requestScreenTimePermission() {
        isRequestingPermission = true
    }
}
