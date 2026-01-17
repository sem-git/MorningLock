//
//  NotificationPermissionView.swift
//  WakeUp
//
//  Created by 이세민 on 11/20/25.
//

import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var permissionManager: PermissionManager
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                Text(NSLocalizedString("requestNotificationProgess", comment: "comment"))
                    .bold22()
                    .padding(.top, 48)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            
            if viewModel.isRequestingPermission {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2.0)
                    .tint(.white)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray800)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.isRequestingPermission = true
            
            Task {
                await permissionManager.requestNotification()
                viewModel.isRequestingPermission = false
                viewModel.navigate(to: .appLockSelection)
            }
        }
    }
}
