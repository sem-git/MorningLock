//
//  RemoteConfigManager.swift
//  WakeUp
//
//  Created by a on 1/27/26.
//

import Foundation

import FirebaseRemoteConfig

class RemoteConfigManager {
    static let shared = RemoteConfigManager()
    
    let remoteConfig = RemoteConfig.remoteConfig()
    let settings = RemoteConfigSettings()
    
    init() {
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }
    
    func getMinimumAppVersion() async -> Int? {
        do {
            try await remoteConfig.fetch()
            try await remoteConfig.activate()
            return remoteConfig["currentAppVersion"].numberValue.intValue
        } catch {
            return nil
        }
    }
}
