//
//  AppRecommendationView.swift
//  WakeUp
//
//  Created by a on 11/14/25.
//

import FamilyControls
import SwiftUI
import DeviceActivity
import ManagedSettings
import ExtensionKit

extension DeviceActivityFilter.SegmentInterval {
    static let today: Self = .daily(during: DateInterval(start: Calendar.current.startOfDay(for: Date()), end: .now))
    static let thisWeek: Self = .weekly(during: Calendar.current.dateInterval(of: .weekOfYear, for: .now)!)
}

struct AppRecommendationView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    @State private var apps: [AppItem] = [
        AppItem(name: "카카오톡"),
        AppItem(name: "인스타그램"),
        AppItem(name: "유튜브"),
        AppItem(name: "네이버"),
        AppItem(name: "틱톡")
    ]
    
    @State private var filter = DeviceActivityFilter(
        segment: .today,
        users: .all,
        devices: .init([.iPhone])
    )
    
    private var isAllSelected: Bool {
        apps.allSatisfy { $0.isSelected }
    }
    
    private var isAddButtonDisabled: Bool {
        !apps.contains(where: { $0.isSelected })
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("많이 쓰는 앱을 모아봤어요")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.gray50)
                .padding(.top, 48)
            
            Text("이 중에 아침에 잠그고 싶은 앱이 있다면 추가해주세요")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.gray200)
                .padding(.top, 12)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 8){
                Spacer()
                
                Button {
                    let newValue = !isAllSelected
                    for index in apps.indices {
                        apps[index].isSelected = newValue
                    }
                } label: {
                    Image(.check)
                        .renderingMode(.template)
                        .foregroundColor(isAllSelected ? .gray50 : .gray300)
                    
                    Text("전체 선택")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isAllSelected ? .gray50 : .gray400)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            DeviceActivityReport(.barChart, filter: filter)
                .onAppear {
                    print("DeviceActivityReport appeared")
                }
            
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach($apps) { $app in
                        AppSelectionItem(appName: app.name, isSelected: $app.isSelected)
                    }
                }
            }
            
            HStack(spacing: 16) {
                MainButton(
                    title: "건너뛰기",
                    buttonStyle: .text
                )
                
                MainButton(
                    title: "추가하기",
                    disabled: isAddButtonDisabled
                ) {
                    viewModel.isOnboarding = false
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 16)
        .background(.gray800)
    }
}

#Preview {
    AppRecommendationView()
}
