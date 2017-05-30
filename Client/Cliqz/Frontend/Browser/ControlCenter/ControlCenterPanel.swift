//
//  ControlCenterPanel.swift
//  Client
//
//  Created by Mahmoud Adam on 12/28/16.
//  Copyright © 2016 CLIQZ. All rights reserved.
//

import UIKit

class ControlCenterPanel: UIViewController {
    //MARK: - Constants
    let enabledColor = UIColor(rgb: 0x2EBA85)
    let partiallyDisabledColor = UIColor(rgb: 0xF5C03E)
    let disabledColor = UIColor(rgb: 0x858585)
    
    //MARK: - Instance variables
    let trackedWebViewID: Int!
    let isPrivateMode: Bool!
    let currentURL: URL!
    var openTime = Date.getCurrentMillis()
    var isAdditionalInfoVisible = false

    weak var delegate: BrowserNavigationDelegate? = nil
    weak var controlCenterPanelDelegate: ControlCenterPanelDelegate? = nil
    
    
    //MARK: Views
    let titleLabel = UILabel()
    let panelIcon = UIImageView()
    let subtitleLabel = UILabel()
    let learnMoreButton = UIButton(type: .custom)
    let okButton = UIButton(type: .custom)
    let activateButton = UIButton(type: .custom)
    
