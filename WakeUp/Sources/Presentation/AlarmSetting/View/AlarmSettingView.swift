//
//  AlarmSettingView.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI

struct AlarmSettingView: View {
    @StateObject var viewModel: AlarmSettingViewModel
    @StateObject private var nativeViewModel = NativeAdViewModel(isDisabled: UserDefaults.standard.bool(forKey: StringLiteral.UserDefaultKeys.isPremiumSubscriber))
    @Environment(\.dismiss) var dismiss
    @AppStorage(StringLiteral.UserDefaultKeys.isPremiumSubscriber) var isSubscribed = true
    
    var body: some View {
        VStack(spacing: 16) {
            // 시간 설정
            DatePicker("", selection: $viewModel.alarm.fireDate, displayedComponents: .hourAndMinute)
                .environment(\.locale, Locale(identifier: "en_US"))
                .datePickerStyle(.wheel)
                .labelsHidden()
            
            // 요일 설정
            VStack(alignment: .leading, spacing: 14) {
                Text(NSLocalizedString("repeatTitle", comment: "반복"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.gray50)
                
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
        .navigationTitle(NSLocalizedString("alarmSettingScreenTitle", comment: "네비게이션 타이틀"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .bottom, content: {
            VStack {
                if !isSubscribed {
                    NativeAdMobView(nativeViewModel: nativeViewModel)
                        .frame(maxHeight: 64)
                        .padding(.horizontal, 16)                        
                }
                MainButton(title: NSLocalizedString("saveButtonText", comment: "저장하기"), disabled: viewModel.buttonDisabled) {
                    if viewModel.isEditing {
                        updateAlarm()
                    } else {
                        saveAlarm()
                    }
                }
                .padding(.horizontal, 16)
            }
            })
        .background(.gray800)
    }
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            Image(.icBack)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
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
