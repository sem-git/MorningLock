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
        content.title = NSLocalizedString("AlarmRingingNotificationTitle", comment: "알람 타이틀")
        content.body = NSLocalizedString("AlarmRingingNotificationSubTitle", comment: "알람 서브 타이틀")
        content.sound = nil
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }
}
