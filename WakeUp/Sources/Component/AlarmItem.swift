//
//  AlarmItem.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI

struct AlarmItem: View {
    @Binding var alarm: AlarmEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text("\(alarm.meridiem)")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.gray50)
                
                Text("\(alarm.dateString)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.gray50)
                    .fixedSize(horizontal: true, vertical: false)
                
                Spacer()
                
                Toggle("", isOn: Binding(get: {
                    alarm.isActive
                }, set: { isActive in
                    alarm.isActive = isActive
                }))
            }
            
            HStack(spacing: 12) {
                ForEach(Weekday.allCases, id: \.self) {
                    Text($0.dayName)
                        .foregroundStyle(alarm.repeatDay.contains($0) ? .gray50 : .gray300)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(.gray600)
        .cornerRadius(16)
    }
}
