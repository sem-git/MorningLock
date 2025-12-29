//
//  SubscriptionCardView.swift
//  WakeUp
//
//  Created by 이세민 on 12/20/25.
//

import SwiftUI

struct SubscriptionCardView: View {
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
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isHighlighted ? .neon : .white)
                .padding(.trailing, 12)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHighlighted ? .neon : .white)
                    .frame(width: 56, height: 29)
                
                Text(discountText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                Text(discountedPrice)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.neon)
                
                Text(originalPrice)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.gray200)
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
