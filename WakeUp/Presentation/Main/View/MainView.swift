//
//  MainView.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var sheetHeight: CGFloat = .zero
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(Array(viewModel.alarmList.enumerated()), id: \.self.element.id) { (index, alarm) in
                        // alarmList가 바뀔떄까지 업데이트 안됨
                        AlarmView(alarm: Binding(get: {
                            // 삭제시 인덱스 오류 방지
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
                        
                    }
                }
                .padding(16)
            }
            .animation(.default, value: viewModel.alarmList.count)
            
            .sheet(isPresented: $viewModel.alarmSheetPresented, onDismiss: {
                viewModel.fetchAlarm()
            }, content: {
                VStack(spacing: 0) {
                    Text("알림이 울렸습니다")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.top, 24)
                    
                    Text("지금부터 15분동안 설정한 앱들을 잠글게요")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    
                    Image(.imgLock)
                        .padding(.top, 16)
                    
                    HStack(spacing: 16) {
                        MainButton(title: "5분 후 다시 알림", buttonStyle: .text) {
                            viewModel.snoozeAlarm(by: .minutes(5))
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
            .background(.customBackground)
            .overlay(alignment: .bottomTrailing) {
                AddButton {
                    viewModel.navigateToAlarmSetting()
                }
                .offset(x: -16, y: -16)
            }
            .onAppear {
                viewModel.requestPermission()
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
