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
    private let notificationManager: NotificationManager
    
    private var alarmQueue: AlarmQueue!
    private var scheduledAlarm: AlarmEntity?
    private var timer: Timer?
    
    @Published private(set) var isAlarmPlaying: Bool = false
    
    private init(
        dataManager: CoreDataManager = .shared,
        audioPlayer: AudioPlayerManager = .shared,
        notificationManager: NotificationManager = .shared
    ) {
        self.dataManager = dataManager
        self.audioPlayer = audioPlayer
        self.notificationManager = notificationManager
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
    
    /// 현재 활성화된 알람 종료
    func deactiveAlarm() {
        guard var currentAlarm = scheduledAlarm else { return }
        scheduledAlarm = nil
        timer?.invalidate()
        isAlarmPlaying = false
        audioPlayer.stop()
        currentAlarm.isActive = false
        updateAlarm(currentAlarm)
    }
    
    /// 일정 시간뒤에 알람 활성화
    func snoozeAlarm(by interval: TimeInterval) {
        guard let scheduledAlarm else { return }
        // 현재 알람 중지
        audioPlayer.stop()
        timer?.invalidate()
        
        // 알람 예약
        audioPlayer.play(atTime: interval, volume: 0.5)
        
        timer = Timer(
            fireAt: scheduledAlarm.time.getTime + interval,
            interval: 5,
            target: self,
            selector: #selector(activateAlarm),
            userInfo: nil,
            repeats: true
        )
        
        RunLoop.main.add(timer!, forMode: .common)
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
            selector: #selector(activateAlarm),
            userInfo: nil,
            repeats: true
        )
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    /// 알람 활성화
    @objc
    private func activateAlarm() {
        if !isAlarmPlaying {
            isAlarmPlaying = true
        }
        notificationManager.postImmediateNotification()
    }
}
