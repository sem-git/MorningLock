//
//  OnboardingViewModel.swift
//  WakeUp
//
//  Created by a on 11/14/25.
//

import Combine
import SwiftUI
import FamilyControls

enum OnboardingPath: Hashable {
    case permissionGuide
    case screenTimePermission
    case notificationPermission
    case appLockSelection
}

class OnboardingViewModel: ObservableObject {
    @Published var navigationPath: [OnboardingPath] = []
    @Published var isRequestingPermission = false
    @Published var isOnboarding: Bool = UserDefaults.standard.bool(forKey: StringLiteral.UserDefaultKeys.hasCompletedOnboarding) {
        didSet {
            UserDefaults.standard.set(isOnboarding, forKey: StringLiteral.UserDefaultKeys.hasCompletedOnboarding)
        }
    }
    
    func navigate(to path: OnboardingPath) {
        navigationPath.append(path)
    }
    
    func pop() {
        navigationPath.popLast()
    }
}
