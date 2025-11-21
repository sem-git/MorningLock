//
//  MainButton.swift
//  WakeUp
//
//  Created by a on 10/14/25.
//

import SwiftUI

enum ButtonStyle {
    case `default`
    case text
    
    var backgroundColor: Color {
        switch self {
        case .`default`:
                .gray600
        case .text:
                .clear
        }
    }
    
    func textColor(disabled: Bool) -> Color {
        switch (self, disabled) {
        case (.default, false):
                .gray50
        case (.default, true):
                .gray400
        case (.text, false):
                .gray200
        case (.text, true):
                .gray300
        }
    }
}

struct MainButton: View {
    let title: String
    var disabled: Bool = false
    var buttonStyle: ButtonStyle = .default
    var action: (() -> ())?
    
    var body: some View {
        Button {
            action?()
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(buttonStyle.textColor(disabled: disabled))
                .frame(maxWidth: .infinity, minHeight: 62)
        }
        .disabled(disabled)
        .background(buttonStyle.backgroundColor)
        .cornerRadius(16)
    }
}

#Preview {
    MainButton(title: "완료")
}
