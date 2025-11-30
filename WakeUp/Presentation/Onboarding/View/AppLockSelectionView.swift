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
    @EnvironmentObject var selectionStore: AppLockSelectionStore
    
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
                
                MainButton(
                    title: "추가하기"
                ) {
                    isPickerPresented = true
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 16)
        .background(.gray800)
        .sheet(isPresented: $isPickerPresented) {
            NavigationStack {
                FamilyActivityPicker(selection: $selectionStore.selection)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("앱 선택")
                                .font(.system(size: 20, weight: .bold))
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("완료") {
                                withAnimation {
                                    selectionStore.save()
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
            await AlarmManager.shared.addAlarm(.init())
            viewModel.isOnboarding = false
        }
    }
}
