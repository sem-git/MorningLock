//
//  AppSelectionItem.swift
//  WakeUp
//
//  Created by a on 11/14/25.
//

import SwiftUI

struct AppSelectionItem: View {
    let appName: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            HStack(spacing: 16) {
                Image("")
                    .resizable()
                    .frame(width: 54, height: 54)
                    .background(.neutralTertiary)
                    .cornerRadius(16)
                
                Text(appName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.neutral)
                
                Spacer()
                
                Image(.check)
                    .renderingMode(.template)
                    .foregroundColor(isSelected ? .neutral : .neutralTertiary)
            }
            .padding(16)
            .background(.default)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct AppSelectionItem_Previews: PreviewProvider {
    @State static var isSelected = true
    
    static var previews: some View {
        AppSelectionItem(appName: "카카오톡", isSelected: $isSelected)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
