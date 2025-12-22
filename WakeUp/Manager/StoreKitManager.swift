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
    
    private let productIDs: [String] = [
        "com.awayke.subscription.monthly",
        "com.awayke.subscription.yearly"
    ]
    
    @Published var products: [Product] = [] // App Store에서 받아온 상품 메타데이터
    @Published var isSubscribed: Bool = false // 지금 유저가 구독 중인지
    
    init() {
        Task {
            await requestProducts()
            await updateSubscriptionStatus()
        }
        
        Task.detached {
            await self.listenForTransactions()
        }
    }
    
    /// 상품 정보 가져오기
    func requestProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("실패", error)
        }
    }
    
    /// 결제 수행
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    print("Verification 실패")
                    return
                }
                
                await transaction.finish()
                await updateSubscriptionStatus()
                
            case .userCancelled:
                print("사용자 취소")
                
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
        isSubscribed = false
        
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               productIDs.contains(transaction.productID) {
                isSubscribed = true
                return
            }
        }
    }
    
    /// 앱 실행 중 발생하는 모든 결제 이벤트 감시
    func listenForTransactions() async {
        for await result in StoreKit.Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await updateSubscriptionStatus()
            }
        }
    }
}
