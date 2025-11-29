//
//  AppLockSelectionStore.swift
//  WakeUp
//
//  Created by 이세민 on 11/29/25.
//

import Foundation
import FamilyControls
import Combine

@MainActor
final class AppLockSelectionStore: ObservableObject {
    static let shared = AppLockSelectionStore()
    
    @Published var selection: FamilyActivitySelection = .init()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.awayke")
    private let key = "appLockSelection"
    
    func save() {
        let model = AppModel(selection: selection)
        do {
            let data = try JSONEncoder().encode(model)
            userDefaults?.set(data, forKey: key)
            print("앱 잠금 선택 저장 완료")
        } catch {
            print("선택 저장 실패:", error)
        }
    }
    
    func load() {
        guard let data = userDefaults?.data(forKey: key) else { return }
        do {
            let model = try JSONDecoder().decode(AppModel.self, from: data)
            selection = model.selection
            print("앱 잠금 선택 로드 완료")
        } catch {
            print("선택 로드 실패:", error)
        }
    }
    
    func clear() {
        userDefaults?.removeObject(forKey: key)
        selection = .init()
    }
}
