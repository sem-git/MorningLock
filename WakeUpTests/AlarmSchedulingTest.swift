//
//  AlarmSchedulingTest.swift
//  WakeUpTests
//
//  Created by a on 12/20/25.
//

import XCTest
@testable import WakeUp

final class AlarmSchedulingTest: XCTestCase {
    var sut: AlarmScheduler!
    
    // 테스트 기준 날짜
    var testDate: Date {
        var testDateComponets = DateComponents()
        testDateComponets.year = 2025
        testDateComponets.month = 12
        testDateComponets.day = 25
        testDateComponets.hour = 12
        testDateComponets.minute = 30
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: testDateComponets)!
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = DefaultAlarmScheduler(sortOption: .test(testDate: testDate))
    }
    
    override func tearDownWithError() throws {
        //sut = nil
        try super.tearDownWithError()
    }
    
    func test_동일한_시간의_알람이_여러개일때_가장_가까운_알람을_선택한다() throws {
        // given - 알람목록을 가져오고 스케줄러에 데이터를 추가
        let alarms: [AlarmEntity] = [
            AlarmEntity(time: .now, repeatDay: [.fri]),
            AlarmEntity(time: .now, repeatDay: [.mon]),
            AlarmEntity(time: .now, repeatDay: []), // 가장 빠른 알람
        ]
        // 데이터 추가
        sut.buildQueue(with: alarms)
        
        // when - 알람 스케줄링 시작
        sut.scheduleAlarm()
        
        // then - 현재시간 기준 가장 빠른 알람인 일요일 알람이 스케줄링된다
        let scheduledAlarm = try XCTUnwrap(sut.scheduledAlarm)
        let lastAlarm = try XCTUnwrap(alarms.last)
        XCTAssertEqual(scheduledAlarm.id, lastAlarm.id, "스케줄링된 알람과 가장 빠른 알람의 id가 일치하지 않음")
    }
    
    func test_서로_다른시간의_알람들중_가장_빠른_알람이_선택된다() throws {
        // given - 서로다른 시간의 알람 목록을 스케줄러에 추가
        let alarms: [AlarmEntity] = [
            AlarmEntity(time: testDate.addingTimeInterval(100)),
            AlarmEntity(time: testDate.addingTimeInterval(50)),
            AlarmEntity(time: testDate.addingTimeInterval(10)) // 가장 빠른 알람
        ]
        sut.buildQueue(with: alarms)
        
        // when - 알람 스케줄링 시작
        sut.scheduleAlarm()    
        
        // when - 마지막 알람이 스케줄링된 상태
        let scheduledAlarm = try XCTUnwrap(sut.scheduledAlarm)
        let lastAlarm = try XCTUnwrap(alarms.last)
        XCTAssertEqual(scheduledAlarm.id, lastAlarm.id, "스케줄링된 알람과 가장 빠른 알람의 id가 일치하지 않음")
    }
    
    func test_비활성화된_알람은_스케줄링_대상에서_제외된다() throws {
        // given - 비활성화된 알람을 추가
        let alarms: [AlarmEntity] = [
            AlarmEntity(time: testDate.addingTimeInterval(100), isActive: true),
            AlarmEntity(time: testDate.addingTimeInterval(50), isActive: false),
            AlarmEntity(time: testDate.addingTimeInterval(10), isActive: false) // 가장 빠른 알람
        ]
        sut.buildQueue(with: alarms)
        
        // when - 알람 스케줄링 시작
        sut.scheduleAlarm()
        
        let scheduledAlarm = try XCTUnwrap(sut.scheduledAlarm)
        let firstAlarm = try XCTUnwrap(alarms.first)
        XCTAssertEqual(scheduledAlarm.id, firstAlarm.id)
        XCTAssertTrue(scheduledAlarm.isActive)
    }
}

