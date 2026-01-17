//
//  AppSelectionSheetView.swift
//  WakeUp
//
//  Created by 이세민 on 1/17/26.
//

import SwiftUI

struct AppSelectionSheetView: View {
    let onSkip: () -> Void
    let onConfigure: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("알람을 키셨네요")
                .semiBold20()
                .padding(.top, 24)
            
            Text("알람이 울릴 때 잠글 앱을 설정해볼까요")
                .semiBold17(color: .gray200)
                .padding(.top, 8)
            
            HStack(spacing: 16) {
                MainButton(
                    title: "알람만 키기",
                    buttonStyle: .text
                ) { onSkip() }
                
                MainButton(title: "설정하기") { onConfigure() }
            }
            .padding(.top, 28)
        }
        .padding(.horizontal, 16)
    }
}
