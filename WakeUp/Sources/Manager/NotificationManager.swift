//
//  NotificationManager.swift
//  WakeUp
//
//  Created by a on 11/24/25.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()    
    
    private init() {}
    
    func postImmediateNotification() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "알람이 울렸습니다")
        content.body = String(localized: "방해 앱을 잠그고 외출 준비에 집중해보세요")
        content.sound = nil
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }
    
    func postDelayNotification(after seconds: TimeInterval, title: String, body: String) {
        center.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }
    
    func removePendingNotification() {
        center.removeAllPendingNotificationRequests()
    }
}
