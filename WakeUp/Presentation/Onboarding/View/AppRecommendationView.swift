//
//  AppRecommendationView.swift
//  WakeUp
//
//  Created by a on 11/14/25.
//

import SwiftUI

struct AppRecommendationView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            
            Text("많이 쓰는 앱을 모아봤어요")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.neutral)
                .padding(.top, 48)
            
            Text("이 중에 아침에 잠그고 싶은 앱이 있다면 추가해주세요")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.tertiary)
                .padding(.top, 12)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 8){
                Spacer()
                
                Image(.check)
                    .renderingMode(.template)
                    .foregroundColor(.neutralTertiary)
                
                Text("전체 선택")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.neutralSecondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { _ in
                        AppSelectionItem(appName: "카카오톡", isSelected: false)
                    }
                }
            }
            
            HStack(spacing: 16) {
                MainButton(
                    title: "건너뛰기",
                    disabled: true,
                    buttonStyle: .text
                )
                
                MainButton(title: "추가하기") {
                    viewModel.isOnboarding = false
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 16)
        .background(.customBackground)
    }
}

#Preview {
    AppRecommendationView()
}
