//
//  Top5Report.swift
//  WakeUp
//
//  Created by 이세민 on 11/21/25.
//

import SwiftUI
import DeviceActivity
import ExtensionKit
import ManagedSettings

struct Top5Report: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .top5
    
    let content: ([AppReport]) -> Top5ReportView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> [AppReport] {
        return await data.makeReport()
    }
}
