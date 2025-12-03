//
//  NotificationManager.swift
//  WakeUp
//
//  Created by a on 11/24/25.
//

import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()    
    
    private init() {}
    
    func requestAuthorization() async {
        let settings = await center.notificationSettings()
        
        if settings.authorizationStatus == .notDetermined {
            do {
                if try await center.requestAuthorization(options: [.alert, .sound, .badge]) {
                    print("허용함")
                } else {
                }
            } catch {
            }
        }
    }
    
    func postImmediateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "앱에서 알람 끄기"
        content.body = "상쾌한 아침을 보내세요!"
        content.sound = nil
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }
}
