//
//  TimerView.swift
//  WakeUp
//
//  Created by a on 12/9/25.
//

import SwiftUI

struct TimerView: View {
    var body: some View {
        ZStack {
            Color.gray800.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                Text("아침 준비를 기다리는 중이에요")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.gray50)
                    .padding(.top, 48)
                
                Text("오늘의 시작에 집중해볼까요?")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.gray200)
                    .padding(.top, 12)
                
                RoundProgressView(
                    width: 280,
                    height: 280,
                    color1: .gray400,
                    color2: .gray50,
                    percent: .constant(10)
                )
                .overlay(
                    Text("03:45")
                        .foregroundStyle(.gray50)
                        .font(.system(size: 40, weight: .bold))
                )
                .padding(.top, 137)
                Spacer()
            }
        }
    }
}

struct RoundProgressView : View {
    var width: CGFloat
    var height: CGFloat
    var color1: Color
    var color2: Color
    @Binding var percent: Int;
    
    var body: some View {
        
        let multiplier = width / 40
        
        let progress = 1 - (CGFloat(percent) / 100)
        
        return ZStack {
            
            Circle()
                .stroke(Color.black.opacity(0.1), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .frame(width: width, height: height)
            
            Circle()
                .trim(from: progress, to: 1)
            
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color1, color2]), startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .frame(width: width, height: height)
            
                .rotationEffect(Angle(degrees: 90))
                .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
                .shadow(color: color2, radius: 14 * multiplier, x: 0.0, y: 14 * multiplier)
        }
    }
}


#Preview {
    TimerView()
}
