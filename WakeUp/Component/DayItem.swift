//
//  DayButton.swift
//  WakeUp
//
//  Created by 이세민 on 11/21/25.
//

import SwiftUI

struct DayItem: View {
    let title: String
    
    var isSelected: Bool = false
    var action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .gray50 : .gray400)
                .frame(width: 39, height: 37)
                .background(isSelected ? .gray500 : .clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 18.5)
                        .stroke(isSelected ? Color.clear : Color.gray300, lineWidth: 1)
                )
                .cornerRadius(18.5)
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        DayItem(title: "월", isSelected: true)
        DayItem(title: "화", isSelected: false)
    }
    .padding()
    .background(.gray800)
}
