//
//  AntiPhishingPanel.swift
//  Client
//
//  Created by Mahmoud Adam on 12/29/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class AntiPhishingPanel: ControlCenterPanel {
    
    //MARK: - Instance variables
    
    //MARK: Views
    private let descriptionLabel = UILabel()
 
    //MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // panel title
        descriptionLabel.text = NSLocalizedString("Anti-Phishing technology identifies and blocks potentially deceptive websites that try to get your password or account data before you visit the site.", tableName: "Cliqz", comment: "Anti-Phishing panel description")
        descriptionLabel.textColor = textColor()
        descriptionLabel.font = UIFont.systemFontOfSize(15)
        descriptionLabel.numberOfLines = 0
        self.view.addSubview(descriptionLabel)

    }

    //MARK: - Abstract methods implementation
    override func getPanelTitle() -> String {
        if isFeatureEnabledForCurrentWebsite() {
            return NSLocalizedString("You are safe", tableName: "Cliqz", comment: "Anti-Phishing panel title in the control center if the current website is safe.")
        } else {
            return NSLocalizedString("Your data is not protected", tableName: "Cliqz", comment: "Anti-Phishing panel title in the control center if the current website is a phishing one.")
        }
    }
    
    override func getPanelSubTitle() -> String {
        if isFeatureEnabledForCurrentWebsite() {
            return NSLocalizedString("No suspicious activities detected", tableName: "Cliqz", comment: "Anti-Phishing panel subtitle in the control center if the current website is safe.")
        } else {
            return NSLocalizedString("Suspicious activities were detected", tableName: "Cliqz", comment: "Anti-Phishing panel subtitle in the control center if the current website is a phishing one.")
        }
    }
    
    override func getPanelIcon() -> UIImage? {
        return UIImage(named: "hookIcon")
    }
    
    
    override func getLearnMoreURL() -> NSURL? {
        return NSURL(string: "https://cliqz.com/whycliqz/anti-phishing")
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        subtitleLabel.snp_updateConstraints { make in
            make.top.equalTo(panelIcon.snp_bottom).offset(25)
        }
        descriptionLabel.snp_makeConstraints { make in
            make.left.equalTo(self.view).offset(30)
            make.right.equalTo(self.view).offset(-30)
            make.top.equalTo(subtitleLabel.snp_bottom).offset(25)
        }

    }
    
    override func isFeatureEnabledForCurrentWebsite() -> Bool {
        return !AntiPhishingDetector.isDetectedPhishingURL(self.currentURL)
    }

}
