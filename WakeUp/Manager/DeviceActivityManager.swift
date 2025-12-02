import Foundation
import ManagedSettings
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
    private let sharedContainer = UserDefaults(suiteName: "group.com.awayke")
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var selectedApp: [ApplicationToken]? = nil
    
    init() {
        dataBind()
    }
    
    func dataBind() {
        sharedContainer?
            .publisher(for: \.testKey)
            .decode(type: AppModel.self, decoder: JSONDecoder())
            .map { Array($0.selection.applicationTokens) }
            .replaceNil(with: [])
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
            }, receiveValue: {
                self.selectedApp = $0
            })
            .store(in: &cancellables)
    }
    
    // Extension에서 읽을 앱 선택 정보 저장
    func saveSelection(_ selection: FamilyActivitySelection) {
        let model = AppModel(selection: selection)
        
        do {
            let data = try JSONEncoder().encode(model)
            sharedContainer?.set(data, forKey: "testKey")
            print("앱 선택 저장 완료")
        } catch {
            print("앱 선택 저장 실패", error)
        }
    }
    
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

extension UserDefaults {
    @objc var testKey: Data {
        get {
            return data(forKey: "testKey") ?? Data()
        }
        set {
            set(newValue, forKey: "testKey")
        }
    }
}
