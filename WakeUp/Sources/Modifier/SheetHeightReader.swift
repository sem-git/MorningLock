//
//  SheetHeightReader.swift
//  WakeUp
//
//  Created by 이세민 on 1/30/26.
//

import SwiftUI

struct SheetHeightReader: ViewModifier {
    @Binding var height: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: InnerHeightPreferenceKey.self, value: geo.size.height)
                }
            )
            .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                height = newHeight
            }
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func trackSheetHeight(_ height: Binding<CGFloat>) -> some View {
        modifier(SheetHeightReader(height: height))
    }
}
