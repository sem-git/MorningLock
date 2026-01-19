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
    
    @StateObject var deviceManager: DeviceActivityManager = .shared
    
    @State private var isPickerPresented = false
    
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
                    addDefaultAlarm()
                }
                
                MainButton(title: String(localized: "추가하기")) {
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
                AppLockPickerSheetView(selection: $deviceManager.selection, canSave: .constant(true)) {
                    withAnimation {
                        deviceManager.save()
                        addDefaultAlarm()
                        isPickerPresented = false
                    }
                }
            }
        }
    }
    
    func addDefaultAlarm() {
        Task {            
            let calendar = Calendar.current
            let now = Date()
            
            let fireDate = calendar.date(
                bySettingHour: 7,
                minute: 30,
                second: 0,
                of: now
            )!
            
            let alarm = AlarmEntity(
                fireDate: fireDate,
                isActive: false,
                repeatDay: [.mon, .thu, .wed, .tue, .fri]
            )
            
            await AlarmManager.shared.addAlarm(alarm)
            viewModel.isOnboarding = false
        }
    }
}
