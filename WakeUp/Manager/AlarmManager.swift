//
//  AlarmManager.swift
//  WakeUp
//
//  Created by a on 11/22/25.
//


import UserNotifications
import Combine

final class AlarmManager {
    static let shared = AlarmManager()
    
    private let dataManager: CoreDataManager
    private let audioPlayer: AudioPlayerManager
    
    private var alarmQueue: AlarmQueue!
    private var scheduledAlarm: AlarmEntity?
    private var timer: Timer?
    
    private init(dataManager: CoreDataManager = .shared, audioPlayer: AudioPlayerManager = .shared) {
        self.dataManager = dataManager
        self.audioPlayer = audioPlayer
        self.buildQueue()
    }
    
    /// 큐 구성
    private func buildQueue() {
        alarmQueue = AlarmQueue(sort: {
            if !$0.isActive { return false }
            return $0.time.getTime < $1.time.getTime
        })
        dataManager
            .fetchAlarm()
            .toEntities()
            .filter{ $0.isActive }
            .forEach { alarmQueue.insert($0) }
        scheduleAlarm()
    }
    
    /// 알람 추가
    func addAlarm(_ alarm: AlarmEntity) async {
        do {
            try await dataManager.addAlarm(alarm: alarm)
            alarmQueue.insert(alarm)
            scheduleAlarm()
        } catch {
            
        }
    }
    
    /// 알람 업데이트
    func updateAlarm(_ alarm: AlarmEntity) {
        do {
            try dataManager.updateAlarm(alarm: alarm)
            buildQueue()
            scheduleAlarm()
        } catch {
            print("Failure to update alarm: \(error)")
        }
    }
    
    /// 알람 삭제
    func removeAlarm(_ id: UUID) {
        dataManager.deleteAlarm(id: id)
        buildQueue()
        scheduleAlarm()
    }
    
    /// 알람 스케줄링
    private func scheduleAlarm() {
        // 알람이 없다면 오디오를 종료한다
        guard let dequeAlarm = alarmQueue.peek() else {
            audioPlayer.stop()
            return
        }
        
        // 새로운 알람이 없다면 이전 알람을 유지
        if let prev = scheduledAlarm {
            if prev.id == dequeAlarm.id && prev.time == dequeAlarm.time {
                return
            }
        }
        
        scheduledAlarm = dequeAlarm
        let interval = dequeAlarm.time.getTime.timeIntervalSinceNow
        
        // 오디오 세션 활성화
        audioPlayer.play(atTime: interval, volume: 0.5)
        
        // 타이머 등록 일정시간마다 알림 생성
        timer = Timer(
            fireAt: dequeAlarm.time.getTime,
            interval: 5,
            target: self,
            selector: #selector(sendRequestNotification),
            userInfo: nil,
            repeats: true
        )
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    @objc
    private func sendRequestNotification() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
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
