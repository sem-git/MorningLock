//
//  AlarmManager.swift
//  WakeUp
//
//  Created by a on 11/22/25.
//

import UserNotifications
import Combine
import FirebaseAnalytics

final class AlarmManager {
    /// 알람 반복 여부
    enum AlarmMode {
        case once
        case repeating
        case inactive
    }
    
    static let shared = AlarmManager()
    
    // MARK: - Managers
    
    private let dataManager: CoreDataManager
    private let audioPlayer: AudioPlayerManager
    private let notificationManager: NotificationManager
    private let deviceActivityManager: DeviceActivityManager
    
    // MARK: - Properties
    
    private var alarmQueue: AlarmQueue!
    private var scheduledAlarm: AlarmEntity?
    private var timer: Timer?
    private var alarmMode: AlarmMode = .once
    
    @Published private(set) var isAlarmPlaying: Bool = false
    @Published private(set) var isOpenSheet: Bool = false
    @Published private(set) var snoozeCount: Int = 1
    
    // MARK: - Initializer
    
    private init(
        dataManager: CoreDataManager = .shared,
        audioPlayer: AudioPlayerManager = .shared,
        notificationManager: NotificationManager = .shared,
        deviceActivityManager: DeviceActivityManager = .shared
    ) {
        self.dataManager = dataManager
        self.audioPlayer = audioPlayer
        self.notificationManager = notificationManager
        self.deviceActivityManager = deviceActivityManager
        updateAlarmSchedule()
    }
    
    func setAlarmMode(_ mode: AlarmMode) {
        self.alarmMode = mode
    }
    
    func updateAlarmSchedule(_ completion: (() -> ())? = nil) {
        buildQueue()
        scheduleAlarm()
        completion?()
    }
    
    func openSheet() {
        isOpenSheet = true
    }
    
    func dismissSheet() {
        isOpenSheet = false
    }
    
    // MARK: - 큐 구성
    
    private func buildQueue() {
        alarmQueue = AlarmQueue(sort: .upcoming)
        
        let today = Calendar.current.component(.weekday, from: Date())
        
        // 큐에 추가될 알림들 미리 필터링
        dataManager
            .fetchAlarm()
            .toEntities()
            .filter { alarm in
                guard alarm.isActive else { return false }
                if alarm.repeatDay.isEmpty { return true }
                // 현재 날짜 기준 2일
                let validDays: [Int] = (0...2).map { offset in
                    ((today - 1 + offset) % 7) + 1
                }
                return alarm.repeatDay.contains { weekDay in
                    validDays.contains(weekDay.rawValue)
                }
            }
            .forEach { alarmQueue.insert($0) }
    }
    
    // MARK: - 알람 관리
    
    func addAlarm(_ alarm: AlarmEntity) async {
        do {
            try await dataManager.addAlarm(alarm: alarm)
            alarmQueue.insert(alarm)
            scheduleAlarm()
        } catch {
            print("Failed to add alarm: \(error)")
        }
    }
    
    func updateAlarm(_ alarm: AlarmEntity) {
        do {
            try dataManager.updateAlarm(alarm: alarm)
            updateAlarmSchedule()
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
        alarmMode = .once
        audioPlayer.play(atTime: interval, volume: 0.5)
        startTimer(scheduledAlarm.time.getTime + interval)
        let timer = Timer(timeInterval: interval, repeats: false) { _ in
            self.snoozeCount += 1
        }
        RunLoop.main.add(timer, forMode: .common)
    }
    
    // MARK: - 알람 활성화/비활성화
    
    private func activeAlarmImmediately() {
        stopCurrentAlarm()
        audioPlayer.play(atTime: 0, volume: 0.5)
        startTimer(.now)
    }
    
    func deactiveAlarm() {
        guard var currentAlarm = scheduledAlarm else { return }
        
        deviceActivityManager.startMonitoring(startAt: Date())
        deviceActivityManager.startTimer()
        
        snoozeCount = 1
        alarmMode = .once
        scheduledAlarm = nil
        timer?.invalidate()
        isAlarmPlaying = false
        isOpenSheet = false
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
        
         guard let nextAlarm = alarmQueue.peek() else {
             stopCurrentAlarm()
             return
         }
                  
         if let scheduled = scheduledAlarm,
            scheduled.id == nextAlarm.id,
            scheduled.time.getTime == nextAlarm.time.getTime {
             return
         }
         
        // 오늘 울리는 알림이거나 일회성 알림 여부 확인
         guard nextAlarm.repeatDay.hasToday || nextAlarm.repeatDay.isEmpty else {
             return
         }
                  
        // 알람 등록
         scheduledAlarm = nextAlarm
         let interval = nextAlarm.time.getTime.timeIntervalSinceNow
         audioPlayer.play(atTime: interval, volume: 0.5)
//         deviceActivityManager.startMonitoring(startAt: nextAlarm.time.getTime)
         startTimer(nextAlarm.time.getTime)
    }
    
    // MARK: - 알람 활성화
    
    @objc
    private func activateAlarm() {
        if !isAlarmPlaying {
            isAlarmPlaying = true
            isOpenSheet = true
        }
        
        switch alarmMode {
        case .once:
            notificationManager.postImmediateNotification()
            alarmMode = .inactive
        case .repeating:
            notificationManager.postImmediateNotification()
        case .inactive:
            break
        }
    }
}
