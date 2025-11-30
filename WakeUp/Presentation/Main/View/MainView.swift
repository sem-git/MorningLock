//
//  MainView.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI
import FamilyControls
import DeviceActivity

struct MainView: View {
    @StateObject var viewModel: MainViewModel = MainViewModel()
    @State private var sheetHeight: CGFloat = .zero
    
    // 임시
    @StateObject private var manager = DeviceActivityManager()
    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(Array(viewModel.alarmList.enumerated()), id: \.self.element.id) { (index, alarm) in
                        // alarmList가 바뀔 때까지 업데이트 안됨
                        AlarmView(alarm: Binding(get: {
                            // 삭제 시 인덱스 오류 방지
                            if index > viewModel.alarmList.count-1 {
                                return AlarmEntity(id: UUID(), time: .now, isActive: false, repeatDay: [])
                            } else {
                                return alarm
                            }
                        }, set: {
                            viewModel.alarmList[index] = $0
                            viewModel.updateAlarm($0)
                        }))
                        .onTapGesture {
                            viewModel.navigateToAlarmSetting(alarm)
                        }
                        
                        // 임시 버튼
                        HStack(spacing: 12) {
                            Button {
                                isPickerPresented = true
                            } label: {
                                Text("앱 선택")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                manager.saveSelection(selection)
                            } label: {
                                Text("저장")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(16)
            }
            .animation(.default, value: viewModel.alarmList.count)
            // 임시 FamilyActivityPicker 시트
            .sheet(isPresented: $isPickerPresented) {
                NavigationStack {
                    FamilyActivityPicker(selection: $selection)
                        .navigationTitle("앱 선택")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(
                isPresented: $viewModel.alarmSheetPresented,
                onDismiss: {
                    viewModel.fetchAlarm()
                },
                content: {
                    VStack(spacing: 0) {
                        Text("알림이 울렸습니다")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.top, 24)
                        
                        Text("지금부터 15분동안 설정한 앱들을 잠글게요\n*3회 중 \(viewModel.snoozeCount)회 울림")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .multilineTextAlignment(.center)
                        
                        Image(.imgLock)
                            .padding(.top, 16)
                        
                        HStack(spacing: 16) {
                            MainButton(
                                title: "\(Int(viewModel.snoozeTime / 60))분 후 다시 알림",
                                disabled: viewModel.snoozeDisabled,
                                buttonStyle: .text
                            ) {
                            viewModel.snoozeAlarm()
                        }
                        MainButton(title: "알람 끄기") {
                            viewModel.deactiveAlarm()
                        }
                    }
                }
                .presentationDetents([.height(sheetHeight)])
                .interactiveDismissDisabled(true)
                .padding(.horizontal, 16)
                .overlay {
                    GeometryReader { geometry in
                        Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                    }
                }
                .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                    sheetHeight = newHeight
                }
            })
            .navigationBarItems(trailing: contactButton)
            .background(.gray800)
            .overlay(alignment: .bottomTrailing) {
                AddButton {
                    viewModel.navigateToAlarmSetting()
                }
                .offset(x: -16, y: -16)
            }
            .onAppear {
                viewModel.fetchAlarm()
            }
            .navigationDestination(for: MainRoute.self, destination: { destination in
                switch destination {
                case .alarmSetting(let alarm):
                    AlarmSettingView(viewModel: AlarmSettingViewModel(alarm: alarm))
                }
            })
        }
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - SubViews
extension MainView {
    private func removeRows(at offsets: IndexSet) {
        viewModel.alarmList.remove(atOffsets: offsets)
    }
    
    private var contactButton: some View {
        Button(action: {
            
        }, label: {
            Text("문의")
        })
    }
}

#Preview {
    MainView()
}
