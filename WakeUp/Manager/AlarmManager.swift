//
//  AlarmManager.swift
//  WakeUp
//
//  Created by a on 11/22/25.
//

import UserNotifications
import Combine
import FirebaseAnalytics

// 알람 반복 여부
enum AlarmMode {
    case once
    case repeating
    case inactive
}

final class AlarmManager {
    static let shared = AlarmManager()
    
    // MARK: - Managers
    
    private let dataManager: CoreDataManager
    private let audioPlayer: AudioPlayerManager
    private let notificationManager: NotificationManager
    private let deviceActivityManager: DeviceActivityManager
    
    // MARK: - Alarm State
    
    @Published private(set) var isAlarmPlaying: Bool = false
    @Published private(set) var isOpenSheet: Bool = false
    @Published private(set) var snoozeCount: Int = 1
    
    // MARK: - Alarm Scheduling
    
    private var alarmQueue: AlarmQueue!
    private var scheduledAlarm: AlarmEntity?
    private var alarmTimer: Timer?
    
    // MARK: - Alarm Execution
    
    @Published private(set) var alarmMode: AlarmMode = .once
    
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
    
    // MARK: - 알람 데이터 관리
    
    // 새로운 알람을 CoreData에 저장하고 알람 큐에 추가한 뒤 스케줄 설정
    func addAlarm(_ alarm: AlarmEntity) async {
        do {
            try await dataManager.addAlarm(alarm: alarm)
            alarmQueue.insert(alarm)
            scheduleAlarm()
        } catch {
            print("Failed to add alarm: \(error)")
        }
    }
    
    // 기존 알람 정보 수정하여 스케줄 갱신
    func updateAlarm(_ alarm: AlarmEntity) {
        do {
            try dataManager.updateAlarm(alarm: alarm)
            updateAlarmSchedule()
        } catch {
            print("Failure to update alarm: \(error)")
        }
    }
    
    // 알람 삭제하고 다시 스케줄링
    func removeAlarm(_ id: UUID) {
        dataManager.deleteAlarm(id: id)
        buildQueue()
        scheduleAlarm()
    }
    
    // MARK: - 알람 큐 관리
    
    // CoreData에 저장된 알람 중 현재 시점에서 울릴 알람만 필터링하여 우선순위 큐 생성
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
    
    // MARK: - 알람 동작 제어
    
    // 울리고 있는 알람 일시 중지하고 지정 시간 후 다시 울리도록 설정
    func snoozeAlarm(by interval: TimeInterval) {
        // 현재 알람 중지
        stopCurrentAlarm()
        
        // 알람 모드 변경
        alarmMode = .once
        
        // 현재시간 + interval로 알람 예약
        let now = Date()
        audioPlayer.play(atTime: interval, volume: 0.5)
        startAlarmTimer(now + interval)
        
        // interval 시간 이후로 snoozeCount 1회 증가(일회성)
        let timer = Timer(timeInterval: interval, repeats: false) { _ in
            self.snoozeCount += 1
        }
        RunLoop.main.add(timer, forMode: .common)
    }
    
    // 알람 끄기
    func deactiveAlarm() {
        guard var currentAlarm = scheduledAlarm else { return }
        
        // 알람 종료
        alarmMode = .once
        scheduledAlarm = nil
        
        // 타이머 종료
        alarmTimer?.invalidate()
        
        // UI 및 사운드 종료
        isAlarmPlaying = false
        isOpenSheet = false
        audioPlayer.stop()
        
        // 잠금 시작
        deviceActivityManager.startMonitoring(startAt: Date())
        deviceActivityManager.commitSelectionWhileLocking()
        // 반복 알람 여부 반영
        currentAlarm.isActive = !currentAlarm.repeatDay.isEmpty
        updateAlarm(currentAlarm)
    }
    
    // 현재 울리고 있는 알람의 사운드 및 타이머 중지
    private func stopCurrentAlarm() {
        audioPlayer.stop()
        alarmTimer?.invalidate()
    }
    
    // 지정된 시점에 알람이 활성화되도록 타이머 설정
    private func startAlarmTimer(_ date: Date) {
        alarmTimer = Timer(
            fireAt: date,
            interval: 5,
            target: self,
            selector: #selector(activateAlarm),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(alarmTimer!, forMode: .common)
    }
    
    // MARK: - 알람 스케줄링
    
    // 알람 예약
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
        startAlarmTimer(nextAlarm.time.getTime)
    }
    
    // MARK: - 알람 활성화
    
    // 알람 예약 시간이 됐을 때 호출, 노티 발송
    @objc
    private func activateAlarm() {
        guard scheduledAlarm != nil else { return }
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
