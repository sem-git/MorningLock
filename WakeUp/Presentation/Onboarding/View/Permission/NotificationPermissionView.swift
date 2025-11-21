//
//  NotificationPermissionView.swift
//  WakeUp
//
//  Created by 이세민 on 11/20/25.
//

import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                Text("알림 권한을 \n요청하고 있어요")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.gray50)
                    .padding(.top, 48)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            
            ZStack {
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                viewModel.requestNotificationPermission()
            }
        }
    }
}
