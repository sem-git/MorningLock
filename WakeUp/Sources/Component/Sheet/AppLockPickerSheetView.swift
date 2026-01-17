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
        FamilyActivityPicker(selection: $selection)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("SelectApps", comment: "앱 선택"))
                        .font(.system(size: 20, weight: .bold))
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Complete", comment: "완료")) {
                        onComplete()
                    }
                    .disabled(!canSave)
                }
            }
    }
}
