//
//  CliqzURLBarView.swift
//  Client
//
//  Created by Sahakyan on 8/25/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit
import SnapKit
import Shared
import QuartzCore

enum Whitelisted {
    case yes
    case no
    case undefined
}

class CliqzURLBarView: URLBarView {

	static let antitrackingGreenBackgroundColor = UIColor(rgb: 0x2CBA84)
    static let antitrackingOrangeBackgroundColor = UIColor(rgb: 0xF5C03E)
	static let antitrackingButtonSize = CGSize(width: 42, height: CGFloat(URLBarViewUX.LocationHeight))
	private var trackersCount = 0
    
	fileprivate lazy var antitrackingButton: UIButton = {
		let button = UIButton(type: .custom)
		button.setTitle("0", for: .normal)
		button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.backgroundColor = UIColor.clear
        button.accessibilityLabel = "AntiTrackingButton"
        
        let buttonImage = self.imageForAntiTrackingButton(Whitelisted.undefined)
        button.setImage(buttonImage, for: .normal)
        
        button.titleEdgeInsets = UIEdgeInsets(top: 5, left: 2, bottom: 5, right: 0)
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 2, bottom: 4, right: 20)
        button.addTarget(self, action: #selector(antitrackingButtonPressed), for: .touchUpInside)
        button.isHidden = true
        
		return button
	}()
    fileprivate lazy var newTabButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.templateImageNamed("bottomNav-NewTab"), for: .normal)
        button.accessibilityLabel = NSLocalizedString("New tab", comment: "Accessibility label for the New tab button in the tab toolbar.")
        button.addTarget(self, action: #selector(CliqzURLBarView.SELdidClickNewTab), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    static let antitrackingGreenIcon = UIImage(named: "antitrackingGreen")
    static let antitrackingOrangeIcon = UIImage(named: "antitrackingOrange")
    
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
    
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepareOverlayAnimation() {
        super.prepareOverlayAnimation()
        self.newTabButton.isHidden = !self.toolbarIsShowing
    }
    
    override func transitionToOverlay(didCancel: Bool = false) {
        super.transitionToOverlay(didCancel: didCancel)
        self.newTabButton.alpha = inOverlayMode ? 0 : 1
    }
    override func updateViewsForOverlayModeAndToolbarChanges() {
        super.updateViewsForOverlayModeAndToolbarChanges()
        self.newTabButton.isHidden = !self.toolbarIsShowing || inOverlayMode
    }
    
	func updateTrackersCount(_ count: Int) {
        trackersCount = count
		self.antitrackingButton.setTitle("\(count)", for: UIControlState())
		self.setNeedsDisplay()
	}

	func showAntitrackingButton(_ hidden: Bool) {
//		self.antitrackingButton.isHidden = !hidden
		self.bringSubview(toFront: self.antitrackingButton)
		self.setNeedsUpdateConstraints()
	}
    
    func isAntiTrackingButtonHidden() -> Bool {
        return antitrackingButton.isHidden
    }

	func enableAntitrackingButton(_ enable: Bool) {
//		self.antitrackingButton.isEnabled = enable
	}
    
    func refreshAntiTrackingButton(_ notification: Notification){
        
        if let userInfo = notification.userInfo{
            
            var whitelisted : Whitelisted = .undefined
            if let onWhiteList = userInfo["whitelisted"] as? Bool{
                whitelisted = onWhiteList ? Whitelisted.yes : Whitelisted.no
            }
            
            var newURL : URL? = nil
            if let url = userInfo["newURL"] as? URL{
                newURL = url
            }
            
            let antitrackingImag = self.imageForAntiTrackingButton(whitelisted, newURL: newURL)
            self.antitrackingButton.setImage(antitrackingImag, for: .normal)
        }
        else {
            
            let antitrackingImag = self.imageForAntiTrackingButton(Whitelisted.undefined)
            self.antitrackingButton.setImage(antitrackingImag, for: .normal)
        }

    }
    
    func imageForAntiTrackingButton(_ whitelisted: Whitelisted, newURL: URL? = nil) -> UIImage? {
        
        var theURL : URL
        
        if let url = newURL {
            theURL = url
        }
        else if let url = self.currentURL {
            theURL = url
        }
        else {
            return CliqzURLBarView.antitrackingGreenIcon
        }
        
        guard let domain = theURL.host else {return CliqzURLBarView.antitrackingGreenIcon}
        var isAntiTrackingEnabled = false
        
        //Doc: If the observer checks if the website is whitelisted, it might get the wrong value, since the correct value may not be set yet. 
        //To avoid that whitelisted is sent as an argument, and takes precedence over isDomainWhiteListed.
        if whitelisted != .undefined{
            isAntiTrackingEnabled = whitelisted == .yes ? false : true
        }else{
            isAntiTrackingEnabled = !AntiTrackingModule.sharedInstance.isDomainWhiteListed(domain)
        }
        
        let isWebsiteOnPhisingList = AntiPhishingDetector.isDetectedPhishingURL(theURL)
        
        if isAntiTrackingEnabled && !isWebsiteOnPhisingList{
            return CliqzURLBarView.antitrackingGreenIcon
        }
        
        return CliqzURLBarView.antitrackingOrangeIcon
    }

	fileprivate func commonInit() {
        
        NotificationCenter.default.addObserver(self, selector:#selector(refreshAntiTrackingButton) , name: NSNotification.Name(rawValue: NotificationRefreshAntiTrackingButton), object: nil)
        
		addSubview(self.antitrackingButton)
		antitrackingButton.snp_makeConstraints { make in
			make.centerY.equalTo(self.locationContainer)
			make.leading.equalTo(self.locationContainer.snp_trailing).offset(-1.5 * URLBarViewUX.ButtonWidth)
			make.size.equalTo(CliqzURLBarView.antitrackingButtonSize)
		}
        
        addSubview(newTabButton)
        // Cliqz: Changed new tab position, now it should be befores tabs button
        newTabButton.snp.makeConstraints { make in
            make.right.equalTo(self.tabsButton.snp_left).offset(-URLBarViewUX.URLBarButtonOffset)
            make.centerY.equalTo(self)
            make.size.equalTo(backButton)
        }
        
        // Cliqz: Changed share position, now it should be before new tab button
		shareButton.snp.remakeConstraints { (make) in
			make.right.equalTo(self.newTabButton.snp.left).offset(-URLBarViewUX.URLBarButtonOffset)
			make.centerY.equalTo(self)
			make.size.equalTo(backButton)
		}
		
        self.actionButtons.append(newTabButton)
	}
	
	@objc private func antitrackingButtonPressed(sender: UIButton) {
        let status = CliqzURLBarView.antitrackingGreenBackgroundColor == sender.backgroundColor ? "green" : "Orange"
		self.delegate?.urlBarDidClickAntitracking(self, trackersCount: trackersCount, status: status)
	}
    
    
    // Cliqz: Add actions for new tab button
    func SELdidClickNewTab() {
        delegate?.urlBarDidPressNewTab(self, button: newTabButton)
    }

    override func applyTheme(_ themeName: String) {
        super.applyTheme(themeName)
        
        if let theme = URLBarViewUX.Themes[themeName] {
            self.antitrackingButton.setTitleColor(theme.textColor, for: .normal)
        }
    }

}
