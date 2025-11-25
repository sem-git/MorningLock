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
    
    // MARK: - Managers
    private let dataManager: CoreDataManager
    private let audioPlayer: AudioPlayerManager
    private let notificationManager: NotificationManager
    
    // MARK: - Properties
    private var alarmQueue: AlarmQueue!
    private var scheduledAlarm: AlarmEntity?
    private var timer: Timer?
    
    @Published private(set) var isAlarmPlaying: Bool = false
    
    // MARK: - Initializer
    private init(
        dataManager: CoreDataManager = .shared,
        audioPlayer: AudioPlayerManager = .shared,
        notificationManager: NotificationManager = .shared
    ) {
        self.dataManager = dataManager
        self.audioPlayer = audioPlayer
        self.notificationManager = notificationManager
        buildQueue()
        scheduleAlarm()
    }
    
    // MARK: - 큐 구성
    private func buildQueue() {
        alarmQueue = AlarmQueue(sort: .upcoming)
        
        dataManager
            .fetchAlarm()
            .toEntities()
            .filter { $0.isActive && $0.isDueToday }
            .forEach { alarmQueue.insert($0) }
    }
    
    // MARK: - 알람 관리
    func addAlarm(_ alarm: AlarmEntity) async {
        do {
            try await dataManager.addAlarm(alarm: alarm)
            if alarm.isDueToday {
                alarmQueue.insert(alarm)
            }
            scheduleAlarm()
        } catch {
            print("Failed to add alarm: \(error)")
        }
    }
    
    func updateAlarm(_ alarm: AlarmEntity) {
        do {
            try dataManager.updateAlarm(alarm: alarm)
            buildQueue()
            scheduleAlarm()
        } catch {
            print("Failure to update alarm: \(error)")
        }
    }
    
    func removeAlarm(_ id: UUID) {
        dataManager.deleteAlarm(id: id)
        buildQueue()
        scheduleAlarm()
    }
    
    func snoozeAlarm(by interval: TimeInterval) {
        guard let scheduledAlarm else { return }
        stopCurrentAlarm()
        audioPlayer.play(atTime: interval, volume: 0.5)
        startTimer(scheduledAlarm.time.getTime + interval)
    }
    
    // MARK: - 알람 활성화/비활성화
    private func activeAlarmImmediately() {
        stopCurrentAlarm()
        audioPlayer.play(atTime: 0, volume: 0.5)
        startTimer(.now)
    }
    
    func deactiveAlarm() {
        guard var currentAlarm = scheduledAlarm else { return }
        
        scheduledAlarm = nil
        timer?.invalidate()
        isAlarmPlaying = false
        audioPlayer.stop()
        
        // 반복 알람 여부에 따라 상태 결정
        currentAlarm.isActive = !currentAlarm.repeatDay.isEmpty
        updateAlarm(currentAlarm)
    }
    
    private func stopCurrentAlarm() {
        audioPlayer.stop()
        timer?.invalidate()
    }
    
    private func startTimer(_ date: Date) {
        timer = Timer(
            fireAt: date,
            interval: 5,
            target: self,
            selector: #selector(activateAlarm),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    // MARK: - 알람 스케줄링
    private func scheduleAlarm() {
        guard let dequeAlarm = alarmQueue.peek() else {
            stopCurrentAlarm()
            return
        }
        
        // 새로운 알람이 없다면 이전 알람을 유지
        if let prev = scheduledAlarm, prev.id == dequeAlarm.id, prev.time == dequeAlarm.time {
            return
        }
        
        scheduledAlarm = dequeAlarm
        let interval = dequeAlarm.time.getTime.timeIntervalSinceNow
        // 오디오 세션 활성화
        audioPlayer.play(atTime: interval, volume: 0.5)
        // 타이머 등록
        startTimer(dequeAlarm.time.getTime)
    }
    
    // MARK: - 알람 활성화
    @objc
    private func activateAlarm() {
        if !isAlarmPlaying {
            isAlarmPlaying = true
        }
        notificationManager.postImmediateNotification()
    }
}
