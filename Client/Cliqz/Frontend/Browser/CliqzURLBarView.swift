//
//  CliqzURLBarView.swift
//  Client
//
//  Created by Sahakyan on 8/25/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit
import SnapKit

class CliqzURLBarView: URLBarView {

	private let antitrackingBackgroundColor = UIColor(rgb: 0x2CBA84)
	private let antitrackingButtonSize = CGSizeMake(42, CGFloat(URLBarViewUX.LocationHeight))
	
	private lazy var antitrackingButton: UIButton = {
		let button = UIButton(type: .Custom)
		button.setTitle("0", forState: .Normal)
		button.titleLabel?.font = UIFont.systemFontOfSize(12)
		button.backgroundColor = self.antitrackingBackgroundColor
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

	override func updateConstraints() {
		super.updateConstraints()
		if !antitrackingButton.hidden {
            if self.toolbarIsShowing {
                locationContainer.snp_updateConstraints { make in
                    let x = -UIConstants.ToolbarHeight
                    make.trailing.equalTo(shareButton.snp_leading).offset(x)
                }
            } else {
                locationContainer.snp_updateConstraints { make in
                    let x = -(UIConstants.ToolbarHeight + 10)
                    make.trailing.equalTo(self).offset(x)
                }
            }
			
			self.antitrackingButton.snp_updateConstraints(closure: { (make) in
				make.size.equalTo(self.antitrackingButtonSize)
			})
			if self.antitrackingButton.backgroundColor != UIColor.clearColor() && self.antitrackingButton.bounds.size != CGSizeZero {
				self.antitrackingButton.addRoundedCorners(cornersToRound: [.TopRight, .BottomRight], cornerRadius: CGSizeMake(URLBarViewUX.TextFieldCornerRadius, URLBarViewUX.TextFieldCornerRadius), color: self.antitrackingBackgroundColor)
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

	private func commonInit() {
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
		self.delegate?.urlBarDidClickAntitracking(self)
	}
    
    
    // Cliqz: Add actions for new tab button
    func SELdidClickNewTab() {
        delegate?.urlBarDidPressNewTab(self, button: newTabButton)
    }
}
