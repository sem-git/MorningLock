//
//  ScreenTimePermissionView.swift
//  WakeUp
//
//  Created by 이세민 on 11/18/25.
//

import SwiftUI

struct ScreenTimePermissionView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                Text("스크린타임 권한을 \n요청하고 있어요")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.neutral)
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
        .background(.customBackground)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.requestScreenTimePermission()
        }
    }
}
