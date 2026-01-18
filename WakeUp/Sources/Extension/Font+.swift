//
//  Font+.swift
//  WakeUp
//
//  Created by 이세민 on 1/18/26.
//

import SwiftUI

extension Font {
    static func systemFont(size: CGFloat, weight: Font.Weight) -> Font {
        return .system(size: size, weight: weight)
    }

    static let bold48 = Font.systemFont(size: 48, weight: .bold)
    static let bold40 = Font.systemFont(size: 40, weight: .bold)
    static let bold22 = Font.systemFont(size: 22, weight: .bold)
    static let bold20 = Font.systemFont(size: 20, weight: .bold)
    static let bold16 = Font.systemFont(size: 16, weight: .bold)
    
    static let heavy17 = Font.systemFont(size: 17, weight: .heavy)
    
    static let semiBold20 = Font.systemFont(size: 20, weight: .semibold)
    static let semiBold17 = Font.systemFont(size: 17, weight: .semibold)
    static let semiBold16 = Font.systemFont(size: 16, weight: .semibold)
    
    static let medium14 = Font.systemFont(size: 14, weight: .medium)
    
    static let regular20 = Font.systemFont(size: 20, weight: .regular)
    static let regular15 = Font.systemFont(size: 15, weight: .regular)
    static let regular13 = Font.systemFont(size: 13, weight: .regular)
    static let regular12 = Font.systemFont(size: 12, weight: .regular)
}
