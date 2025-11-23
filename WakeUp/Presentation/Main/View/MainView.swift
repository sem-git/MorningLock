//
//  MainView.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(Array(viewModel.alarmList.enumerated()), id: \.self.element.id) { (index, alarm) in
                        HStack {
                            if viewModel.deleteMode {
                                Button {
                                    viewModel.deleteAlarm(alarm.id)
                                } label: {
                                    Text("삭제")
                                        .foregroundStyle(.red)
                                }
                            }
                            
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
                }
                .animation(.default, value: viewModel.isActiveAlarm)
                .padding(16)
            }
            .animation(.default, value: viewModel.alarmList.count)
            .overlay(content: {
                if viewModel.alarmList.isEmpty {
                    VStack(spacing: 12) {
                        Image(.alarm)
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundStyle(.gray)
                        
                        Text("설정된 알람이 없습니다.")
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                    }
                }
            })
            .onTapGesture {
                withAnimation {
                    viewModel.deleteMode = false
                }
            }
            .navigationBarItems(trailing: menuButton)
            .navigationBarItems(leading: completeButton)
            .background(.customBackground)
            .overlay(alignment: .bottomTrailing) {
                AddButton {
                    viewModel.navigateToAlarmSetting()
                }
                .offset(x: -16, y: -16)
            }
            .navigationDestination(for: MainRoute.self, destination: { destination in
                switch destination {
                case .alarmSetting(let alarm):
                    AlarmSettingView(viewModel: AlarmSettingViewModel(alarm: alarm))
                }
            })
            .alert(isPresented: $viewModel.isShowAlert) {
                Alert(
                    title: Text("설정"),
                    message: Text("알림 권한을 허용하지 않으면 알림이 울리지 않을 수 있습니다"),
                    primaryButton: .default(Text("설정하기"), action: {
                        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                            if UIApplication.shared.canOpenURL(appSettings) {
                                UIApplication.shared.open(appSettings)
                            }
                        }
                    }),
                    secondaryButton: .cancel(Text("취소"))
                )
            }
            .task {
                await viewModel.requestPermission()
                await viewModel.fetchAlarm()
            }
        }
    }
}

extension MainView {
    private func removeRows(at offsets: IndexSet) {
        viewModel.alarmList.remove(atOffsets: offsets)
    }
    
    private var menuButton: some View {
        Menu {
            Button {
                withAnimation {
                    viewModel.deleteMode = true
                }
            } label: {
                Label("알람 삭제", systemImage: "trash")
            }
            
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.white)
        }
    }
    
    private var completeButton: some View {
        Button("완료") {
            withAnimation {
                viewModel.deleteMode = false
            }
        }
        .opacity(viewModel.deleteMode ? 1 : 0)
        .disabled(!viewModel.deleteMode)
    }
}

#Preview {
    MainView()
}

