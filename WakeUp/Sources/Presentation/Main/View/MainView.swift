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
import StoreKit

struct MainView: View {
    @StateObject var viewModel: MainViewModel = MainViewModel()
    @StateObject private var nativeViewModel = NativeAdViewModel()
    @State private var sheetHeight: CGFloat = .zero
    
    @StateObject var deviceManager: DeviceActivityManager = .shared
    @EnvironmentObject var permissionManager: PermissionManager
    
    @State private var isPickerPresented = false
    @State private var isSubscriptionSheetPresented = false
    @State private var canSave: Bool = false
    
    @State private var selectedSubscription: SubscriptionType? = nil
    @StateObject private var store = StoreKitManager.shared
    
    @Environment(\.openURL) private var openURL
    
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
                                    await viewModel.handleAppLockTap(
                                        permissionManager: permissionManager
                                    ) {
                                        isPickerPresented = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
                
                if store.subscriptionStatus == .notSubscribed {
                    Button(action: {
                        isSubscriptionSheetPresented = true
                    }) {
                        Text(NSLocalizedString("RemoveAdsButtonText", comment: "RemoveAdsButtonText"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray300)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.gray300, lineWidth: 1)
                            )
                    }
                }
            }
            .overlay(alignment: .bottom, content: {
                NativeAdMobView(nativeViewModel: nativeViewModel)
                    .frame(maxHeight: 64)
                    .padding(.horizontal, 16)
            })
            .animation(.default, value: viewModel.alarmList.count)
            
            // Sheet 1: 문의
            .sheet(isPresented: $viewModel.isWebViewPresented, content: {
                WebView(url: "https://docs.google.com/forms/d/e/1FAIpQLSduOHAV4hz962dKI66QEk8KmBkxgmQaT7hFD8xJQgCX4TQr8w/viewform?usp=dialog")
            })
            
            // Sheet 2: 잠금 앱 설정 안 한 상태로 알람을 켰을 때
            .sheet(isPresented: $viewModel.isAppSelectionPresented) {
                AppSelectionSheetView(
                    onSkip: { viewModel.toggleAppSelection() },
                    onConfigure: {
                        viewModel.toggleAppSelection()
                        isPickerPresented = true
                    }
                )
                .presentationDetents([.height(sheetHeight)])
                .overlay {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: InnerHeightPreferenceKey.self,
                            value: geometry.size.height
                        )
                    }
                }
                .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                    sheetHeight = newHeight
                }
            }
            
            // Sheet 3: 잠금 앱 선택
            .sheet(isPresented: $isPickerPresented) {
                NavigationStack {
                    AppLockPickerSheetView(selection: $deviceManager.selection, canSave: $canSave) {
                        if deviceManager.isLockingNow {
                            deviceManager.commitSelectionWhileLocking()
                        } else {
                            deviceManager.save()
                        }
                        
                        isPickerPresented = false
                    }
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
                }
            }
            
            // Sheet 4: 알람 울렸을 때
            .sheet(
                isPresented: $viewModel.isAlarmSheetPresented,
                onDismiss: { viewModel.fetchAlarm() }
            ) {
                AlarmSheetView(
                    snoozeCount: viewModel.snoozeCount,
                    snoozeMinutes: Int(viewModel.snoozeTime / 60),
                    snoozeDisabled: viewModel.snoozeDisabled,
                    onSnooze: { viewModel.snoozeAlarm() },
                    onDeactivate: { viewModel.deactiveAlarm() }
                )
                .presentationDetents([.height(sheetHeight)])
                .interactiveDismissDisabled(true)
                .padding(.horizontal, 16)
                .overlay {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: InnerHeightPreferenceKey.self,
                            value: geometry.size.height
                        )
                    }
                }
                .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                    sheetHeight = newHeight
                }
            }
            
            // Sheet 5: 구독
            .sheet(isPresented: $isSubscriptionSheetPresented, content: {
                SubscriptionSheetView(
                    isPresented: $isSubscriptionSheetPresented,
                    selectedSubscription: $selectedSubscription,
                    onSubscribe: {
                        await viewModel.purchaseSubscription(
                            type: selectedSubscription
                        )
                    },
                    onRestorePurchases: {
                        await store.restorePurchases()
                    }
                )
                .presentationDetents([.large])
                .padding(.horizontal, 16)
            })
            .background(.gray800)
            .onAppear {
                viewModel.fetchAlarm()
                viewModel.requestTrackingAuthorization()
            }
            .onReceive(store.$subscriptionStatus, perform: { subscriptionStatus in
                if subscriptionStatus == .notSubscribed {
                    nativeViewModel.loadAd()
                }
            })
            .navigationBarItems(trailing: contactButton)
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
            viewModel.toggleWebView()
        }, label: {
            Text(NSLocalizedString("contactButtonText", comment: "comment"))
                .foregroundStyle(.gray50)
                .font(Font.system(size: 15, weight: .regular))
        })
    }
}

struct AppIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.icon
            .scaleEffect(2.5)
    }
}
