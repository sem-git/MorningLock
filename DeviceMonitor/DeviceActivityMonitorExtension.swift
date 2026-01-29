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
            blockSelectedApps(selection)
        }
    }
    
    private func loadSelectedApps() -> FamilyActivitySelection? {
        let userDefaults = UserDefaults(suiteName: "group.com.awayke")
        
        guard
            let data = userDefaults?.data(forKey: "appLockStateKey"),
            let state = try? JSONDecoder().decode(AppLockState.self, from: data)
        else {
            return nil
        }
        
        return state.selection
    }
    
    private func blockSelectedApps(_ selection: FamilyActivitySelection) {
        store.shield.applications =
        selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        
        store.shield.applicationCategories =
        selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        
        store.shield.webDomains =
        selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}
