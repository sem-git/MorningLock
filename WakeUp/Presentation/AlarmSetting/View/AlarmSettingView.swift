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
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    // 시간 설정
                    DatePicker("", selection: $viewModel.alarm.time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                    
                    // 요일 설정
                    VStack(alignment: .leading, spacing: 14) {
                        Text("반복")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.gray50)
                        
                        GeometryReader { geometry in
                            let itemSize = (geometry.size.width - 10 * 6) / 7
                            HStack(alignment: .center, spacing: 10) {
                                ForEach(Weekday.allCases, id: \.self) { day in
                                    let daySelected = viewModel.weekDays.contains(day)
                                    DayButton(title: day.dayName, isSelected: daySelected) {
                                        viewModel.selecteDay(day)
                                    }
                                }
                            }
                        }
                        .frame(height: 50)
                    }
                    .padding(16)
                    .background(.gray600)
                    .cornerRadius(16)
                }
                .padding(16)
            }
        }
        .navigationBarItems(leading: backButton)
        .navigationTitle("알람 설정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .bottom, content: {
            VStack {
                NativeAdMobView(nativeViewModel: nativeViewModel)
                    .frame(maxHeight: 50)
                MainButton(title: viewModel.isEditing ? "수정 하기" : "저장 하기") {
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

struct SettingOption: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                }
                Spacer()
                Image(.icRight)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

//#Preview {
//    AlarmSettingView(viewModel: AlarmSettingViewModel())
//}
