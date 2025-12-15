//
//  StringLiteral.swift
//  WakeUp
//
//  Created by a on 12/16/25.
//

import Foundation

enum StringLiteral {
    enum UserDefaultKeys {
        /// 사용자가 선택한 잠금 앱 목록
        static let appGroupStorageKey = "appGroupStorageKey"
        /// 잠금이 진행 중인 앱 목록
        static let appLockStateKey = "appLockStateKey"
        /// 온보딩 완료 여부
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
}
