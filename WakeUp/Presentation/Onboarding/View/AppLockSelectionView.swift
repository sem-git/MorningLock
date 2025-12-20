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
    @StateObject var deviceManager: DeviceActivityManager = .shared
    @EnvironmentObject var permissionManager: PermissionManager
    
    @State private var isPickerPresented = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("알람이 울리면 잠글 앱을 설정해주세요")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.gray50)
                .padding(.top, 48)
            
            Text("추가하기를 누르면 앱 선택 화면이 뜰 거에요")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.gray200)
                .padding(.top, 12)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            HStack(spacing: 16) {
                MainButton(
                    title: "건너뛰기",
                    buttonStyle: .text
                ) {
                    addDefaultAlarm()
                }
                
                MainButton(title: "추가하기") {
                    Task {
                        switch permissionManager.screenTimeStatus {
                            
                        case .authorized:
                            isPickerPresented = true
                            
                        case .unknown, .denied:
                            await permissionManager.requestScreenTime()
                            
                            if permissionManager.screenTimeStatus == .authorized {
                                isPickerPresented = true
                            }
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
                FamilyActivityPicker(selection: $deviceManager.selection)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("앱 선택")
                                .font(.system(size: 20, weight: .bold))
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("완료") {
                                withAnimation {
                                    deviceManager.save()
                                    addDefaultAlarm()
                                    isPickerPresented = false
                                }
                            }
                        }
                    }
            }
        }
    }
    
    func addDefaultAlarm() {
        Task {
            let isActive = permissionManager.notificationStatus == .authorized
            
            let alarm = AlarmEntity(
                fireDate: Date().addingTimeInterval(60),
                isActive: false,
                repeatDay: []
            )
            
            await AlarmManager.shared.addAlarm(alarm)
            viewModel.isOnboarding = false
        }
    }
}
