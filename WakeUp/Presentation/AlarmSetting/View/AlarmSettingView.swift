//
//  AlarmSettingView.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI

struct AlarmSettingView: View {
    @StateObject var viewModel: AlarmSettingViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // 시간 설정
            DatePicker("", selection: $viewModel.alarm.fireDate, displayedComponents: .hourAndMinute)
                .environment(\.locale, Locale(identifier: "en_US"))
                .datePickerStyle(.wheel)
                .labelsHidden()
            
            // 요일 설정
            VStack(alignment: .leading, spacing: 14) {
                Text("반복")
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
        .navigationTitle("알람 설정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .bottom, content: {
            MainButton(title: viewModel.isEditing ? "수정 하기" : "저장 하기") {
                if viewModel.isEditing {
                    updateAlarm()
                } else {
                    saveAlarm()
                }
            }
            .padding(.horizontal, 16)
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
