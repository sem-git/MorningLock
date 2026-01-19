//
//  AlarmSettingView.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI

struct AlarmSettingView: View {
    @StateObject var viewModel: AlarmSettingViewModel
    @StateObject private var nativeViewModel = NativeAdViewModel()
    @StateObject private var store = StoreKitManager.shared
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // 시간 설정
            DatePicker("", selection: $viewModel.alarm.fireDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
            
            // 요일 설정
            VStack(alignment: .leading, spacing: 14) {
                Text("반복")
                    .semiBold17()
                
                HStack(alignment: .center, spacing: 8) {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        let daySelected = viewModel.weekDays.contains(day)
                        DayItem(title: day.dayName, isSelected: daySelected) {
                            viewModel.selecteDay(day)
                        }
                    }
                }
            }
            .padding(16)
            .background(.gray600)
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .navigationBarItems(leading: backButton)
        .navigationTitle(String(localized: "알람 설정"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .bottom, content: {
            VStack(spacing: 16) {
                NativeAdMobView(nativeViewModel: nativeViewModel)
                    .frame(maxHeight: 64)
                    
                MainButton(title: String(localized: "저장하기"), disabled: viewModel.buttonDisabled) {
                    if viewModel.isEditing {
                        updateAlarm()
                    } else {
                        saveAlarm()
                    }
                }
            }
            .padding(.horizontal, 16)
            })
        .background(.gray800)
        .onReceive(store.$subscriptionStatus, perform: { subscriptionStatus in
            if subscriptionStatus == .notSubscribed {
                nativeViewModel.loadAd()
            }
        })
    }
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            Image(.icBack)
        }
    }
    
    private func saveAlarm() {
        Task {
            await viewModel.saveAlarm()
            dismiss()
        }
    }
    
    private func updateAlarm() {
        viewModel.updateAlarm()
        dismiss()
    }
}
