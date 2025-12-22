//
//  ShieldConfigurationExtension.swift
//  ShieldConfiguration
//
//  Created by 이세민 on 11/28/25.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: .black,
            icon: UIImage(named: ""),
            title: .init(text: "잠금 상태입니다", color: .white),
            subtitle: .init(text: "아침 준비를 기다리는 중이에요\n오늘의 시작에 집중해볼까요?", color: .gray200),
            primaryButtonLabel: .init(text: "남은 시간은?", color: .gray50),
            primaryButtonBackgroundColor: .gray500,
            secondaryButtonLabel: nil
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: .black,
            icon: UIImage(named: ""),
            title: .init(text: "잠금 상태입니다", color: .white),
            subtitle: .init(text: "아침 준비를 기다리는 중이에요\n오늘의 시작에 집중해볼까요?", color: .gray200),
            primaryButtonLabel: .init(text: "남은 시간은?", color: .gray50),
            primaryButtonBackgroundColor: .gray500,
            secondaryButtonLabel: nil
        )
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Customize the shield as needed for web domains.
        ShieldConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for web domains shielded because of their category.
        ShieldConfiguration()
    }
}
