//
//  WakeUpApp.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI
import CoreData
import BackgroundTasks
import FirebaseCore
import FirebaseAnalytics

@main
struct WakeUpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            RootView()
//                .onChange(of: scenePhase) { newPhase in
//                    switch newPhase {
//                    case .background:
//                        Analytics.logEvent("EnterBackground", parameters: [
//                            AnalyticsParameterItemID: "id",
//                            AnalyticsParameterItemName: "enter-background",
//                            AnalyticsParameterContentType: "system",
//                        ])
//                        print("App entered background")
//                        delegate.scheduleAppBackgroundRefresh()
//                        delegate.scheduleAppBackgroundProcessing()
//                    @unknown default:
//                        break
//                    }
//                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let alarmManager: AlarmManager = .shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.awayke.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.awayke.processing", using: nil) { task in
            self.handleProcessingTask(task: task as! BGProcessingTask)
        }
        return true
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        Analytics.logEvent("BackgroundRefresh", parameters: nil)
        
        task.expirationHandler = {
            Analytics.logEvent("BackgroundRefresh Failed", parameters: nil)
            task.setTaskCompleted(success: false)
        }
        
        alarmManager.updateAlarmSchedule()
        
        task.setTaskCompleted(success: true)
    }
    
    func handleProcessingTask(task: BGProcessingTask) {
        Analytics.logEvent("BackgroundProcessing", parameters: nil)
        
        task.expirationHandler = {
            Analytics.logEvent("BackgroundProcessing Failed", parameters: nil)
            task.setTaskCompleted(success: false)
        }
        
        alarmManager.updateAlarmSchedule()
        
        task.setTaskCompleted(success: true)
    }
    
    func scheduleAppBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.awayke.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: .minutes(1))
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func scheduleAppBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: "com.awayke.processing")
        request.earliestBeginDate = Date(timeIntervalSinceNow: .minutes(1))
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("\(Date()): Could not schedule processing task: \(error)")
        }
    }
    
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
