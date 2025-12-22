//
//  DeviceActivityMonitorExtension.swift
//  DeviceMonitor
//
//  Created by 이세민 on 11/21/25.
//

import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
     
        if let selection = loadSelectedApps() {
            print("앱 목록 로드 성공")
            blockSelectedApps(selection)
        }
    }

    private func loadSelectedApps() -> FamilyActivitySelection? {
        let userDefaults = UserDefaults(suiteName: "group.com.awayke")
        guard let data = userDefaults?.data(forKey: "appLockStateKey") else {
            return nil
        }
        
        do {
            let model = try JSONDecoder().decode(AppModel.self, from: data)
            return model.selection
        } catch {
            print("앱 목록 로드 실패: \(error)")
            return nil
        }
    }
    
    private func blockSelectedApps(_ selection: FamilyActivitySelection) {
        // 앱 차단 설정
        store.shield.applications = selection.applicationTokens.isEmpty ?
            nil : selection.applicationTokens
        
        // 카테고리 차단 설정
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
        ? nil
        : .specific(selection.categoryTokens)
        
        // 웹 도메인 차단 설정 (필요한 경우)
        store.shield.webDomains = selection.webDomainTokens.isEmpty
        ? nil
        : selection.webDomainTokens
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
     
        // 모든 차단 해제
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        print("interval 종료 - 차단 해제")
    }
}
