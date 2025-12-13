import Foundation
import ManagedSettings
import DeviceActivity
import FamilyControls
import Combine

@MainActor
final class DeviceActivityManager: ObservableObject {
    static let shared = DeviceActivityManager()
    
    private let center = DeviceActivityCenter()
    private let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
        .encouraged: DeviceActivityEvent(
            threshold: DateComponents(minute: 1)
        )
    ]
    // MARK: - AppGruop Store
    
    /// 앱그룹 저장소
    private let sharedContainer = UserDefaults(suiteName: "group.com.awayke")
    /// 앱그룹 저장소 Key
    private let keyName = "testKey"
    
    // MARK: - Properties
    
    /// 앱 잠금 종료 시간 기록
    private var endTime = Date()
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    
    // MARK: - State
    
    /// 잠금 앱
    @Published var selectedApp: [ApplicationToken]? = nil
    @Published var selection = FamilyActivitySelection(includeEntireCategory: true)
    /// 앱 잠금 남은 시간
    @Published var remainingTime: TimeInterval = .zero
    /// 앱 잠금 남은 시간 표시용
    @Published var percent: Double = 0
    
    private init() {
        dataBind()
    }
    
    /// 앱그룹 저장소에 잠금 앱 저장
    func save() {
        let model = AppModel(selection: selection)
        do {
            let data = try JSONEncoder().encode(model)
            sharedContainer?.set(data, forKey: keyName)
            print("앱 잠금 선택 저장 완료")
        } catch {
            print("선택 저장 실패:", error)
        }
    }
    
    /// 잠금 앱 불러오기
    func load() {
        guard let data = sharedContainer?.data(forKey: keyName) else { return }
        do {
            let model = try JSONDecoder().decode(AppModel.self, from: data)
            selection = model.selection
            print("앱 잠금 선택 로드 완료")
        } catch {
            print("선택 로드 실패:", error)
        }
    }
    
    /// 잠금 앱 초기화
    func clear() {
        sharedContainer?.removeObject(forKey: keyName)
        selection = .init()
    }
    
    /// 잠금 앱 불러오기
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
    
    /// 모니터링 시작
    func startMonitoring(startAt date: Date) {
        let now = Date()
        let end = Calendar.current.date(byAdding: .minute, value: 15, to: date)!
        
        let startComponents = fullDateComponents(from: date)
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
            endTime = end
        } catch {
            print("DeviceActivity 모니터링 실패:", error)
        }
    }
    
    /// 모니터링 중지
    func stopMonitoring() {
        center.stopMonitoring([.testName])
        timer = nil
        print("DeviceActivity 모니터링 중단")
    }
    
    /// 타이머 시작
    func startTimer() {
        let totalTime = TimeInterval(minutes: 15)
        remainingTime = endTime.timeIntervalSince(.now)
        percent = (remainingTime / totalTime) * 100
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { _ in
                self.remainingTime -= 1
                self.percent = (self.remainingTime / totalTime) * 100
            })
    }
    
    /// 타이머 종료
    func stopTimer() {
        timer = nil
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
