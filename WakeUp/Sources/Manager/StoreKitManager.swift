//
//  StoreKitManager.swift
//  WakeUp
//
//  Created by 이세민 on 12/20/25.
//

import SwiftUI
import StoreKit
import Combine

@MainActor
class StoreKitManager: ObservableObject {
    
    static let shared = StoreKitManager()
    
    // 구독 상태를 나타냄
    enum SubscriptionStatus {
        case subscribed      // 구독중
        case notSubscribed   // 미구독
        case unknown         // 로딩
    }
    
    // App Store Connect에 등록한 상품 ID
    private let productIDs: [String] = [
        "com.awayke.subscription.monthly",
        "com.awayke.subscription.yearly"
    ]
    
    // App Store에서 받아온 상품 정보
    @Published var products: [Product] = []
    
    // 지금 유저가 구독 중인지
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    
    private init() {
        Task {
            await requestProducts()
            await updateSubscriptionStatus()
            await listenForTransactions()
        }
    }
    
    /// 상품 메타데이터 로드
    func requestProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            print("상품 로드: ", products.map { $0.id })
        } catch {
            print("실패: ", error)
        }
    }
    
    /// 사용자가 상품을 구매했을 때 호출
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
                
            case .success(let verification):
                
                guard case .verified(let transaction) = verification else {
                    print("검증 실패")
                    return
                }
                
                guard isValidSubscription(transaction) else {
                    print("환불되었거나 만료된 구독")
                    await transaction.finish()
                    return
                }
                
                print("구매 성공:", transaction.productID)
                
                await transaction.finish()
                await updateSubscriptionStatus()
                
            case .userCancelled:
                print("사용자 결제 취소")
                
            case .pending:
                print("결제 대기 중")
                
            @unknown default:
                break
            }
        } catch {
            print("구매 실패:", error)
        }
    }
    
    /// 이전에 구독 중이었는지 확인 (앱 재설치 / 기기 변경 대응)
    func updateSubscriptionStatus() async {        
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard productIDs.contains(transaction.productID) else { continue }
            
            if isValidSubscription(transaction) {
                subscriptionStatus = .subscribed                
                print("현재 활성 구독:", transaction.productID)
                return
            }
        }
        subscriptionStatus = .notSubscribed
        print("활성 구독 없음")
    }
    
    /// 유효한 구독인지 확인
    func isValidSubscription(_ transaction: StoreKit.Transaction) -> Bool {
        
        if transaction.revocationDate != nil {
            print("환불된 거래")
            return false
        }
        
        if let expirationDate = transaction.expirationDate {
            if expirationDate <= Date() {
                print("구독 만료:", expirationDate)
                return false
            }
        }
        
        if transaction.isUpgraded {
            print("업그레이드된 구독")
            return false
        }
        
        return true
    }
    
    /// 앱 실행 중 발생하는 모든 결제, 갱신, 복원 감시
    func listenForTransactions() async {
        for await result in StoreKit.Transaction.updates {
            
            guard case .verified(let transaction) = result else { continue }
            
            print("거래 업데이트:", transaction.productID)
            
            await transaction.finish()
            await updateSubscriptionStatus()
        }
    }
    
    /// 구매 복원 버튼 눌렀을 때  호출
    func restorePurchases() async {
        print("구매 복원 시도")

        await updateSubscriptionStatus()       
    }
}
