//
//  DeviceActivityResults+.swift
//  WakeUp
//
//  Created by 이세민 on 11/21/25.
//

import SwiftUI
import DeviceActivity
import ManagedSettings

extension DeviceActivityResults where Element ==  DeviceActivityData {
    func makeReport() async -> [AppReport] {
        var appReports: [AppReport] = []
        
        for await value in self {
            for await activity in value.activitySegments {
                for await categorie in activity.categories {
                    for await application in categorie.applications {
                        appReports.append(AppReport(appName: application.application.localizedDisplayName!, usage: application.totalActivityDuration))
                    }
                }
            }
        }
        return appReports
    }
}
