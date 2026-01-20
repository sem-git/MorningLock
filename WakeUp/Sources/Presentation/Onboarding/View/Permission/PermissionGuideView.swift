//
//  PermissionGuideView.swift
//  WakeUp
//
//  Created by a on 11/14/25.
//

import SwiftUI

struct PermissionGuideView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ZStack {
            Color.gray800
                .ignoresSafeArea()
            
            Image(.imgScreentime)
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        viewModel.navigate(to: .screenTimePermission)
                    } label: {
                        Color.clear
                    }
                    .frame(width: 145, height: 55)
                }
            
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("스크린타임과 알람 권한을 꼭 허용해주세요")
                        .bold22()
                        .multilineTextAlignment(.center)
                    
                    Text("아침 잠금을 사용하기 위해서 꼭 필요해요\n아래의 화면이 뜨면 계속을 눌러주세요")
                        .semiBold17(color: .gray200)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 48)
                
                Spacer()
                
                MainButton(title: String(localized: "다음으로")) {
                    viewModel.navigate(to: .screenTimePermission)
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    PermissionGuideView()
}
