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
    
    @MainActor
    func completeOnboardingWithDefaultAlarm() async {
        let calendar = Calendar.current
        let now = Date()
        
        let fireDate = calendar.date(
            bySettingHour: 7,
            minute: 30,
            second: 0,
            of: now
        )!
        
        let alarm = AlarmEntity(
            fireDate: fireDate,
            isActive: false,
            repeatDay: [.mon, .thu, .wed, .tue, .fri]
        )
        
        await AlarmManager.shared.addAlarm(alarm)
        isOnboarding = false
    }
    
    @MainActor
    func requestScreenTimeIfNeeded(
        permissionManager: PermissionManager
    ) async -> Bool {
        switch permissionManager.screenTimeStatus {
        case .authorized:
            return true
            
        case .unknown, .denied:
            await permissionManager.requestScreenTime()
            return permissionManager.screenTimeStatus == .authorized
        }
    }
}
