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
            title: .init(text: NSLocalizedString("appLockScreenSubTitle", comment: "잠금화면 타이틀"), color: .white),
            subtitle: .init(text: NSLocalizedString("appLockScreenTitle", comment: "잠금화면 서브타이틀"), color: .gray200),
            primaryButtonLabel: .init(text: NSLocalizedString("remainingTimeButtonText", comment: "잠금화면 서브타이틀"), color: .gray50),
            primaryButtonBackgroundColor: .gray500,
            secondaryButtonLabel: nil
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: .black,
            icon: UIImage(named: ""),
            title: .init(text: NSLocalizedString("appLockScreenSubTitle", comment: "잠금화면 타이틀"), color: .white),
            subtitle: .init(text: NSLocalizedString("appLockScreenTitle", comment: "잠금화면 서브타이틀"), color: .gray200),
            primaryButtonLabel: .init(text: NSLocalizedString("remainingTimeButtonText", comment: "잠금화면 서브타이틀"), color: .gray50),
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
