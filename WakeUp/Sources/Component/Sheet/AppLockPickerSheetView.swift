//
//  AppLockPickerSheetView.swift
//  WakeUp
//
//  Created by 이세민 on 1/17/26.
//

import SwiftUI
import FamilyControls

struct AppLockPickerSheetView: View {
    @Binding var selection: FamilyActivitySelection
    @Binding var canSave: Bool
    
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("앱을 20개 이하로 선택해주세요 ( \(selection.applicationTokens.count) / 20 )")
                .font(.medium14)
                .foregroundStyle(selection.applicationTokens.count > 20 ? .danger : .gray50)
            
            FamilyActivityPicker(selection: $selection)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("잠글 앱 선택")
                            .bold20()
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("완료") {
                            onComplete()
                        }
                        .disabled(!canSave)
                    }
                }
        }
    }
}
