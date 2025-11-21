//
//  DeviceReport.swift
//  DeviceReport
//
//  Created by 이세민 on 11/21/25.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct DeviceReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        BarChartReport { appReports in
            BarChartView(appReports: appReports)
        }
    }
}
