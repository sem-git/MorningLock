//
//  Top5ReportView.swift
//  WakeUp
//
//  Created by 이세민 on 11/21/25.
//

import SwiftUI

struct Top5ReportView: View {
    let appReports: [AppReport]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(appReports.prefix(5), id: \.appName) { report in
                    Text(report.appName)
                        .foregroundColor(.white)
                }
            }
        }
    }
}
