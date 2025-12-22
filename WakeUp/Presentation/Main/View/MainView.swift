//
//  MainView.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI
import FamilyControls
import DeviceActivity
import StoreKit

// 임시로 MainView에
enum SubscriptionType {
    case monthly
    case yearly
}

struct MainView: View {
    @StateObject var viewModel: MainViewModel = MainViewModel()
    @State private var sheetHeight: CGFloat = .zero
    
    @StateObject var deviceManager: DeviceActivityManager = .shared
    @EnvironmentObject var permissionManager: PermissionManager
    
    @State private var isPickerPresented = false
    @State private var isSubscriptionSheetPresented = false
    @State private var canSave: Bool = false
    
    @State private var selectedSubscription: SubscriptionType = .yearly
    @StateObject private var store = StoreKitManager()
    
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
                            
                            // TODO: 컴포넌트로 분리 예정
                            VStack(alignment: .leading, spacing: 0) {
                                Text("잠글 앱")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.gray50)
                                    .padding(.bottom, 8)
                                
                                Text("알람 후 15분 동안 잠글게요")
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
                                                    .onTapGesture {
                                                        isPickerPresented = true
                                                    }
                                            } else {
                                                Label(token)
                                                    .labelStyle(AppIconLabelStyle())
                                                    .frame(width: 56, height: 56)
                                                    .onTapGesture {
                                                        isPickerPresented = true
                                                    }
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.gray600)
                            .cornerRadius(16)
                        }
                        //                        .opacity(alarm.isActive ? 1 : 0.3)
                    }
                }
                .padding(16)
                
                Button(action: {
                    isSubscriptionSheetPresented = true
                }) {
                    Text("광고없이 사용하기")
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
            .animation(.default, value: viewModel.alarmList.count)
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
                                Text("앱 선택")
                                    .font(.system(size: 20, weight: .bold))
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("완료") {
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
            
            // TODO: 타이머 뷰가 나타날 때 sheet 비활성화
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
            }
            .navigationDestination(for: MainRoute.self, destination: { destination in
                switch destination {
                case .alarmSetting(let alarm):
                    AlarmSettingView(viewModel: AlarmSettingViewModel(alarm: alarm))
                }
            })
            
            .sheet(isPresented: $isSubscriptionSheetPresented, content: {
                subscriptionSheetView
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
                .foregroundStyle(.gray50)
                .font(Font.system(size: 15, weight: .regular))
        })
    }
    
    private var alarmSheetView: some View {
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
    }
    
    private var subscriptionSheetView: some View {
        VStack(spacing: 0) {
            Text("앱 출시 기념 할인가")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.gray50)
                .padding(.top, 24)
            
            Text("효율적인 아침을 앞으로도 도와드릴게요")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.gray200)
                .padding(.top, 8)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                SubscriptionCardView(
                    title: "월 구독",
                    discountText: "-25%",
                    originalPrice: "3,900원",
                    discountedPrice: "2,900원",
                    description: "",
                    isHighlighted: false,
                    isSelected: selectedSubscription == .monthly
                )
                .onTapGesture {
                    selectedSubscription = .monthly
                }
                
                SubscriptionCardView(
                    title: "연 구독",
                    discountText: "-38%",
                    originalPrice: "46,800원",
                    discountedPrice: "29,000원",
                    description: "4개월 상당분 할인",
                    isHighlighted: true,
                    isSelected: selectedSubscription == .yearly
                )
                .onTapGesture {
                    selectedSubscription = .yearly
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 28)
            
            HStack(spacing: 16) {
                MainButton(
                    title: "다음에 하기",
                    buttonStyle: .text
                ) {
                    isSubscriptionSheetPresented = false;
                }
                MainButton(title: "구입하기") {
                    Task {
                        await purchaseSelectedSubscription()
                    }
                }
            }
        }
    }
    
    @MainActor
    private func purchaseSelectedSubscription() async {
        
        let product: Product?
        
        switch selectedSubscription {
        case .monthly:
            product = store.products.first {
                $0.subscription?.subscriptionPeriod.unit == .month
            }
            
        case .yearly:
            product = store.products.first {
                $0.subscription?.subscriptionPeriod.unit == .year
            }
        }
        
        guard let product else {
            print("선택된 구독 상품 없음")
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

