//
//  AlarmSheetView.swift
//  WakeUp
//
//  Created by 이세민 on 1/17/26.
//

import SwiftUI

struct AlarmSheetView: View {
    let snoozeCount: Int
    let snoozeMinutes: Int
    let snoozeDisabled: Bool
    
    let onSnooze: () -> Void
    let onDeactivate: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text(NSLocalizedString("alarmRiningTitle", comment: "알람이 울렸습니다."))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.gray50)
                .padding(.top, 24)
            
            Text(NSLocalizedString("alarmRiningSubTitle", comment: "알람 횟수 표시"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.gray200)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            Text(String(format: NSLocalizedString("alarmRingingCount", comment: "알람 횟수 표시"), snoozeCount))
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.gray200)
            .multilineTextAlignment(.center)
            
            Image(.imgLock)
                .padding(.top, 16)
            
            HStack(spacing: 16) {
                MainButton(
                    title: String(format: NSLocalizedString("snoozeButtonText", comment: "스누즈 버튼"), snoozeMinutes),
                    disabled: snoozeDisabled,
                    buttonStyle: .text
                ) {
                    onSnooze()
                }
                
                MainButton(title: NSLocalizedString("deactiveAlarmText", comment: "알람 끄기")) {
                    onDeactivate()
                }
            }
        }
    }
}
