//
//  AlarmManager.swift
//  WakeUp
//
//  Created by a on 11/22/25.
//

import Combine
import UserNotifications

/// 등록된 알람을 스케줄링하고 알람 백그라운드 작업을 예약하는 클래스입니다.
final class AlarmManager {
    
    /// 알람 매니저의 공유 인스턴스입니다.
    ///
    /// 알람 관련 기능은 싱글톤으로 관리되며, 이 인스턴스를 통해서만 접근합니다.
    static let shared = AlarmManager()
    
    // MARK: - Dependencies
    
    /// 알람 데이터 저장 및 불러오기 위한 CoreData 매니저 클래스
    private let dataManager: CoreDataManager
    
    /// 알람 사운드 재생을 담당하는 오디오 플레이어 매니저 클래스
    private let audioPlayer: AudioPlayerManager
    
    /// 알람 Notification의 생성, 갱신, 해제를 담당하는 매니저 클래스
    private let notificationManager: NotificationManager
    
    /// 앱 사용 제한 및 잠금 처리를 위한  매니저 클래스
    private let deviceActivityManager: DeviceActivityManager
    
    // MARK: - Properties
    
    private let scheduler: AlarmScheduler = .default
    
    /// 알람 트리거 타이밍을 제어하기 위한 타이머
    private var alarmTimer: Timer?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    /// 현재 활성화된 알람이 재생 중인지 여부를 나타내는 값입니다.
    ///
    /// - 알람의 동작 상태에 따라 isAlarmPlaying 값이 자동으로 갱신됩니다.
    /// - 외부에서 isAlarmPlaying 값을 직접 수정할 수 없습니다.
    @Published private(set) var isAlarmPlaying: Bool = false
    
    @Published private(set) var isOpenSheet: Bool = false
    
    /// 현재 활성화된 알람에 대한 스누즈 횟수를 나타내는 값입니다.
    ///
    /// - 이 값은 snoozeAlarm() 호출 시 1씩 증가합니다..
    /// - 임의로 snoozeCount 값을 수정할 수 없습니다.
    @Published private(set) var snoozeCount: Int = 1
    
    /// 알람 Notification의 표시 방식을 나타내는 값입니다.
    ///
    /// - 현재 등록된 알람의 Notification 트리거 상태를 나타냅니다.
    /// - 외부에서는 이 값을 직접 수정할 수 없습니다.
    @Published private(set) var alarmNotificationMode: AlarmNotificationMode = .once
    
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
        syncAlarmSchedule()
        registerTasksScheduledAlarm()
    }
}


extension AlarmManager {

    
    /// 알람 관련 UI 시트를 표시합니다.
    func openSheet() {
        isOpenSheet = true
    }
    
    /// 알람 관련 UI 시트를 닫습니다.
    func dismissSheet() {
        isOpenSheet = false
    }
    
    /// 새로운 알람을 등록하고 스케줄을 갱신합니다.
    ///
    /// - Parameter alarm: 새로 등록할 알람 엔티티
    func addAlarm(_ alarm: AlarmEntity) async {
        do {
            try await dataManager.addAlarm(alarm: alarm)
            scheduler.insert(alarm)
        } catch {
            print("Failed to add alarm: \(error)")
        }
    }
    
    /// 기존에 등록된 알람 정보를 수정하고 스케줄을 갱신합니다.
    ///
    /// - Parameter alarm: 수정할 알람 엔티티
    func updateAlarm(_ alarm: AlarmEntity) {
        do {
            try dataManager.updateAlarm(alarm: alarm)
            syncAlarmSchedule()
        } catch {
            print("Failure to update alarm: \(error)")
        }
    }
    
    /// 등록된 알람을 삭제하고 알람 스케줄을 다시 구성합니다.
    ///
    /// - Parameter id: 삭제할 알람의 고유 id
    func removeAlarm(withId id: UUID) {
        dataManager.deleteAlarm(id: id)
        syncAlarmSchedule()
    }
    
    /// 현재 활성화된 알람을 기준으로 스누즈를 적용합니다.
    ///
    /// - 현재시간 기준 interval 만큼 알람을 지연시킵니다
    func snoozeAlarm(by interval: TimeInterval) {
        // 현재 알람 중지
        stopCurrentAlarm()
        
        // 알람 모드 변경
        alarmNotificationMode = .once
        
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
    
    /// 현재 활성화된 알람을 종료하고 스케줄을 갱신합니다.
    func deactiveAlarm() {
        guard var currentAlarm = scheduler.scheduledAlarm.value else { return }
        
        // 알람 종료
        alarmNotificationMode = .once
        
        // 타이머 종료
        alarmTimer?.invalidate()
        
        // UI 및 사운드 종료
        isAlarmPlaying = false
        isOpenSheet = false
        audioPlayer.stop()
        
        // 잠금 시작
        deviceActivityManager.startMonitoring(startAt: Date())
        deviceActivityManager.commitSelectionWhileLocking()
        
        currentAlarm.isActive = !currentAlarm.repeatDay.isEmpty
        updateAlarm(currentAlarm)
    }
}

// MARK: - Alarm Scheduling
extension AlarmManager {
    
    /// 알람 스케줄러에 데이터를 추가
    private func syncAlarmSchedule() {
        scheduler.buildQueue(with: dataManager.fetchAlarm().toEntities())
        scheduler.scheduleAlarm()
    }
    
    /// 스케줄러에서 선택된 알람을 감지하고 오디오  작업을 수행합니다.
    private func registerTasksScheduledAlarm() {
        scheduler
            .scheduledAlarm
            .sink { scheduledAlarm in
                if let scheduledAlarm {
                    let interval = scheduledAlarm.time.nextOccurrenceIncludingMinutes.timeIntervalSinceNow
                    self.audioPlayer.play(atTime: interval, volume: 0.5)
                    self.startAlarmTimer(scheduledAlarm.time.nextOccurrenceIncludingMinutes)
                } else {
                    self.stopCurrentAlarm()
                }
            }
            .store(in: &cancellables)
    }
    
    @objc
    private func activateAlarm() {
        if !isAlarmPlaying {
            isAlarmPlaying = true
            isOpenSheet = true
        }
        
        switch alarmNotificationMode {
        case .once:
            notificationManager.postImmediateNotification()
            alarmNotificationMode = .inactive
        case .repeating:
            notificationManager.postImmediateNotification()
        case .inactive:
            break
        }
    }
    
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
    
    // 현재 울리고 있는 알람의 사운드 및 타이머 중지
    private func stopCurrentAlarm() {
        audioPlayer.stop()
        alarmTimer?.invalidate()
    }
}

// MARK: - Enum
extension AlarmManager {
    /// AlarmManager 클래스 내부에서 Notification 표시 반복 방식을 나타내는 enum입니다.
    enum AlarmNotificationMode {
        
        /// 알림을 한 번만 트리거합니다.
        case once
        
        /// 반복 스케줄에 따라 Notification을 지속적으로 트리거합니다.
        case repeating
        
        /// Notification을 트리거하지 않습니다.
        case inactive
    }
}
