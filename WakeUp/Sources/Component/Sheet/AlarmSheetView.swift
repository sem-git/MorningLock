//
//  AlarmSheetView.swift
//  WakeUp
//
//  Created by 이세민 on 1/17/26.
//

import SwiftUI

struct AlarmSheetView: View {
    let snoozeCount: Int
    let snoozeTime: Int
    let snoozeDisabled: Bool
    
    let onSnooze: () -> Void
    let onDeactivate: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("알람이 울렸습니다")
                .semiBold20()
                .padding(.top, 24)
            
            Text("지금부터 15분 동안 설정한 앱들을 잠글게요")
                .semiBold17(color: .gray200)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            Text(String(localized: "*3회 중 \(snoozeCount)회 울림"))
                .semiBold17(color: .gray200)
                .foregroundStyle(.gray200)
                .multilineTextAlignment(.center)
            
            Image(.imgLock)
                .padding(.top, 16)
                .padding(.bottom, 28)
            
            HStack(spacing: 16) {
                MainButton(
                    title: String(localized: "5분 후 다시 알림"),
                    disabled: snoozeDisabled,
                    buttonStyle: .text
                ) {
                    onSnooze()
                }
                
                MainButton(title: String(localized: "알람 끄기")) {
                    onDeactivate()
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
