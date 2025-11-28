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
            icon: nil,
            title: .init(text: "아침 준비를 기다리는 중이에요", color: .systemMint),
            subtitle: .init(text: "오늘의 시작에 집중해볼까요?", color: .systemMint),
            primaryButtonLabel: .init(text: "OK", color: .systemMint),
            primaryButtonBackgroundColor: .black,
            secondaryButtonLabel: .init(text: "OK", color: .systemMint)
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: .black,
            icon: nil,
            title: .init(text: "아침 준비를 기다리는 중이에요", color: .systemMint),
            subtitle: .init(text: "오늘의 시작에 집중해볼까요?\(category.localizedDisplayName)", color: .systemMint),
            primaryButtonLabel: .init(text: "OK", color: .systemMint),
            primaryButtonBackgroundColor: .black,
            secondaryButtonLabel: .init(text: "OK", color: .systemMint)
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
