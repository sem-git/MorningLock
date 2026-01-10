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
        
        static let isPremiumSubscriber = "isPremiumSubscriber"
    }
    
    enum SubscriptionNotice {
        
        static let limitedPrice = "상기 가격은 앱 출시 기념 한정 혜택가이며, 서비스 운영 정책 및 내부 사정에 따라 사전 고지 없이 변경될 수 있습니다."
        
        static let appleBilling = "구매를 확정하면 결제 금액이 Apple ID 계정으로 청구됩니다."
        
        static let autoRenewal = "구독은 현재 이용 기간 종료 24시간 전까지 취소하지 않을 경우 자동으로 갱신됩니다."
        
        static let renewalCharge = "갱신 요금은 현재 기간 종료 24시간 이내에 청구됩니다."
        
        static let manageSubscription = "구독 관리 및 취소는 App Store 계정 설정에서 직접 변경할 수 있습니다."
        
        static let termsAndPrivacy = "자세한 내용은 이용약관 및 개인정보 처리방침에서 확인하실 수 있습니다."
    }
}
