//
//  PermissionManager.swift
//  WakeUp
//
//  Created by 이세민 on 12/4/25.
//

import FamilyControls
import Combine
import UserNotifications

@MainActor
final class PermissionManager: ObservableObject {
    
    enum AuthorizationState {
        case unknown
        case authorized
        case denied
    }
    
    static let shared = PermissionManager()
    
    @Published private(set) var screenTimeStatus: AuthorizationState = .unknown
    @Published private(set) var notificationStatus: AuthorizationState = .unknown
    
    private init() {
        refreshScreenTimeStatus()
        refreshNotificationStatus()
    }
    
    func refreshScreenTimeStatus() {
        let status = AuthorizationCenter.shared.authorizationStatus
        
        switch status {
        case .approved:
            screenTimeStatus = .authorized
        case .denied:
            screenTimeStatus = .denied
        default:
            screenTimeStatus = .unknown
        }
    }
    
    func requestScreenTime() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refreshScreenTimeStatus()
        } catch {
            refreshScreenTimeStatus()
        }
    }
    
    func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self.notificationStatus = .authorized
                case .denied:
                    self.notificationStatus = .denied
                default:
                    self.notificationStatus = .unknown
                }
            }
        }
    }
    
    func requestNotification() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            notificationStatus = granted ? .authorized : .denied
        } catch {
            notificationStatus = .denied
        }
    }
}
