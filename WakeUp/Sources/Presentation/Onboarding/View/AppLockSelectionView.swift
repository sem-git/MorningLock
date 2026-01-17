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
            Text(NSLocalizedString("appSelectTitle", comment: "comment"))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.gray50)
                .padding(.top, 48)
            
            Text(NSLocalizedString("appSelectSubTitle", comment: "comment"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.gray200)
                .padding(.top, 12)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            HStack(spacing: 16) {
                MainButton(
                    title: NSLocalizedString("skipButtonText", comment: "comment"),
                    buttonStyle: .text
                ) {
                    addDefaultAlarm()
                }
                
                MainButton(title: NSLocalizedString("addButtonText", comment: "comment")) {
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
                AppLockPickerSheet(deviceManager: deviceManager, canSave: .constant(true)) {
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
