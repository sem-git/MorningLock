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
                    .bold22()
                    .padding(.top, 48)
                
                Text("불필요한 앱을 아침에 잠궈드릴게요\n후다닥 외출 준비에 집중할 수 있어요")
                    .semiBold17(color: .gray200)
                    .padding(.top, 12)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Image(.imgOnboarding)
                
                Spacer()
                
                MainButton(title: String(localized: "시작하기")) {
                    viewModel.navigate(to: .permissionGuide)
                }
            }
            .padding(.horizontal, 16)
            .background(.gray800)
            .navigationDestination(for: OnboardingPath.self) { destination in
                switch destination {
                case .permissionGuide:
                    PermissionGuideView()
                case .screenTimePermission:
                    ScreenTimePermissionView()
                case .notificationPermission:
                    NotificationPermissionView()
                case .appLockSelection:
                    AppLockSelectionView()
                }
            }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    OnboardingView()
}
