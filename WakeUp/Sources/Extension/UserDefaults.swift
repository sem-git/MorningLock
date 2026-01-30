//
//  UserDefaults.swift
//  WakeUp
//
//  Created by 이세민 on 1/30/26.
//

import Foundation

extension UserDefaults {
    
    // MARK: - App Group 접근
    
    private static let suite = "group.com.awayke"
    
    static var sharedAppGroup: UserDefaults? { UserDefaults(suiteName: suite) }

    // MARK: - 선택 앱 목록 저장 및 불러오기
    
    @objc var appLockSelectionData: Data {
        get { data(forKey: StringLiteral.UserDefaultKeys.appGroupStorageKey) ?? Data() }
        set { set(newValue, forKey: StringLiteral.UserDefaultKeys.appGroupStorageKey) }
    }

    func saveAppLockSelection(_ selection: AppSelection) {
        if let data = try? JSONEncoder().encode(selection) {
            appLockSelectionData = data
        }
    }

    func loadAppLockSelection() -> AppSelection? {
        guard !appLockSelectionData.isEmpty else { return nil }
        return try? JSONDecoder().decode(AppSelection.self, from: appLockSelectionData)
    }
    
    // MARK: - 잠금 상태 저장 및 불러오기
    
    var appLockState: AppLockState? {
        get {
            guard let data = data(forKey: StringLiteral.UserDefaultKeys.appLockStateKey) else { return nil }
            return try? JSONDecoder().decode(AppLockState.self, from: data)
        }
        set {
            if let newValue {
                let data = try? JSONEncoder().encode(newValue)
                set(data, forKey: StringLiteral.UserDefaultKeys.appLockStateKey)
            } else {
                removeObject(forKey: StringLiteral.UserDefaultKeys.appLockStateKey)
            }
        }
    }
}
