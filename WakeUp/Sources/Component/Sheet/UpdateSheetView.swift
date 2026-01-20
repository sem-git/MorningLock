//
//  UpdateSheetView.swift
//  WakeUp
//
//  Created by 이세민 on 1/19/26.
//

import SwiftUI

struct UpdateSheetView: View {
    let onSkip: () -> Void
    let onUpdate: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("아침잠금을 업데이트 해주세요")
                .semiBold20()
                .padding(.top, 24)
            
            Text("앱의 원활한 이용을 위해")
                .semiBold17(color: .gray200)
                .padding(.top, 8)
            
            Text("최신 버전으로 업데이트해 주세요")
                .semiBold17(color: .gray200)
            
            Image(.imgUpdate)
                .padding(.top, 16)
            
            HStack(spacing: 16) {
                MainButton(
                    title: String(localized: "다음에 하기"),
                    buttonStyle: .text
                ) {
                    onSkip()
                }
                
                MainButton(title: String(localized: "업데이트하기")) {
                    onUpdate()
                }
            }
            .padding(.top, 28)
        }
        .padding(.horizontal, 16)
    }
}
