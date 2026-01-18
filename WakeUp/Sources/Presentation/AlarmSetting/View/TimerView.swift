//
//  TimerView.swift
//  WakeUp
//
//  Created by a on 12/9/25.
//

import SwiftUI

struct TimerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var nativeViewModel = NativeAdViewModel()
    
    @StateObject var deviceManager = DeviceActivityManager.shared
    @StateObject private var store = StoreKitManager.shared
    
    var body: some View {
        ZStack {
            Color.gray800.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(.icX)
                    }
                    .padding()
                }
                
                Text("아침 준비를 기다리는 중이에요")
                    .bold22()
                    .padding(.top, 48)
                
                Text("오늘의 시작에 집중해볼까요?")
                    .semiBold17(color: .gray200)
                    .padding(.top, 12)
                
                RoundProgressView(
                    width: 280,
                    height: 280,
                    color1: .gray50,
                    color2: .gray50,
                    percent: $deviceManager.percent
                )
                .overlay(
                    Text(deviceManager.remainingTime.formatToHourMinute)
                        .bold40()
                )
                .padding(.top, 137)
                
                Spacer()
                
                NativeAdMobView(nativeViewModel: nativeViewModel)
                    .frame(maxHeight: 64)
                    .padding(.horizontal, 16)
            }
        }
        .onAppear {
            deviceManager.startLockTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                deviceManager.startLockTimer()
            case .background:
                deviceManager.stopLockTimer()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
        .onChange(of: deviceManager.remainingTime) { _, remainingTime in
            if remainingTime <= 0 {
                deviceManager.stopLockTimer()
                dismiss()
            }
        }
        .onReceive(store.$subscriptionStatus, perform: { subscriptionStatus in
            if subscriptionStatus == .notSubscribed {
                nativeViewModel.loadAd()
            }
        })
    }
}

struct RoundProgressView : View {
    var width: CGFloat
    var height: CGFloat
    var color1: Color
    var color2: Color
    
    @Binding var percent: Double;
    
    var body: some View {
        let progress = 1 - (CGFloat(percent) / 100)
        
        return ZStack {
            Circle()
                .stroke(.gray600, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .frame(width: width, height: height)
            
            Circle()
                .trim(from: progress, to: 1)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color1, color2]), startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .frame(width: width, height: height)
                .animation(.default, value: progress)
                .rotationEffect(Angle(degrees: 90))
                .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
        }
    }
}


#Preview {
    TimerView()
}
