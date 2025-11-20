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
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                print("스크린타임 권한 승인")
            } catch {
                print("스크린타임 권한 요청 실패: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                self.isRequestingPermission = false
                self.navigate(to: .notificationPermission)
            }
        }
    }
    
    func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                print(granted ? "알림 권한 허용됨" : "알림 권한 거부됨")
            } catch {
                print("알림 권한 요청 실패: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                self.isRequestingPermission = false
                self.navigate(to: .appRecommendation)
            }
        }
    }
}
