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
                    .background(.gray300)
                    .cornerRadius(16)
                
                Text(appName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.gray50)
                
                Spacer()
                
                Image(.check)
                    .renderingMode(.template)
                    .foregroundColor(isSelected ? .gray50 : .gray300)
            }
            .padding(16)
            .background(.gray600)
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
