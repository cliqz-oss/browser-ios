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

enum Whitelisted{
    case yes
    case no
    case undefined
}

class CliqzURLBarView: URLBarView {

	private let antitrackingGreenBackgroundColor = UIColor(rgb: 0x2CBA84)
    private let antitrackingOrangeBackgroundColor = UIColor(rgb: 0xF5C03E)
	private let antitrackingButtonSize = CGSizeMake(42, CGFloat(URLBarViewUX.LocationHeight))
	private var trackersCount = 0
    
	private lazy var antitrackingButton: UIButton = {
		let button = UIButton(type: .Custom)
		button.setTitle("0", forState: .Normal)
		button.titleLabel?.font = UIFont.systemFontOfSize(12)
        button.backgroundColor = self.colorForAntiTrackingButtonBackground(Whitelisted.undefined, newURL: nil)
        button.accessibilityLabel = "AntiTrackingButton"
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
		return button
	}()
    private lazy var newTabButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.setImage(UIImage.templateImageNamed("bottomNav-NewTab"), forState: .Normal)
        button.accessibilityLabel = NSLocalizedString("New tab", comment: "Accessibility label for the New tab button in the tab toolbar.")
        button.addTarget(self, action: #selector(CliqzURLBarView.SELdidClickNewTab), forControlEvents: UIControlEvents.TouchUpInside)
        return button
    }()
    
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

	override func updateConstraints() {
		super.updateConstraints()
		if !antitrackingButton.hidden {
            if self.toolbarIsShowing {
                let trailingPadding = antitrackingButtonSize.width + URLBarViewUX.URLBarButtonOffset
                locationContainer.snp_updateConstraints { make in
                    make.trailing.equalTo(shareButton.snp_leading).offset(-trailingPadding)
                }
            } else {
                let trailingPadding = antitrackingButtonSize.width + URLBarViewUX.LocationLeftPadding
                locationContainer.snp_updateConstraints { make in
                    make.trailing.equalTo(self).offset(-trailingPadding)
                }
            }
			
			self.antitrackingButton.snp_updateConstraints(closure: { (make) in
				make.size.equalTo(self.antitrackingButtonSize)
			})
			if self.antitrackingButton.bounds.size != CGSizeZero {
                
			}
		} else {
			self.antitrackingButton.snp_updateConstraints(closure: { (make) in
				make.size.equalTo(CGSizeMake(0, 0))
			})
		}
	}
    
    override func prepareOverlayAnimation() {
        super.prepareOverlayAnimation()
        self.newTabButton.hidden = !self.toolbarIsShowing
    }
    
    override func transitionToOverlay(didCancel: Bool = false) {
        super.transitionToOverlay(didCancel)
        self.newTabButton.alpha = inOverlayMode ? 0 : 1
    }
    override func updateViewsForOverlayModeAndToolbarChanges() {
        super.updateViewsForOverlayModeAndToolbarChanges()
        self.newTabButton.hidden = !self.toolbarIsShowing || inOverlayMode
    }
    
	func updateTrackersCount(count: Int) {
        trackersCount = count
		self.antitrackingButton.setTitle("\(count)", forState: .Normal)
		self.setNeedsDisplay()
	}

	func showAntitrackingButton(hidden: Bool) {
		self.antitrackingButton.hidden = !hidden
		self.setNeedsUpdateConstraints()
	}

	func enableAntitrackingButton(enable: Bool) {
		self.antitrackingButton.enabled = enable
	}
    
    func refreshAntiTrackingButton(notification: NSNotification){
        
        if let userInfo = notification.userInfo{
            
            var whitelisted : Whitelisted = .undefined
            if let onWhiteList = userInfo["whitelisted"] as? Bool{
                whitelisted = onWhiteList ? Whitelisted.yes : Whitelisted.no
            }
            
            var newURL : NSURL? = nil
            if let url = userInfo["newURL"] as? NSURL{
                newURL = url
            }
            
            self.antitrackingButton.backgroundColor = colorForAntiTrackingButtonBackground(whitelisted, newURL: newURL)
        }
        else {
            self.antitrackingButton.backgroundColor = colorForAntiTrackingButtonBackground(Whitelisted.undefined, newURL: nil)
        }

    }
    
    func colorForAntiTrackingButtonBackground(whitelisted: Whitelisted, newURL: NSURL?) -> UIColor{
        
        var theURL : NSURL
        
        if let url = self.currentURL {
            theURL = url
        }
        else if let url = newURL{
            theURL = url
        }
        else{
            return antitrackingGreenBackgroundColor
        }
        
        guard let domain = theURL.host else {return antitrackingGreenBackgroundColor}
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
            return antitrackingGreenBackgroundColor
        }
        
        return antitrackingOrangeBackgroundColor
    }

	private func commonInit() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(refreshAntiTrackingButton) , name: NotificationRefreshAntiTrackingButton, object: nil)
        
		let img = UIImage(named: "shieldButton")
		self.antitrackingButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
		self.antitrackingButton.setImage(img, forState: .Normal)
		self.antitrackingButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 2, bottom: 5, right: 0)
		self.antitrackingButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 5, bottom: 4, right: 20)
		self.antitrackingButton.addTarget(self, action: #selector(antitrackingButtonPressed), forControlEvents: .TouchUpInside)
		self.antitrackingButton.hidden = true
		addSubview(self.antitrackingButton)
		antitrackingButton.snp_makeConstraints { make in
			make.centerY.equalTo(self.locationContainer)
			make.leading.equalTo(self.locationContainer.snp_trailing)
			make.size.equalTo(self.antitrackingButtonSize)
		}
        
        addSubview(newTabButton)
        // Cliqz: Changed new tab position, now it should be befores tabs button
        newTabButton.snp_makeConstraints { make in
            make.right.equalTo(self.tabsButton.snp_left).offset(-URLBarViewUX.URLBarButtonOffset)
            make.centerY.equalTo(self)
            make.size.equalTo(backButton)
        }
        
        // Cliqz: Changed share position, now it should be before new tab button
        shareButton.snp_updateConstraints { make in
            make.right.equalTo(self.newTabButton.snp_left).offset(-URLBarViewUX.URLBarButtonOffset)
        }
        
        self.actionButtons.append(newTabButton)
	}
	
	@objc private func antitrackingButtonPressed(sender: UIButton) {
        let status = antitrackingGreenBackgroundColor == sender.backgroundColor ? "green" : "Orange"
		self.delegate?.urlBarDidClickAntitracking(self, trackersCount: trackersCount, status: status)
	}
    
    
    // Cliqz: Add actions for new tab button
    func SELdidClickNewTab() {
        delegate?.urlBarDidPressNewTab(self, button: newTabButton)
    }
}
