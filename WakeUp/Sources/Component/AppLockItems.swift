//
//  AppLockItems.swift
//  WakeUp
//
//  Created by 이세민 on 1/18/26.
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct AppLockItems: View {
    let selectedApps: [ApplicationToken]?
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("잠글 앱")
                .semiBold17()
                .padding(.bottom, 8)
            
            Text("알람 후 15분 동안 잠글게요")
                .regular15(color: .gray200)
                .padding(.bottom, 16)
            
            HStack(spacing: 12) {
                if let selectedApps = selectedApps {
                    ForEach(Array(selectedApps.enumerated()).prefix(5), id: \.element) { index, token in
                        if index >= 4 && selectedApps.count > 5 {
                            Rectangle()
                                .frame(width: 56, height: 56)
                                .foregroundStyle(.gray700)
                                .cornerRadius(16)
                                .overlay(
                                    Text("+\(selectedApps.count - 4)")
                                        .semiBold17()
                                )
                        } else {
                            Label(token)
                                .labelStyle(AppIconLabelStyle())
                                .frame(width: 56, height: 56)
                        }
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                        
                        Image(.icPlus)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.gray600)
        .cornerRadius(16)
        .onTapGesture {
            onTap()
        }
    }
}
