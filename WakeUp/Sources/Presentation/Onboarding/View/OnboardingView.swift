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
                
                Text(NSLocalizedString("onboardingTitle", comment: "comment"))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.gray50)
                    .padding(.top, 48)
                
                Text(NSLocalizedString("onboardingSubTitle", comment: "comment"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.gray200)
                    .padding(.top, 12)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Image(.imgOnboarding)
                
                Spacer()
                
                MainButton(title: NSLocalizedString("StartButtonText", comment: "comment")) {
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
