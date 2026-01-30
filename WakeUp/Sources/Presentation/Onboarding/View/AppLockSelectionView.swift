//
//  AppLockSelectionView.swift
//  WakeUp
//
//  Created by a on 11/14/25.
//

import FamilyControls
import SwiftUI
import DeviceActivity
import ManagedSettings
import ExtensionKit

struct AppLockSelectionView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var permissionManager: PermissionManager
    
    @StateObject var deviceActivityManager: DeviceActivityManager = .shared
    
    @State private var isPickerPresented = false
    @State private var canSave: Bool = true
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("알람이 울리면 잠글 앱을 설정해주세요")
                .bold22()
                .padding(.top, 48)
                .multilineTextAlignment(.center)
            
            Text("추가하기를 누르면 앱 선택 화면이 뜰 거예요")
                .semiBold17(color: .gray200)
                .padding(.top, 12)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            HStack(spacing: 16) {
                MainButton(
                    title: String(localized: "건너뛰기"),
                    buttonStyle: .text
                ) {
                    Task {
                        await viewModel.completeOnboardingWithDefaultAlarm()
                    }
                }
                
                MainButton(title: String(localized: "추가하기")) {
                    Task {
                        if await viewModel.requestScreenTimeIfNeeded(
                            permissionManager: permissionManager
                        ) {
                            isPickerPresented = true
                        }
                    }
                }
                
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 16)
        .background(.gray800)
        .sheet(isPresented: $isPickerPresented) {
            NavigationStack {
                AppLockPickerSheetView(selection: $deviceActivityManager.selection, canSave: $canSave) {
                    Task {
                        withAnimation {
                            deviceActivityManager.saveSelection()
                            isPickerPresented = false
                        }
                        
                        await viewModel.completeOnboardingWithDefaultAlarm()
                    }
                }
                .onChange(of: deviceActivityManager.selection.applicationTokens) {
                    let count = deviceActivityManager.selection.applicationTokens.count
                    canSave = count <= 20
                }
            }
        }
    }
}
