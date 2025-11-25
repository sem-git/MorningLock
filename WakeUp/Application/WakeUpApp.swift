//
//  WakeUpApp.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI
import CoreData
import FirebaseCore

@main
struct WakeUpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State var isShowMissionView = false
    @State var isShowAlarmView = false
    
    var body: some Scene {
        WindowGroup {
            RootView()
//                .onReceive(NotificationCenter.default.publisher(for: .openMissionView)) { _ in
//                    isShowMissionView = true
//                }
//                .onReceive(NotificationCenter.default.publisher(for: .closeMissionView)) { _ in
//                    isShowMissionView = false
//                }
//                .onReceive(NotificationCenter.default.publisher(for: .openAlarmView)) { _ in
//                    isShowAlarmView = true
//                }
//                .onReceive(NotificationCenter.default.publisher(for: .closeAlarmView)) { _ in
//                    isShowAlarmView = false
//                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {        
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        FirebaseApp.configure()        
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        
//        if response.notification.request.content.userInfo["type"] as? String == "mission" {
//            NotificationCenter.default.post(name: .openMissionView, object: response.notification.request.identifier)
//        } else {
//            NotificationCenter.default.post(name: .openAlarmView, object: response.notification.request.identifier)
//        }
    }
}

extension Notification.Name {
    static let openMissionView = Notification.Name("openMissionView")
    static let closeMissionView = Notification.Name("closeMissionView")
    static let openAlarmView = Notification.Name("openAlarmView")
    static let closeAlarmView = Notification.Name("closeAlarmView")
}
