import Foundation
import DeviceActivity
import FamilyControls
import Combine

@MainActor
final class DeviceActivityManager: ObservableObject {
    private let center = DeviceActivityCenter()
    
    private let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
        .encouraged: DeviceActivityEvent(
            threshold: DateComponents(minute: 1)
        )
    ]
    
    // 모니터링 시작
    func startMonitoring() {
        let now = Date()
        let end = Calendar.current.date(byAdding: .minute, value: 15, to: now)!
        
        let startComponents = fullDateComponents(from: now)
        let endComponents = fullDateComponents(from: end)
        
        do {
            try center.startMonitoring(
                .testName,
                during: DeviceActivitySchedule(
                    intervalStart: startComponents,
                    intervalEnd: endComponents,
                    repeats: false
                ),
                events: events
            )
            
            print("DeviceActivity 모니터링 시작")
            print("start:", startComponents)
            print("end:", endComponents)
            
        } catch {
            print("DeviceActivity 모니터링 실패:", error)
        }
    }
    
    // 모니터링 중지
    func stopMonitoring() {
        center.stopMonitoring([.testName])
        print("DeviceActivity 모니터링 중단")
    }
    
    private func fullDateComponents(from date: Date) -> DateComponents {
        Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
    }
}

extension DeviceActivityName {
    static let testName = Self("testName")
}

extension DeviceActivityEvent.Name {
    static let encouraged = Self("encouraged")
}
