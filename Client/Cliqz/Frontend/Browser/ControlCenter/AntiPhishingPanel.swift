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
    fileprivate let descriptionLabel = UILabel()
 
    //MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // panel title
        descriptionLabel.text = NSLocalizedString("Anti-Phishing technology identifies and blocks potentially deceptive websites that try to get your password or account data before you visit the site.", tableName: "Cliqz", comment: "Anti-Phishing panel description")
        descriptionLabel.textColor = textColor()
        descriptionLabel.font = UIFont.systemFont(ofSize: 15)
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
    
    
    override func getLearnMoreURL() -> URL? {
        return URL(string: "https://cliqz.com/whycliqz/anti-phishing")
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        let panelLayout = OrientationUtil.controlPanelLayout()
        
        if panelLayout == .portrait {
			panelIcon.snp.updateConstraints { (make) in
				make.height.equalTo(70)
				make.width.equalTo(70 * 0.72)
			}
			
            subtitleLabel.snp.updateConstraints({ (make) in
				make.top.equalTo(panelIcon.snp.bottom).offset(20)
			})
            
			
            descriptionLabel.snp.remakeConstraints { make in
                make.left.equalTo(self.view).offset(30)
                make.right.equalTo(self.view).offset(-30)
                make.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            }
        }
        else if panelLayout == .landscapeCompactSize {
                       
            subtitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(panelIcon.snp.bottom).offset(20)
                make.left.equalTo(self.view.bounds.width/2).offset(20)
            }
            
            panelIcon.snp.remakeConstraints { (make) in
                make.top.equalTo(titleLabel.snp.bottom).offset(20)
                make.centerX.equalTo(titleLabel)
                make.height.equalTo(70)
                make.width.equalTo(70 * 0.72)
            }
            
            descriptionLabel.snp.remakeConstraints { make in
                make.left.equalTo(self.view.bounds.width/2 + 20)
                make.width.equalTo(self.view.bounds.width/2 - 40)
                make.top.equalTo(self.view).offset(25)
            }
            
            okButton.snp.remakeConstraints { (make) in
                make.size.equalTo(CGSize(width: 80, height: 40))
                make.bottom.equalTo(self.view).offset(-12)
                make.centerX.equalTo(descriptionLabel)
            }
            
        }
        else{
            subtitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(panelIcon.snp.bottom).offset(25)
                make.left.equalTo(self.view).offset(20)
                make.width.equalTo(self.view.frame.width - 40)
                make.height.equalTo(20)
            }
            
            panelIcon.snp.updateConstraints { (make) in
                make.height.equalTo(44)
                make.width.equalTo(44 * 0.72)
            }
            
            descriptionLabel.snp.remakeConstraints { make in
                make.left.equalTo(self.view).offset(30)
                make.right.equalTo(self.view).offset(-30)
                make.top.equalTo(subtitleLabel.snp.bottom).offset(15)
            }
        }

    }
    
    override func isFeatureEnabledForCurrentWebsite() -> Bool {
        return !AntiPhishingDetector.isDetectedPhishingURL(self.currentURL)
    }
    
    override func getViewName() -> String {
        return "atphish"
    }
    
    

}
