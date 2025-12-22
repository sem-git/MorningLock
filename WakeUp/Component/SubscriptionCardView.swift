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
    let description: String
    let isHighlighted: Bool
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .fontWeight(.bold)
                .foregroundColor(isHighlighted ? .neon : .white)
                .padding(.top, 10)
            
            ZStack {
                Circle()
                    .fill(isHighlighted ? .neon : .white)
                    .frame(width: 70, height: 70)
                
                Text(discountText)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
            }
            .padding(.top, 13)
            
            Text(originalPrice)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray200)
                .strikethrough()
                .padding(.top, 9)
            
            Text(discountedPrice)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.neon)
            
            Text(description)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray200)
                .padding(.top, 13)
                .padding(.bottom, 9)
            
        }
        .frame(width: 136, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray800)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut, value: isSelected)
    }
}
