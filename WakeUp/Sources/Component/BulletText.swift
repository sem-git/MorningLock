//
//  BulletText.swift
//  WakeUp
//
//  Created by 이세민 on 12/26/25.
//

import SwiftUI

struct BulletText: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.system(size: 12))
                .foregroundStyle(.gray200)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.gray200)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
