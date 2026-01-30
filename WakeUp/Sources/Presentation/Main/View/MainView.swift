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
    @State private var isUpdateSheetPresented = false
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
                            
                            AppLockItems(
                                selectedApps: deviceActivityManager.hasSelectedApps ? deviceActivityManager.selectedApps : nil,
                                onTap: {
                                    Task {
                                        deviceActivityManager.selection = deviceActivityManager.committedSelection
                                        await viewModel.handleAppLockTap(
                                            permissionManager: permissionManager
                                        ) {
                                            isAppLockPickerSheetPresented = true
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(16)
                
                if storeKitManager.subscriptionStatus == .notSubscribed {
                    Button(action: {
                        isSubscriptionSheetPresented = true
                    }) {
                        Text("광고 없이 사용하기")
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
            .sheet(isPresented: $viewModel.showLockSuggestionSheet) {
                LockSuggestionSheetView(
                    onSkip: { viewModel.showLockSuggestionSheet.toggle() },
                    onConfigure: {
                        viewModel.showLockSuggestionSheet.toggle()
                        isAppLockPickerSheetPresented = true
                    }
                )
                .presentationDetents([.height(sheetHeight)])
                .trackSheetHeight($sheetHeight)
            }
            
            // Sheet 3: 잠금 앱 선택
            .sheet(isPresented: $isAppLockPickerSheetPresented) {
                NavigationStack {
                    AppLockPickerSheetView(selection: $deviceActivityManager.selection, canSave: $viewModel.canSave) {
                        if deviceActivityManager.isLockingNow {
                            deviceActivityManager.commitAdditionalApps()
                        } else {
                            deviceActivityManager.saveSelection()
                        }
                        
                        isAppLockPickerSheetPresented = false
                    }
                    .onAppear {
                        viewModel.updateCanSave()
                    }
                    .onChange(of: deviceActivityManager.selection.applicationTokens) { _, _ in
                        viewModel.updateCanSave()
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
                .trackSheetHeight($sheetHeight)
                .interactiveDismissDisabled(true)
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
            
            // Sheet 6: 업데이트 안내
            .sheet(isPresented: $isUpdateSheetPresented) {
                UpdateSheetView(
                    onSkip: {
                        isUpdateSheetPresented = false
                    },
                    onUpdate: {
                        isUpdateSheetPresented = false
                    }
                )
                .presentationDetents([.height(sheetHeight)])
                .trackSheetHeight($sheetHeight)
            }
            
            // Sheet 7: 일정 시간 경과로 잠금 스킵
            .sheet(isPresented: $viewModel.isLockSkipSheetPresented) {
                LockSkipSheetView(
                    onClose: {
                        viewModel.isLockSkipSheetPresented = false
                    }
                )
                .presentationDetents([.height(sheetHeight)])
                .trackSheetHeight($sheetHeight)
            }
            
        }
    }
}

// MARK: - SubViews

extension MainView {
    private var contactButton: some View {
        Button(action: {
            viewModel.isContactFormPresented.toggle()
        }, label: {
            Text("문의")
                .regular15()
        })
    }
}
