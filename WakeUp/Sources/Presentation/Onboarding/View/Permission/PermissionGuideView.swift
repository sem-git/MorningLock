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
                    Text(NSLocalizedString("requestScreenTimeTitle", comment: "comment"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.gray50)
                        .multilineTextAlignment(.center)
                    
                    Text(NSLocalizedString("requestScreenTimeSubTitle", comment: "comment"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.gray200)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 48)
                
                Spacer()
                
                MainButton(title: NSLocalizedString("nextButtonText", comment: "comment")) {
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
