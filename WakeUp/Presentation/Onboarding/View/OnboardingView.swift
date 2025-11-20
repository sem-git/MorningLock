//
//  OnboardingView.swift
//  WakeUp
//
//  Created by a on 11/13/25.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel = OnboardingViewModel()
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            VStack(alignment: .center, spacing: 0) {
                
                Text("의지가 깨어나는 시간")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.neutral)
                    .padding(.top, 48)
                
                Text("불필요한 앱을 아침에 잠궈드릴게요\n후다닥 외출 준비에 집중할 수 있어요")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.tertiary)
                    .padding(.top, 12)
                    .multilineTextAlignment(.center)
                
                Spacer()
                Image(.onboarding)
                Spacer()
                MainButton(title: "시작하기") {
                    viewModel.navigate(to: .screenTimePermission)
                }
            }
            .padding(.horizontal, 16)
            .background(.customBackground)
            .navigationDestination(for: OnboardingPath.self) { destination in
                switch destination {
                case .permissionGuide:
                    PermissionGuideView()
                case .appRecommendation:
                    AppRecommendationView()
                case .screenTimePermission:
                    PermissionGuideView()
                }
            }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    OnboardingView()
}
