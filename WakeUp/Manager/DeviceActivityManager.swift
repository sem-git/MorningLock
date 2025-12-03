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
    @Published var selection = FamilyActivitySelection(includeEntireCategory: true)
    
    init() {
        dataBind()
    }
    
    func dataBind() {
        if let container = sharedContainer {
            if container.value(forKey: "testKey") == nil {
                // 처음에 저장소가 존재하지 않는 경우 초기화
                let defaultAppModel = AppModel(selection: .init())
                if let data = try? JSONEncoder().encode(defaultAppModel) {
                    container.set(data, forKey: "testKey")
                }
            }
            
            container
                .publisher(for: \.testKey)
                .decode(type: AppModel.self, decoder: JSONDecoder())
                .map { Array($0.selection.applicationTokens) }
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { value in
                    self.selectedApp = value.isEmpty ? nil : value
                    self.selection.applicationTokens = Set(value)
                })
                .store(in: &cancellables)
            
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
