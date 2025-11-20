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
    case notificationPermission
    case appRecommendation
}

class OnboardingViewModel: ObservableObject {
    @Published var navigationPath: [OnboardingPath] = []
    @Published var isRequestingPermission = false
    @Published var isOnboarding: Bool = UserDefaults.standard.bool(forKey: UserDefaultKey.isOnboarding) {
        didSet {
            UserDefaults.standard.set(isOnboarding, forKey: UserDefaultKey.isOnboarding)
        }
    }
    
    func navigate(to path: OnboardingPath) {
        navigationPath.append(path)
    }
    
    func pop() {
        navigationPath.popLast()
    }
    
    func requestScreenTimePermission() {
        isRequestingPermission = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            // 권한 요청
            
            self.isRequestingPermission = false
            self.navigate(to: .notificationPermission)
        }
    }
    
    func requestNotificationPermission() {
        isRequestingPermission = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            // 권한 요청
            
            self.isRequestingPermission = false
            self.navigate(to: .appRecommendation)
        }
    }
}
