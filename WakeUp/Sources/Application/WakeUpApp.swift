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
import FirebaseMessaging
import GoogleMobileAds

@main
struct WakeUpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject private var deviceManager = DeviceActivityManager.shared
    @StateObject private var permissionManager = PermissionManager.shared
    
    @State private var isTimerPresented = false
    @State private var isUpdateSheetPresented: Bool = false
    @State private var sheetHeight: CGFloat = .zero
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .sheet(isPresented: $isUpdateSheetPresented) {
                    UpdateSheetView(
                        onSkip: skipUpdate,
                        onUpdate: openAppStore
                    )
                    .presentationDetents([.height(sheetHeight)])
                    .interactiveDismissDisabled(true)
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: InnerHeightPreferenceKey.self,
                                value: geometry.size.height
                            )
                        }
                    }
                    .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                        sheetHeight = newHeight
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .openTimer)) { _ in
                    isTimerPresented = true
                }
                .fullScreenCover(isPresented: $isTimerPresented, content: {
                    TimerView()
                })
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        Analytics.logEvent("EnterBackground", parameters: [
                            AnalyticsParameterItemID: "id",
                            AnalyticsParameterItemName: "enter-background",
                            AnalyticsParameterContentType: "system",
                        ])
                        delegate.scheduleAppBackgroundRefresh()
                        delegate.scheduleAppBackgroundProcessing()
                    }
                }
                .task(checkAppVersion)
                .environmentObject(permissionManager)
        }
    }
    
    // 업데이트 무시
    private func skipUpdate() {
        isUpdateSheetPresented = false
    }
    
    // 앱 버전 체크
    private func checkAppVersion() async {
        guard let currentVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let currentVersion = Int(currentVersionString.split(separator: ".").joined()),
              let minimumVersion = await RemoteConfigManager.shared.getMinimumAppVersion() else {
            return
        }
        
        if currentVersion < minimumVersion {
            isUpdateSheetPresented = true
        } else {
            isUpdateSheetPresented = false
        }
    }
    
    // 앱스토어 이동
    private func openAppStore() {
        if let url = URL(string: "https://apps.apple.com/app/id/6755328423") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let alarmManager: AlarmManager = .shared
    private let notificationManager: NotificationManager = .shared
    
    func applicationWillTerminate(_ application: UIApplication) {
        if alarmManager.isAlarmScheduled() {
            notificationManager.postImmediateNotification(
                title: String(localized: "앱이 종료되었어요"),
                body: String(localized: "앱을 종료하면 설정한 알람이 울리지 않아요.")
            )
            sleep(3)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        FirebaseApp.configure()
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        MobileAds.shared.start()
        
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
        
        task.setTaskCompleted(success: true)
    }
    
    func handleProcessingTask(task: BGProcessingTask) {
        Analytics.logEvent("BackgroundProcessing", parameters: nil)
        
        task.expirationHandler = {
            Analytics.logEvent("BackgroundProcessing Failed", parameters: nil)
            task.setTaskCompleted(success: false)
        }
        
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
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // deviceToken을 fcm 토큰으로 맵핑
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if response.notification.request.content.userInfo["action"] as? String == "openTimer" {
            NotificationCenter.default.post(name: .openTimer, object: response.notification.request.identifier)
        }
    }
    
    // foreground 상태에서 노티피케이션 전송
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner])
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    }
}

extension Notification.Name {
    static let openMissionView = Notification.Name("openMissionView")
    static let closeMissionView = Notification.Name("closeMissionView")
    static let openAlarmView = Notification.Name("openAlarmView")
    static let closeAlarmView = Notification.Name("closeAlarmView")
    static let openTimer = Notification.Name("openTimer")
}
