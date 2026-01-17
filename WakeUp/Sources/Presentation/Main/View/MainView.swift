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

// 임시로 MainView에
enum SubscriptionType {
    case monthly
    case yearly
}

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
            
            // MARK: - Sheet
            // 문의
            .sheet(isPresented: $viewModel.isWebViewPresented, content: {
                WebView(url: "https://docs.google.com/forms/d/e/1FAIpQLSduOHAV4hz962dKI66QEk8KmBkxgmQaT7hFD8xJQgCX4TQr8w/viewform?usp=dialog")
            })
            // 잠금 앱 설정 안 한 상태로 알람을 켰을 때
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

            // 잠금 앱 선택
            .sheet(isPresented: $isPickerPresented) {
                NavigationStack {
                    AppLockPickerSheet(deviceManager: deviceManager, canSave: $canSave) {
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
            
            // 알람이 울렸을 때
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
            .sheet(isPresented: $isSubscriptionSheetPresented, content: {
                subscriptionSheetView
                    .presentationDetents([.large])
                    .padding(.horizontal, 16)
            })
            .navigationBarItems(trailing: contactButton)
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
    
    private var subscriptionSheetView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                Spacer()
                
                Button {
                    isSubscriptionSheetPresented = false
                } label: {
                    Image(.icX)
                }
            }
            .padding(.top, 16)
            
            ScrollView {
                VStack(spacing: 8) {
                    Text(NSLocalizedString("PromotionSheetTitle", comment: "커피 한 잔 가격으로 광고 없이 사용하세요"))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.gray50)
                        .multilineTextAlignment(.center)
                    
                    Text(NSLocalizedString("PromotionSheetSubTitle", comment: "효율적인 아침을 앞으로도 도와드릴게요"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.gray200)
                        .multilineTextAlignment(.center)
                }
                
                Image(.imgSubscription)
                
                VStack(spacing: 16) {
                    SubscriptionCell(
                        title: NSLocalizedString("Monthly", comment: "월 구독"),
                        discountText: "-25%",
                        originalPrice: "3,900₩",
                        discountedPrice: "2,900₩",
                        isHighlighted: false,
                        isSelected: selectedSubscription == .monthly
                    )
                    .onTapGesture {
                        toggleSubscription(.monthly)
                    }
                    
                    SubscriptionCell(
                        title: NSLocalizedString("Yearly", comment: "연 구독"),
                        discountText: "-38%",
                        originalPrice: "46,800₩",
                        discountedPrice: "29,000₩",
                        isHighlighted: true,
                        isSelected: selectedSubscription == .yearly
                    )
                    .onTapGesture {
                        toggleSubscription(.yearly)
                    }
                }
                
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        BulletText(text: NSLocalizedString("SubscriptionLimitedPrice", comment: "SubscriptionLimitedPrice"))
                        BulletText(text: NSLocalizedString("SubscriptionAppleBilling", comment: "SubscriptionAppleBilling"))
                        BulletText(text: NSLocalizedString("SubscriptionAutoRenewal", comment: "SubscriptionAutoRenewal"))
                        BulletText(text: NSLocalizedString("SubscriptionRenewalCharge", comment: "SubscriptionRenewalCharge"))
                        BulletText(text: NSLocalizedString("SubscriptionManageSubscription", comment: "SubscriptionManageSubscription"))
                        BulletText(text: NSLocalizedString("SubscriptionTermsAndPrivacy", comment: "SubscriptionTermsAndPrivacy"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 24) {
                        Button {
                            Task {
                                await store.restorePurchases()
                            }
                        } label: {
                            Text(NSLocalizedString("RestorePurchaseButtonText", comment: "RestorePurchaseButtonText"))
                                .underline()
                        }
                        
                        Button {
                            if let url = URL(string: "https://www.notion.so/2db236ba320180e58611c0e508826405?source=copy_link") {
                                openURL(url)
                            }
                        } label: {
                            Text(NSLocalizedString("TermsOfUseButtonText", comment: "TermsOfUseButtonText"))
                                .underline()
                        }
                        
                        Button {
                            if let url = URL(string: "https://www.notion.so/2d2236ba320180c8a09ef58dce97639b?source=copy_link") {
                                openURL(url)
                            }
                        } label: {
                            Text(NSLocalizedString("PrivacyPolicyButtonText", comment: "PrivacyPolicyButtonText"))
                                .underline()
                        }
                    }
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.gray50)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.black)
                )
            }
            .scrollIndicators(.hidden)
            
            HStack(spacing: 16) {
                MainButton(
                    title: NSLocalizedString("SubscribeLaterButtonText", comment: "SubscribeLaterButtonText"),
                    buttonStyle: .text
                ) {
                    isSubscriptionSheetPresented = false;
                }
                MainButton(title: NSLocalizedString("SubscribeButtonText", comment: "SubscribeButtonText")) {
                    Task {
                        await purchaseSelectedSubscription()
                    }
                }
                .disabled(selectedSubscription == nil)
                .opacity(selectedSubscription == nil ? 0.5 : 1)
            }
        }
    }
    
    private func toggleSubscription(_ type: SubscriptionType) {
        selectedSubscription = selectedSubscription == type ? nil : type
    }
    
    @MainActor
    private func purchaseSelectedSubscription() async {
        guard let selectedSubscription else {
            return
        }
        
        let product: Product?
        
        switch selectedSubscription {
        case .monthly:
            product = store.products.first {
                $0.id == "com.awayke.subscription.monthly"
            }
            
        case .yearly:
            product = store.products.first {
                $0.id == "com.awayke.subscription.yearly"
            }
        }
        
        guard let product else {
            print("선택된 Product 없음:", store.products.map { $0.id })
            return
        }
        
        await store.purchase(product)
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

