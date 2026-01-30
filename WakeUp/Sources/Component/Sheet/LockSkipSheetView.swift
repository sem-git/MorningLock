//
//  LockSkipSheetView.swift
//  WakeUp
//
//  Created by 이세민 on 1/21/26.
//

import SwiftUI

struct LockSkipSheetView: View {
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("알람이 울린 지 오랜 시간이 지났어요")
                .semiBold20()
                .padding(.top, 24)
            
            Text("한시간 이상 전에 알람이 울려")
                .semiBold17(color: .gray200)
                .padding(.top, 8)
            
            Text("지금은 잠금 설정을 하지 않을게요")
                .semiBold17(color: .gray200)
            
            Image(.imgException)
                .padding(.top, 16)
                .padding(.bottom, 28)
            
            MainButton(title: String(localized: "닫기")) {
                onClose()
            }
        }
        .padding(.horizontal, 16)
    }
}
