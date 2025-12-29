//
//  MainView.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI
import FamilyControls
import DeviceActivity
import GoogleMobileAds

struct MainView: View {
    @StateObject var viewModel: MainViewModel = MainViewModel()
    @StateObject private var nativeViewModel = NativeAdViewModel()
    @State private var sheetHeight: CGFloat = .zero
    
    @StateObject var deviceManager: DeviceActivityManager = .shared
    @EnvironmentObject var permissionManager: PermissionManager
    
    @State private var isPickerPresented = false
    @State private var canSave: Bool = false
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.alarmList.enumerated()), id: \.self.element.id) { (index, alarm) in
                        VStack(spacing: 1) {
                            // alarmList가 바뀔 때까지 업데이트 안 됨
                            AlarmItem(alarm: Binding(get: {
                                // 삭제 시 인덱스 오류 방지
                                if index > viewModel.alarmList.count-1 {
                                    return AlarmEntity()
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
                            
                            // TODO: 컴포넌트로 분리 예정
                            VStack(alignment: .leading, spacing: 0) {
                                Text(NSLocalizedString("appLockTitle", comment: "앱 잠금"))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.gray50)
                                    .padding(.bottom, 8)
                                
                                Text(NSLocalizedString("appLockSubTitle", comment: "알람 후 15분동안 잠글게요"))
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(.gray200)
                                    .padding(.bottom, 16)
                                
                                HStack {
                                    if let selection = deviceManager.selectedApp {
                                        ForEach(Array(selection.enumerated()).prefix(5), id: \.self.element) { index, token in
                                            if index >= 4 && selection.count > 5 {
                                                Rectangle()
                                                    .frame(width: 56, height: 56)
                                                    .foregroundStyle(.gray700)
                                                    .cornerRadius(16)
                                                    .overlay(
                                                        Text("+\(selection.count - 4)")
                                                            .font(.system(size: 17, weight: .semibold))
                                                            .foregroundStyle(.gray50)
                                                    )
                                            } else {
                                                Label(token)
                                                    .labelStyle(AppIconLabelStyle())
                                                    .frame(width: 56, height: 56)
                                            }
                                            
                                        }
                                    } else {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
                                                .foregroundColor(.white)
                                                .frame(width: 56, height: 56)
                                            
                                            Image(.icPlus)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.gray600)
                            .cornerRadius(16)
                            .onTapGesture {
                                Task {
                                    switch permissionManager.screenTimeStatus {
                                        
                                    case .authorized:
                                        isPickerPresented = true
                                        
                                    case .unknown, .denied:
                                        await permissionManager.requestScreenTime()
                                        
                                        if permissionManager.screenTimeStatus == .authorized {
                                            isPickerPresented = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .overlay(alignment: .bottom, content: {
                NativeAdMobView(nativeViewModel: nativeViewModel)
                    .frame(maxHeight: 64)
                    .padding(.horizontal, 16)
                    .opacity(nativeViewModel.isLoading ? 0 : 1)
            })
            .animation(.default, value: viewModel.alarmList.count)
            .sheet(isPresented: $viewModel.isWebViewPresented, content: {
                WebView(url: "https://docs.google.com/forms/d/e/1FAIpQLSduOHAV4hz962dKI66QEk8KmBkxgmQaT7hFD8xJQgCX4TQr8w/viewform?usp=dialog")                
            })
            .sheet(isPresented: $viewModel.isAppSelectionPresented, content: {
                appSelectionSheet
                    .presentationDetents([.height(sheetHeight)])
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
            // TODO: 컴포넌트로 분리
            .sheet(isPresented: $isPickerPresented) {
                NavigationStack {
                    FamilyActivityPicker(selection: $deviceManager.selection)
                        .onAppear {
                            if deviceManager.isLockingNow {
                                canSave = deviceManager.canSaveSelectionWhileLocking
                            } else {
                                canSave = true
                            }
                        }
                        .onChange(of: deviceManager.selection.applicationTokens) { _, _ in
                            if deviceManager.isLockingNow {
                                canSave = deviceManager.canSaveSelectionWhileLocking
                            } else {
                                canSave = true
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text(NSLocalizedString("SelectApps", comment: "앱 선택"))
                                    .font(.system(size: 20, weight: .bold))
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button(NSLocalizedString("Complete", comment: "완료")) {
                                    if deviceManager.isLockingNow {
                                        deviceManager.commitSelectionWhileLocking()
                                    } else {
                                        deviceManager.save()
                                    }
                                    
                                    isPickerPresented = false
                                }
                                .disabled(!canSave)
                            }
                        }
                }
            }
            .sheet(
                isPresented: $viewModel.isAlarmSheetPresented,
                onDismiss: {
                    viewModel.fetchAlarm()
                },
                content: {
                    alarmSheetView
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
            .onAppear {
                viewModel.fetchAlarm()
                viewModel.requestTrackingAuthorization()
                
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
    
    private var appSelectionSheet: some View {
        VStack(spacing: 0) {
                Text("알람을 키셨네요")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.gray50)
                    .padding(.top, 24)
                Text("알람이 울릴 때 잠글 앱을 설정해볼까요")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.gray200)
                    .padding(.top, 8)
            
            HStack(spacing: 16) {
                MainButton(
                    title: "알람만 키기" ,
                    buttonStyle: .text,
                    action: viewModel.toggleAppSelection
                )
                MainButton(title: "설정하기") {
                    viewModel.toggleAppSelection()
                    isPickerPresented = true
                }
            }
            .padding(.top, 28)
        }
    }
    
    private var contactButton: some View {
        Button(action: {
            viewModel.toggleWebView()
        }, label: {
            Text(NSLocalizedString("contactButtonText", comment: "comment"))
                .foregroundStyle(.gray50)
                .font(Font.system(size: 15, weight: .regular))
        })
    }
    
    private var alarmSheetView: some View {
        VStack(spacing: 0) {
            Text(NSLocalizedString("alarmRiningTitle", comment: "알람이 울렸습니다."))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.top, 24)
            
            Text(NSLocalizedString("alarmRiningSubTitle", comment: "알람 횟수 표시"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            Text(String(format: NSLocalizedString("alarmRingingCount", comment: "알람 횟수 표시"), viewModel.snoozeCount))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Image(.imgLock)
                .padding(.top, 16)
            
            HStack(spacing: 16) {
                MainButton(
                    title: String(format: NSLocalizedString("snoozeButtonText", comment: "스누즈 버튼"), Int(viewModel.snoozeTime / 60)),
                    disabled: viewModel.snoozeDisabled,
                    buttonStyle: .text
                ) {
                    viewModel.snoozeAlarm()
                }
                MainButton(title: NSLocalizedString("deactiveAlarmText", comment: "알람 끄기")) {
                    viewModel.deactiveAlarm()
                }
            }
        }
    }
}

struct AppIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.icon
            .scaleEffect(2.5)
    }
}

#Preview {
    MainView()
}

