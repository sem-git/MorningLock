//
//  MainViewModel.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import Combine
import UserNotifications
import SwiftUI

enum FullScreenCover: Hashable, Identifiable {
    case alarmSetting(AlarmEntity?)
    
    var id: Self { self }
}

class MainViewModel: ObservableObject {
    @Published var isShowAddAlarm: Bool = false
    @Published var isShowAlert = false
    @Published var alarmList: [AlarmEntity] = []
    @Published var fullScreenCover: FullScreenCover?
    @Published var deleteMode = false
    
    private let dataManager: CoreDataManager
    
    // 다음 알람 시간표시
    var nextAlarm: String {
        guard let firstDate = alarmList.first(where: {$0.isActive })?.time else { return "" }
        let now = Date()
        let timeDiff = firstDate.getTime.timeIntervalSince(now)
        let hour = Int(timeDiff / 3600)
        let minute = Int(timeDiff) % Int(3600) / 60
        return "\(hour)시간 \(minute)분"
    }
    
    // 알람 활성화 여부
    var isActiveAlarm: Bool {
        alarmList.first(where: {$0.isActive }) != nil
    }
    
    init(dataManager: CoreDataManager = .shared) {
        self.dataManager = dataManager
    }
    
    func showAlarmSettingView(alarm: AlarmEntity? = nil) {
        fullScreenCover = .alarmSetting(alarm)
    }
    
    //    func requestPermission() async {
    //        let center = UNUserNotificationCenter.current()
    //        let settings = await center.notificationSettings()
    //
    //        if settings.authorizationStatus == .notDetermined {
    //            do {
    //                if try await center.requestAuthorization(options: [.alert, .sound, .badge]) {
    //                    print("허용함")
    //                } else {
    //                    isShowAlert = true
    //                }
    //            } catch {
    //            }
    //        }
    //    }
    
    //     데이터를 가져왔을떄 -> isActive 상태에 따라서 초기값 바인딩
    func fetchAlarm() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        
        let result = dataManager.fetchAlarm()
        alarmList = result.map { alarm in
            return AlarmEntity(
                id: alarm.id,
                title: alarm.title ?? "",
                time: alarm.time,
                notiRequests: requests.filter { alarm.requestIDs.contains($0.identifier) },
                isActive: alarm.isActive,
                repeatDay: alarm.repeatDay.compactMap { Weekday(rawValue: $0) }
            )
        }.sorted { $0.time.getTime < $1.time.getTime }
    }
    
    func updateAlarm(_ alarm: AlarmEntity) {
        let center = UNUserNotificationCenter.current()
        //      alarm의 하위 목록 알람 트리거
        if alarm.isActive {
            alarm.notiRequests.forEach { center.add($0) }
        } else {
            center.removePendingNotificationRequests(withIdentifiers: alarm.notiRequests.map{$0.identifier})
        }
        
        do {
            try dataManager.updateAlarm(alarm: alarm)
        } catch {
            
        }
    }
    
    func deleteAlarm(_ alarm: AlarmEntity) {
        let center = UNUserNotificationCenter.current()
        
        // 기존 하위알람 삭제
        center.removePendingNotificationRequests(withIdentifiers: alarm.notiRequests.map(\.identifier))
        
        dataManager.deleteAlarm(alarm: alarm)
        Task {
            await self.fetchAlarm()
            if alarmList.isEmpty {
                deleteMode = false
            }
        }
    }
}

