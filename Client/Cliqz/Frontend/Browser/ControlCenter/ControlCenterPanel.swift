//
//  ControlCenterPanel.swift
//  Client
//
//  Created by Mahmoud Adam on 12/28/16.
//  Copyright © 2016 CLIQZ. All rights reserved.
//

import UIKit

protocol ControlCenterPanelDelegate: class {
    
    func closeControlCenter()
    
}

class ControlCenterPanel: UIViewController {
    //MARK: - Constants
    let enabledColor = UIColor(rgb: 0x2EBA85)
    let partiallyDisabledColor = UIColor(rgb: 0xFF7F00)
    let disabledColor = UIColor(rgb: 0x858585)
    
    //MARK: - Instance variables
    let trackedWebViewID: Int!
    let isPrivateMode: Bool!
    let currentURL: NSURL!

    weak var delegate: BrowserNavigationDelegate? = nil
    weak var controlCenterPanelDelegate: ControlCenterPanelDelegate? = nil
    
    
    //MARK: Views
    let titleLabel = UILabel()
    let panelIcon = UIImageView()
    let subtitleLabel = UILabel()
    let learnMoreButton = UIButton(type: .Custom)
    let okButton = UIButton(type: .Custom)
    let activateButton = UIButton(type: .Custom)
    
    //MARK: - Init
    init(webViewID: Int, url: NSURL, privateMode: Bool = false) {
        trackedWebViewID = webViewID
        isPrivateMode = privateMode
        currentURL = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // panel title
        titleLabel.font = UIFont.systemFontOfSize(22)
        titleLabel.textAlignment = .Center
        self.view.addSubview(titleLabel)
        
        // panel icon
        if let icon = getPanelIcon() {
            panelIcon.image = icon.imageWithRenderingMode(.AlwaysTemplate)
        }
        self.view.addSubview(panelIcon)
        
        // panel subtitle
        subtitleLabel.font = UIFont.boldSystemFontOfSize(16)
        subtitleLabel.textAlignment = .Center
        self.view.addSubview(subtitleLabel)
        
        
        // learn more label
        let learnMoreTitle = NSLocalizedString("Learn more", tableName: "Cliqz", comment: "Learn more label on control center panel.")
        let underlineTitle = NSAttributedString(string: learnMoreTitle, attributes: [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue])
        learnMoreButton.setAttributedTitle(underlineTitle, forState: .Normal)
        learnMoreButton.titleLabel?.font = UIFont.systemFontOfSize(12)
        learnMoreButton.setTitleColor(textColor(), forState: .Normal)
        learnMoreButton.addTarget(self, action: #selector(learnMorePressed), forControlEvents: .TouchUpInside)
        self.view.addSubview(learnMoreButton)
        
        // Ok button
        
        let okButtonTitle = NSLocalizedString("OK", comment: "Ok button in Control Center panel.")
        self.okButton.setTitle(okButtonTitle, forState: .Normal)
        self.okButton.setTitleColor(UIConstants.CliqzThemeColor, forState: .Normal)
        self.okButton.titleLabel?.font = UIFont.boldSystemFontOfSize(14)
        self.okButton.layer.borderColor = UIConstants.CliqzThemeColor.CGColor
        self.okButton.layer.borderWidth = 2.0
        self.okButton.layer.cornerRadius = 20
        self.okButton.backgroundColor = UIColor.clearColor()
        self.okButton.addTarget(self, action: #selector(dismissView), forControlEvents: .TouchUpInside)
        self.view.addSubview(self.okButton)
        
        
        let activateButtonTitle = NSLocalizedString("Activate", comment: "Activate button in control center panel.")
        self.activateButton.setTitle(activateButtonTitle, forState: .Normal)
        self.activateButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        self.activateButton.titleLabel?.font = UIFont.boldSystemFontOfSize(14)
        self.activateButton.backgroundColor = UIColor(rgb: 0x4CBB17)
        self.activateButton.layer.cornerRadius = 10
        self.activateButton.addTarget(self, action: #selector(enableFeature), forControlEvents: .TouchUpInside)
        self.view.addSubview(self.activateButton)
        
        updateView()
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.setupConstraints()
    }
    
    func setupConstraints() {
        titleLabel.snp_makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.view).offset(15)
            make.height.equalTo(24)
        }
        
        panelIcon.snp_makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(titleLabel.snp_bottom).offset(20)
        }
        
        subtitleLabel.snp_makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.height.equalTo(20)
        }
        
        learnMoreButton.snp_makeConstraints { make in
            make.right.bottom.equalTo(self.view).offset(-25)
            make.height.equalTo(24)
        }
        
        okButton.snp_makeConstraints { (make) in
            make.size.equalTo(CGSizeMake(80, 40))
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-20)
        }
        
        activateButton.snp_makeConstraints { (make) in
            make.size.equalTo(okButton)
            make.centerX.bottom.equalTo(okButton)
        }
        
    }
    
    //MARK: - Abstract methods
    func getPanelTitle() -> String {
        return ""
    }
    
    func getPanelSubTitle() -> String {
        return ""
    }
    
    func getPanelIcon() -> UIImage? {
        return nil
    }
    
    func getLearnMoreURL() -> NSURL? {
        return nil
    }
    
    func isFeatureEnabled() -> Bool {
        return true
    }
    
    func enableFeature() {
        closePanel()
    }
    
    func isFeatureEnabledForCurrentWebsite() -> Bool {
        return true
    }
    
    func updateView() {
        titleLabel.text = getPanelTitle()
        titleLabel.textColor = getThemeColor()
        
        subtitleLabel.text = getPanelSubTitle()
        subtitleLabel.textColor = getThemeColor()
        
        panelIcon.tintColor = getThemeColor()
        
        if isFeatureEnabled() {
            okButton.hidden = false
            activateButton.hidden = true  
        } else {
            okButton.hidden = true
            activateButton.hidden = false
        }
        
    }
    
    //MARK: - Helper methods
    func closePanel() {
        self.controlCenterPanelDelegate?.closeControlCenter()
    }
    
    func getThemeColor() -> UIColor {
        if isFeatureEnabled() {
            if isFeatureEnabledForCurrentWebsite() {
                return enabledColor
            } else {
                return partiallyDisabledColor
            }
        } else {
            return disabledColor
        }
    }
    
    func textColor() -> UIColor {
        if self.isPrivateMode == true {
            return UIConstants.PrivateModeTextColor
        }
        return UIConstants.NormalModeTextColor
    }
    
    func backgroundColor() -> UIColor {
        if self.isPrivateMode == true {
            return UIColor(rgb: 0xFFFFFF)
        }
        return UIColor(rgb: 0xE8E8E8)
    }
    
    @objc private func learnMorePressed() {
        let url = getLearnMoreURL()
        if let u = url {
            self.delegate?.navigateToURLInNewTab(u)
            closePanel()
        }
    }
    
    @objc private func dismissView() {
        closePanel()
    }
    
    
}