    //MARK: - Init
    init(webViewID: Int, url: URL, privateMode: Bool = false) {
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
        
        let panelLayout = OrientationUtil.controlPanelLayout()
        
        // panel title
        titleLabel.font = UIFont.systemFont(ofSize: 22)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.6
        
        titleLabel.textAlignment = .center
        self.view.addSubview(titleLabel)
        
        // panel icon
        if let icon = getPanelIcon() {
            panelIcon.image = icon.withRenderingMode(.alwaysTemplate)
        }
        self.view.addSubview(panelIcon)
        
        // panel subtitle
        if panelLayout == .portrait {
            subtitleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        }
        else if panelLayout == .landscapeCompactSize{
            subtitleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        }
        else{
            subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        }
        
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.numberOfLines = 1
        subtitleLabel.minimumScaleFactor = 0.6
        
        subtitleLabel.textAlignment = .center
        self.view.addSubview(subtitleLabel)
        
        
        // learn more label
        let learnMoreTitle = NSLocalizedString("Learn more", tableName: "Cliqz", comment: "Learn more label on control center panel.")
        var underlineTitle = NSAttributedString(string: learnMoreTitle, attributes: [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue])
        
        if panelLayout != .landscapeRegularSize {
            if let privateMode = self.isPrivateMode, privateMode == true {
                underlineTitle = NSAttributedString(string: learnMoreTitle, attributes: [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue, NSForegroundColorAttributeName: UIColor.white])
            }
            learnMoreButton.setAttributedTitle(underlineTitle, for: UIControlState())
            learnMoreButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            learnMoreButton.setTitleColor(textColor(), for: UIControlState())
            
        }
        else
        {
            learnMoreButton.setTitle(learnMoreTitle, for: UIControlState())
            learnMoreButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            learnMoreButton.setTitleColor(UIConstants.CliqzThemeColor, for: .normal)
            learnMoreButton.backgroundColor  = UIColor.clear
        }
        
        learnMoreButton.addTarget(self, action: #selector(learnMorePressed), for: .touchUpInside)
        self.view.addSubview(learnMoreButton)
        
        // Ok button
        
        let okButtonTitle = NSLocalizedString("OK", tableName: "Cliqz", comment: "Ok button in Control Center panel.")
        self.okButton.setTitle(okButtonTitle, for: UIControlState())
        self.okButton.setTitleColor(UIConstants.CliqzThemeColor, for: .normal)
        
        if panelLayout != .landscapeRegularSize{
            self.okButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            self.okButton.layer.borderColor = UIConstants.CliqzThemeColor.cgColor
            self.okButton.layer.borderWidth = 2.0
            self.okButton.layer.cornerRadius = 20
        }
        else{
            self.okButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        }
        
        self.okButton.backgroundColor = UIColor.clear
        self.okButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        self.view.addSubview(self.okButton)
        
        
        let activateButtonTitle = NSLocalizedString("Activate", tableName: "Cliqz", comment: "Activate button in control center panel.")
        self.activateButton.setTitle(activateButtonTitle, for: UIControlState())
        self.activateButton.setTitleColor(UIColor.white, for: UIControlState())
        self.activateButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        self.activateButton.backgroundColor = UIColor(rgb: 0x4CBB17)
        self.activateButton.layer.cornerRadius = 10
        self.activateButton.addTarget(self, action: #selector(enableFeature), for: .touchUpInside)
        self.activateButton.contentEdgeInsets = UIEdgeInsetsMake(6, 4, 6, 4)
        self.view.addSubview(self.activateButton)
        
        updateView()
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        openTime = Date.getCurrentMillis()
        logTelemetrySignal("show", target: nil, customData: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let duration = Int(Date.getCurrentMillis() - openTime)
        logTelemetrySignal("hide", target: nil, customData: ["show_duration": duration])
    }
    func setupConstraints() {
        
        let panelLayout = OrientationUtil.controlPanelLayout()
        
        if panelLayout == .portrait {
            
            titleLabel.snp_makeConstraints { make in
                make.left.right.equalTo(self.view)
                make.top.equalTo(self.view).offset(15)
                make.height.equalTo(24)
            }
            
            panelIcon.snp_makeConstraints { make in
                make.centerX.equalTo(self.view)
				make.height.equalTo(75)
				make.width.equalTo(65)
                make.top.equalTo(titleLabel.snp_bottom).offset(20)
            }
            
            subtitleLabel.snp.makeConstraints({ (make) in
				make.top.equalTo(panelIcon.snp.bottom)
				make.left.equalTo(self.view).offset(20)
				make.width.equalTo(self.view.frame.width - 40)
				make.height.equalTo(20)
			})

            learnMoreButton.snp_makeConstraints { make in
                make.right.bottom.equalTo(self.view).offset(-25)
                make.height.equalTo(24)
            }
            
            okButton.snp_makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 80, height: 40))
                make.centerX.equalTo(self.view)
                make.bottom.equalTo(self.view).offset(-20)
            }
            
            activateButton.snp_makeConstraints { (make) in
                make.size.equalTo(okButton)
                make.centerX.bottom.equalTo(okButton)
            }
            
        }
        else if panelLayout == .landscapeCompactSize{
            
            titleLabel.snp_makeConstraints { make in
                make.left.equalTo(self.view).offset(20)
                make.width.equalTo(self.view.bounds.width/2 - 40)
                make.top.equalTo(self.view).offset(4)
                make.height.equalTo(24)
            }
            
            panelIcon.snp_makeConstraints { make in
                make.centerX.equalTo(titleLabel)
                make.top.equalTo(titleLabel.snp_bottom).offset(16)
            }
            
			subtitleLabel.snp.makeConstraints({ (make) in
				make.top.equalTo(0)
                make.left.equalTo(titleLabel)
                make.width.equalTo(titleLabel)
                make.height.equalTo(20)
                
            })

            learnMoreButton.snp_makeConstraints { make in
                make.right.bottom.equalTo(self.view).offset(-16)
                make.height.equalTo(24)
            }
            
            okButton.snp_makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 80, height: 40))
                //make.centerX.equalTo(self.view)
                make.bottom.equalTo(self.view).offset(-12)
            }
            
            activateButton.snp_makeConstraints { (make) in
                make.size.equalTo(okButton)
                make.centerX.bottom.equalTo(okButton)
            }
        }
        else{
            
            titleLabel.snp_makeConstraints { make in
                make.left.right.equalTo(self.view)
                make.top.equalTo(self.view).offset(0)
                make.height.equalTo(24)
            }
            
            panelIcon.snp_makeConstraints { make in
                make.width.height.equalTo(44)
                make.centerX.equalTo(self.view)
                make.top.equalTo(titleLabel.snp_bottom).offset(12)
            }
            
            subtitleLabel.snp_makeConstraints { make in
				make.top.equalTo(0)
                make.left.right.equalTo(self.view)
                make.height.equalTo(24)
            }
            
            learnMoreButton.snp_makeConstraints { make in
                make.left.equalTo(self.view).offset(12)
                make.bottom.equalTo(self.view).offset(-2)
            }
            
            okButton.snp_makeConstraints { (make) in
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.view).offset(-2)
            }
            
            activateButton.snp_makeConstraints { (make) in
                //make.height.equalTo(30)
                make.bottom.equalTo(self.view).inset(6)
                make.right.equalTo(self.view).inset(4)
            }
            
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
    
    func getLearnMoreURL() -> URL? {
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
            okButton.isHidden = false
            activateButton.isHidden = true
        } else {
            okButton.isHidden = true
            activateButton.isHidden = false
        }
        
    }
    
    func getViewName() -> String {
        return ""
    }
    
    func getAdditionalInfoName() -> String {
        return ""
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
    
    @objc fileprivate func learnMorePressed() {
        
        let url = getLearnMoreURL()
        if let u = url {
            logTelemetrySignal("click", target: "learn_more", customData: nil)
            self.delegate?.navigateToURLInNewTab(u)
            closePanel()
        }
    }
    
    @objc fileprivate func dismissView() {
        closePanel()
        logTelemetrySignal("click", target: "ok", customData: nil)
    }
    func logDomainSwitchTelemetrySignal() {
        let state = isFeatureEnabledForCurrentWebsite() ? "on" : "off"
        logTelemetrySignal("click", target: "domain_switch", customData: ["state": state as AnyObject])
    }
    func logTelemetrySignal(_ action: String, target: String?, customData: [String: Any]?) {
        var viewName = getViewName()
        if "info_company" == target && isAdditionalInfoVisible {
            viewName = getAdditionalInfoName()
        }
        
        TelemetryLogger.sharedInstance.logEvent(.ControlCenter(action, viewName, target, customData))
    }
    
}
