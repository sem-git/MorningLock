//
//  SubscriptionSheetView.swift
//  WakeUp
//
//  Created by 이세민 on 1/18/26.
//

import SwiftUI

enum SubscriptionType {
    case monthly
    case yearly
    
    var productId: String {
        switch self {
        case .monthly:
            return "com.awayke.subscription.monthly"
        case .yearly:
            return "com.awayke.subscription.yearly"
        }
    }
}

struct SubscriptionSheetView: View {
    @Binding var isPresented: Bool
    @Binding var selectedSubscription: SubscriptionType?
    
    let onSubscribe: () async -> Void
    let onRestorePurchases: () async -> Void
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Image(.icX)
                }
            }
            .padding(.top, 16)
            
            ScrollView {
                VStack(spacing: 8) {
                    Text(NSLocalizedString("PromotionSheetTitle", comment: "커피 한 잔 가격으로 광고 없이 사용하세요"))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.gray50)
                        .multilineTextAlignment(.center)
                    
                    Text(NSLocalizedString("PromotionSheetSubTitle", comment: "효율적인 아침을 앞으로도 도와드릴게요"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.gray200)
                        .multilineTextAlignment(.center)
                }
                
                Image(.imgSubscription)
                
                VStack(spacing: 16) {
                    SubscriptionCell(
                        title: NSLocalizedString("Monthly", comment: "월 구독"),
                        discountText: "-25%",
                        originalPrice: "3,900₩",
                        discountedPrice: "2,900₩",
                        isHighlighted: false,
                        isSelected: selectedSubscription == .monthly
                    )
                    .onTapGesture {
                        selectedSubscription = selectedSubscription == .monthly ? nil : .monthly
                    }
                    
                    SubscriptionCell(
                        title: NSLocalizedString("Yearly", comment: "연 구독"),
                        discountText: "-38%",
                        originalPrice: "46,800₩",
                        discountedPrice: "29,000₩",
                        isHighlighted: true,
                        isSelected: selectedSubscription == .yearly
                    )
                    .onTapGesture {
                        selectedSubscription = selectedSubscription == .yearly ? nil : .yearly
                    }
                }
                
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        BulletText(text: NSLocalizedString("SubscriptionLimitedPrice", comment: "SubscriptionLimitedPrice"))
                        BulletText(text: NSLocalizedString("SubscriptionAppleBilling", comment: "SubscriptionAppleBilling"))
                        BulletText(text: NSLocalizedString("SubscriptionAutoRenewal", comment: "SubscriptionAutoRenewal"))
                        BulletText(text: NSLocalizedString("SubscriptionRenewalCharge", comment: "SubscriptionRenewalCharge"))
                        BulletText(text: NSLocalizedString("SubscriptionManageSubscription", comment: "SubscriptionManageSubscription"))
                        BulletText(text: NSLocalizedString("SubscriptionTermsAndPrivacy", comment: "SubscriptionTermsAndPrivacy"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 24) {
                        Button {
                            Task { await onRestorePurchases() }
                        } label: {
                            Text(NSLocalizedString("RestorePurchaseButtonText", comment: "RestorePurchaseButtonText"))
                                .underline()
                        }
                        
                        Button {
                            if let url = URL(string: "https://www.notion.so/2db236ba320180e58611c0e508826405?source=copy_link") {
                                openURL(url)
                            }
                        } label: {
                            Text(NSLocalizedString("TermsOfUseButtonText", comment: "TermsOfUseButtonText"))
                                .underline()
                        }
                        
                        Button {
                            if let url = URL(string: "https://www.notion.so/2d2236ba320180c8a09ef58dce97639b?source=copy_link") {
                                openURL(url)
                            }
                        } label: {
                            Text(NSLocalizedString("PrivacyPolicyButtonText", comment: "PrivacyPolicyButtonText"))
                                .underline()
                        }
                    }
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.gray50)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.black)
                )
            }
            .scrollIndicators(.hidden)
            
            HStack(spacing: 16) {
                MainButton(
                    title: NSLocalizedString("SubscribeLaterButtonText", comment: "SubscribeLaterButtonText"),
                    buttonStyle: .text
                ) {
                    isPresented = false
                }
                MainButton(title: NSLocalizedString("SubscribeButtonText", comment: "SubscribeButtonText")) {
                    Task {
                        await onSubscribe()
                    }
                }
                .disabled(selectedSubscription == nil)
                .opacity(selectedSubscription == nil ? 0.5 : 1)
            }
        }
    }
}
