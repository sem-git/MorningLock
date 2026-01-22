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
    @Binding var isSelected: SubscriptionType?
    
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
                    Text("커피 한 잔 가격으로 광고 없이 사용하세요")
                        .semiBold20()
                        .multilineTextAlignment(.center)
                    
                    Text("효율적인 아침을 앞으로도 도와드릴게요")
                        .semiBold17(color: .gray200)
                        .multilineTextAlignment(.center)
                }
                
                Image(.imgSubscription)
                
                VStack(spacing: 16) {
                    SubscriptionCell(
                        title: String(localized: "월 구독"),
                        discountText: "-25%",
                        originalPrice: "3,900₩",
                        discountedPrice: "2,900₩",
                        isHighlighted: false,
                        isSelected: isSelected == .monthly
                    )
                    .onTapGesture {
                        isSelected = isSelected == .monthly ? nil : .monthly
                    }
                    
                    SubscriptionCell(
                        title: String(localized: "연 구독"),
                        discountText: "-38%",
                        originalPrice: "46,800₩",
                        discountedPrice: "29,000₩",
                        isHighlighted: true,
                        isSelected: isSelected == .yearly
                    )
                    .onTapGesture {
                        isSelected = isSelected == .yearly ? nil : .yearly
                    }
                }
                
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        BulletText(text: String(localized: "상기 가격은 앱 출시 기념 한정 혜택가이며, 서비스 운영 정책 및 내부 사정에 따라 사전 고지 없이 변경될 수 있습니다."))
                        BulletText(text: String(localized: "구매를 확정하면 결제 금액이 Apple ID 계정으로 청구됩니다."))
                        BulletText(text: String(localized: "구독은 현재 이용 기간 종료 24시간 전까지 취소하지 않을 경우 자동으로 갱신됩니다."))
                        BulletText(text: String(localized: "갱신 요금은 현재 기간 종료 24시간 이내에 청구됩니다."))
                        BulletText(text: String(localized: "구독 관리 및 취소는 App Store 계정 설정에서 직접 변경할 수 있습니다."))
                        BulletText(text: String(localized: "자세한 내용은 이용약관 및 개인정보처리방침에서 확인하실 수 있습니다."))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 24) {
                        Button {
                            Task { await onRestorePurchases() }
                        } label: {
                            Text("구매 복원하기")
                                .underline()
                        }
                        
                        Button {
                            if let url = URL(string: "https://www.notion.so/2db236ba320180e58611c0e508826405?source=copy_link") {
                                openURL(url)
                            }
                        } label: {
                            Text("이용약관")
                                .underline()
                        }
                        
                        Button {
                            if let url = URL(string: "https://www.notion.so/2d2236ba320180c8a09ef58dce97639b?source=copy_link") {
                                openURL(url)
                            }
                        } label: {
                            Text("개인정보처리방침")
                                .underline()
                        }
                    }
                    .font(.regular13)
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
                    title: String(localized: "다음에 하기"),
                    buttonStyle: .text
                ) {
                    isPresented = false
                }
                
                MainButton(title: String(localized: "구입하기")) {
                    Task {
                        await onSubscribe()
                    }
                }
                .disabled(isSelected == nil)
                .opacity(isSelected == nil ? 0.5 : 1)
            }
        }
        .padding(.horizontal, 16)
    }
}
