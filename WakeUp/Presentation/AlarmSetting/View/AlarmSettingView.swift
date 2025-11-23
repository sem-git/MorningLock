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
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 1) {
                        // 시간 설정
                        DatePicker("", selection: $viewModel.time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                        
                        // 요일 설정
                        VStack(alignment: .leading, spacing: 14) {
                            Text("반복")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.neutral)
                            
                            GeometryReader { geometry in
                                let itemSize = (geometry.size.width - 10 * 6) / 7
                                HStack(alignment: .center, spacing: 10) {
                                    ForEach(Weekday.allCases, id: \.self) { day in
                                        let daySelected = viewModel.weekDays.contains(day)
                                        Text(day.dayName)
                                            .font(.system(size: 16, weight: .semibold))
                                            .frame(width: itemSize, height: itemSize)
                                            .background(daySelected ? .neutralHover : .clear)
                                            .foregroundStyle(daySelected ? .white : .defaultSecondary)
                                            .clipShape(Circle())
                                            .overlay(RoundedRectangle(cornerRadius: itemSize / 2).stroke(daySelected ? .clear : .neutralSecondary, lineWidth: 1))
                                            .onTapGesture {
                                                viewModel.selecteDay(day)
                                            }
                                    }
                                }
                            }
                            .frame(height: 50)
                        }
                        .padding(16)
                        .background(.default)
                        .cornerRadius(16)
                        HStack {
                            Text("다시 알림")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.neutral)
                            
                            Toggle("Repeat Alarm", isOn: .constant(false))
                        }
                        .padding(16)
                        .background(.default)
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
                let isEditing = viewModel.alarm != nil
                
                MainButton(title: isEditing ? "수정 하기" : "저장 하기") {
                    if isEditing {
                        viewModel.updateAlarm()
                    } else {
                        viewModel.saveAlarm()
                    }
                    dismiss()
                }
                .padding(.horizontal, 16)
            })
            .background(.customBackground)
    }
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            Image(.backbutton)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
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
                Image(.rightIcon)
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
