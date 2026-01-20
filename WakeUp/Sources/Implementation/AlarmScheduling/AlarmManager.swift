//
//  AlarmManager.swift
//  WakeUp
//
//  Created by a on 11/22/25.
//

import Combine
import Foundation

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
    
    // MARK: - Properties
    
    private let scheduler: AlarmScheduler = .default
    
    private let maxSnoozeCount: Int = 3
    
    private var cancellables = Set<AnyCancellable>()
    
    private var alarmTimer: Timer?
    
    // MARK: - Published Properties
    
    /// 현재 활성화된 알람이 재생 중인지 여부를 나타내는 값입니다.
    ///
    /// - 알람의 동작 상태에 따라 isAlarmPlaying 값이 자동으로 갱신됩니다.
    /// - 외부에서 isAlarmPlaying 값을 직접 수정할 수 없습니다.
    @Published private(set) var isAlarmPlaying: Bool = false
    
    /// 현재 활성화된 알람에 대한 스누즈 횟수를 나타내는 값입니다.
    ///
    /// - 이 값은 snoozeAlarm() 호출 시 1씩 증가합니다..
    /// - 임의로 snoozeCount 값을 수정할 수 없습니다.
    @Published private(set) var snoozeCount: Int = 1
    
    @Published private(set) var isSnoozeActive = false
    
    // MARK: - Initializer
    private init(
        dataManager: CoreDataManager = .shared,
        audioPlayer: AudioPlayerManager = .shared,
        notificationManager: NotificationManager = .shared
    ) {
        self.dataManager = dataManager
        self.audioPlayer = audioPlayer
        self.notificationManager = notificationManager
        syncAlarmSchedule()
        registerTasksScheduledAlarm()
    }
}

// MARK: - Alarm Generate

extension AlarmManager {
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
        if snoozeCount >= maxSnoozeCount { return }
        
        // 현재 알람 중지
        deactiveCurrentAlarm(reschedule: true)
        
        // 현재시간 + interval로 알람 예약
        activateCurrentAlarm(after: interval)
        
        // interval 시간 이후로 snoozeCount 1회 증가(일회성)
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { timer in
            self.snoozeCount += 1
            self.isSnoozeActive = false
            timer.invalidate()
        }
    }
    
    /// 현재 활성화된 알람을 종료하고 스케줄을 갱신합니다.
    func deactiveAlarm() {
        guard var currentAlarm = scheduler.scheduledAlarm.value else { return }
        
        // 활성화된 알람 관련 작업을 모두 종료
        deactiveCurrentAlarm()
        
        // 알람 반복 여부에 따라서 isActive 업데이트
        currentAlarm.isActive = !currentAlarm.repeatDay.isEmpty
        updateAlarm(currentAlarm)
    }
}

// MARK: - Alarm Scheduling
extension AlarmManager {
    
    func isAlarmScheduled() -> Bool {
        return scheduler.scheduledAlarm.value != nil
    }
    
    /// 알람 스케줄러에 데이터를 추가
    private func syncAlarmSchedule() {
        scheduler.buildQueue(with: dataManager.fetchAlarm().toEntities())
        scheduler.schedule()
    }
    
    /// 스케줄러에서 선택된 알람을 감지하고 오디오  작업을 수행합니다.
    private func registerTasksScheduledAlarm() {
        scheduler
            .scheduledAlarm
            .sink(receiveValue: { scheduledAlarm in
                if let scheduledAlarm {
                    let interval = scheduledAlarm.fireDate.nextOccurrenceIncludingMinutes.timeIntervalSinceNow
                    self.activateCurrentAlarm(after: interval)
                } else {
                    self.deactiveCurrentAlarm()
                }
            })
            .store(in: &cancellables)
    }
    
    // interval을 기준으로 알람 작업 예약
    private func activateCurrentAlarm(after interval: TimeInterval) {
        // 오디오 재생
        audioPlayer.play(atTime: interval, volume: 0.5)
        
        // 노티피케이션 등록
        notificationManager.postDelayNotification(
            after: interval,
            title: String(localized: "알람이 울렸습니다"),
            body: String(localized: "방해 앱을 잠그고 외출 준비에 집중해보세요")
        )
        // 타이머 등록
        alarmTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            self.isAlarmPlaying = true
        }
    }
    
    // 알람 작업 취소
    private func deactiveCurrentAlarm(reschedule: Bool = false) {
        audioPlayer.stop()
        alarmTimer?.invalidate()
        notificationManager.removePendingNotification()
        
        if reschedule {
            isAlarmPlaying = true
            isSnoozeActive = true
        } else {
            snoozeCount = 1
            isSnoozeActive = false
            isAlarmPlaying = false
        }
    }
}
