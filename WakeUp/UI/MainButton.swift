//
//  MainButton.swift
//  WakeUp
//
//  Created by a on 10/14/25.
//

import SwiftUI

enum MainButtonStyle {
    case `default`
    case text
    
    func backgroundColor(disabled: Bool) -> Color {
        switch self {
        case .default:
            return disabled ? .gray600 : .gray500
        case .text:
            return .clear
        }
    }
    
    func textColor(disabled: Bool) -> Color {
        switch self {
        case .default:
            return disabled ? .gray400 : .gray50
        case .text:
            return .gray200
        }
    }
}

struct MainButton: View {
    let title: String
    var disabled: Bool = false
    var buttonStyle: MainButtonStyle = .default
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
        .background(buttonStyle.backgroundColor(disabled: disabled))
        .cornerRadius(16)
    }
}

#Preview {
    MainButton(title: "완료")
}
