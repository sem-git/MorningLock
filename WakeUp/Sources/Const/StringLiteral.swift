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
    
    enum AppLinks {
        static let contactForm = "https://docs.google.com/forms/d/e/1FAIpQLSduOHAV4hz962dKI66QEk8KmBkxgmQaT7hFD8xJQgCX4TQr8w/viewform?usp=dialog"
        static let termsOfUse = "https://www.notion.so/2db236ba320180e58611c0e508826405?source=copy_link"
        static let privacyPolicy = "https://www.notion.so/2d2236ba320180c8a09ef58dce97639b?source=copy_link"
    }
}
