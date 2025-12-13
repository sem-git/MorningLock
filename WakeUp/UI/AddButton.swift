//
//  AddButton.swift
//  WakeUp
//
//  Created by a on 10/13/25.
//

import SwiftUI

struct AddButton: View {
    var action: (() -> ())?
    
    var body: some View {
        Menu {
            Button {
                action?()
            } label: {
                Label("알람 추가", systemImage: "clock")
            }
        } label: {
            Circle()
                .frame(width: 64, height: 64)
                .foregroundStyle(.gray600)
                .overlay(Image(.icPlus))
        }
    }
}

#Preview {
    AddButton()
}
