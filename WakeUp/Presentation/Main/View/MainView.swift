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
                .padding(16)
            }
            .animation(.default, value: viewModel.alarmList.count)
            .sheet(isPresented: $viewModel.alarmSheetPresented, content: {
                VStack(spacing: 0) {
                    Text("알람이 울렸네요")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.top, 24)
                    
                    Text("지금부터 잠길거임")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    
                    Image(.imgNoadd)
                    
                    HStack(spacing: 16) {
                        MainButton(title: "5분 후 다시 알림", buttonStyle: .text)
                        MainButton(title: "알람 끄기")
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

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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

