//
//  SubscriptionCell.swift
//  WakeUp
//
//  Created by 이세민 on 12/20/25.
//

import SwiftUI

struct SubscriptionCell: View {
    let title: String
    let discountText: String
    let originalPrice: String
    let discountedPrice: String
    let isHighlighted: Bool
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Image(.icCheck)
                .renderingMode(.template)
                .foregroundColor(isSelected ? .gray50 : .gray300)
                .padding(.trailing, 16)
            
            Text(title)
                .font(.semiBold17)
                .foregroundColor(isHighlighted ? .neon : .white)
                .padding(.trailing, 12)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHighlighted ? .neon : .white)
                    .frame(width: 56, height: 29)
                
                Text(discountText)
                    .semiBold16(color: .black)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                Text(discountedPrice)
                    .heavy17(color: .neon)
                
                Text(originalPrice)
                    .regular15(color: .gray200)
                    .strikethrough()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray600)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? .gray100 : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut, value: isSelected)
    }
}

#Preview {
    VStack(spacing: 16) {
        // 월 구독 - 선택 x
        SubscriptionCell(
            title: "월 구독",
            discountText: "-25%",
            originalPrice: "3,900원",
            discountedPrice: "2,900원",
            isHighlighted: false,
            isSelected: false
        )
        
        // 월 구독 - 선택
        SubscriptionCell(
            title: "월 구독",
            discountText: "-25%",
            originalPrice: "3,900원",
            discountedPrice: "2,900원",
            isHighlighted: false,
            isSelected: true
        )
        
        // 연 구독 - 선택
        SubscriptionCell(
            title: "연 구독",
            discountText: "-38%",
            originalPrice: "46,800원",
            discountedPrice: "29,000원",
            isHighlighted: true,
            isSelected: true
        )
    }
    .padding(16)
}
