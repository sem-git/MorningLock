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
    @StateObject private var nativeAdViewModel = NativeAdViewModel()
    @StateObject var deviceActivityManager: DeviceActivityManager = .shared
    @StateObject private var storeKitManager = StoreKitManager.shared
    
    @EnvironmentObject var permissionManager: PermissionManager
    
    @State private var sheetHeight: CGFloat = .zero
    @State private var isAppLockPickerSheetPresented = false
    @State private var isSubscriptionSheetPresented = false
    @State private var canSave: Bool = false
    
    @State private var selectedSubscriptionType: SubscriptionType? = nil
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.alarmList.enumerated()), id: \.self.element.id) { (index, alarm) in
                        VStack(spacing: 1) {
                            // alarmList가 바뀔 때까지 업데이트 안 됨
                            AlarmItem(alarm: Binding(get: {
                                // 삭제 시 인덱스 오류 방지
                                if index > viewModel.alarmList.count - 1 {
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
                                    .semiBold17()
                                    .padding(.bottom, 8)
                                
                                Text(NSLocalizedString("appLockSubTitle", comment: "알람 후 15분동안 잠글게요"))
                                    .regular15(color: .gray200)
                                    .padding(.bottom, 16)
                                
                                HStack {
                                    if let selection = deviceActivityManager.selectedApp {
                                        ForEach(Array(selection.enumerated()).prefix(5), id: \.self.element) { index, token in
                                            if index >= 4 && selection.count > 5 {
                                                Rectangle()
                                                    .frame(width: 56, height: 56)
                                                    .foregroundStyle(.gray700)
                                                    .cornerRadius(16)
                                                    .overlay(
                                                        Text("+\(selection.count - 4)")
                                                            .semiBold17()
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
                                        isAppLockPickerSheetPresented = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
                
                if storeKitManager.subscriptionStatus == .notSubscribed {
                    Button(action: {
                        isSubscriptionSheetPresented = true
                    }) {
                        Text(NSLocalizedString("RemoveAdsButtonText", comment: "RemoveAdsButtonText"))
                            .semiBold16(color: .gray300)
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
                NativeAdMobView(nativeViewModel: nativeAdViewModel)
                    .frame(maxHeight: 64)
                    .padding(.horizontal, 16)
            })
            .animation(.default, value: viewModel.alarmList.count)
            
            // Sheet 1: 문의
            .sheet(isPresented: $viewModel.isContactFormPresented, content: {
                WebView(url: "https://docs.google.com/forms/d/e/1FAIpQLSduOHAV4hz962dKI66QEk8KmBkxgmQaT7hFD8xJQgCX4TQr8w/viewform?usp=dialog")
            })
            
            // Sheet 2: 잠금 앱 설정 안 한 상태로 알람을 켰을 때
            .sheet(isPresented: $viewModel.requiresAppSelectionSheet) {
                AppSelectionSheetView(
                    onSkip: { viewModel.requiresAppSelectionSheet.toggle() },
                    onConfigure: {
                        viewModel.requiresAppSelectionSheet.toggle()
                        isAppLockPickerSheetPresented = true
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
            .sheet(isPresented: $isAppLockPickerSheetPresented) {
                NavigationStack {
                    AppLockPickerSheetView(selection: $deviceActivityManager.selection, canSave: $canSave) {
                        if deviceActivityManager.isLockingNow {
                            deviceActivityManager.commitSelectionWhileLocking()
                        } else {
                            deviceActivityManager.save()
                        }
                        
                        isAppLockPickerSheetPresented = false
                    }
                    .onAppear {
                        if deviceActivityManager.isLockingNow {
                            canSave = deviceActivityManager.canSaveSelectionWhileLocking
                        } else {
                            canSave = true
                        }
                    }
                    .onChange(of: deviceActivityManager.selection.applicationTokens) { _, _ in
                        if deviceActivityManager.isLockingNow {
                            canSave = deviceActivityManager.canSaveSelectionWhileLocking
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
                    snoozeTime: Int(viewModel.snoozeTime / 60),
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
                    isSelected: $selectedSubscriptionType,
                    onSubscribe: {
                        await viewModel.purchaseSubscription(
                            type: selectedSubscriptionType
                        )
                    },
                    onRestorePurchases: {
                        await storeKitManager.restorePurchases()
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
            .onReceive(storeKitManager.$subscriptionStatus, perform: { subscriptionStatus in
                if subscriptionStatus == .notSubscribed {
                    nativeAdViewModel.loadAd()
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
    private var contactButton: some View {
        Button(action: {
            viewModel.isContactFormPresented.toggle()
        }, label: {
            Text(NSLocalizedString("contactButtonText", comment: "comment"))
                .regular15()
        })
    }
}

struct AppIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.icon
            .scaleEffect(2.5)
    }
}
