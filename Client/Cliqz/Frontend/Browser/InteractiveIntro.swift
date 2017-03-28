//
//  InteractiveIntro.swift
//  Client
//
//  Created by Sahakyan on 11/11/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import SnapKit

// TODO: Quick implementation should be redesigned and refactored

enum HintType {
	case Antitracking
	case CliqzSearch
	case Unknown
}

class InteractiveIntro {

	var shouldShowAntitrackingHint = true {
		didSet {
			SettingsPrefs.updateShowAntitrackingHintPref(shouldShowAntitrackingHint)
		}
	}
	var shouldShowCliqzSearchHint = true {
		didSet {
			SettingsPrefs.updateShowCliqzSearchHintPref(shouldShowCliqzSearchHint)
		}
	}

	func updateHintPref(type: HintType, value: Bool) {
		switch type {
		case .Antitracking:
			shouldShowAntitrackingHint = value
		case .CliqzSearch:
			shouldShowCliqzSearchHint = value
		default:
			debugPrint("Wront Hint Type")
		}
	}

	static let sharedInstance = InteractiveIntro()
	
	init() {
		shouldShowAntitrackingHint = SettingsPrefs.getShowAntitrackingHintPref()
		shouldShowCliqzSearchHint = SettingsPrefs.getShowCliqzSearchHintPref()
	}
	
	func reset() {
		self.shouldShowAntitrackingHint = true
		self.shouldShowCliqzSearchHint = true
	}
}

class InteractiveIntroViewController: UIViewController {

	private var contentView: UIView? = nil
	private var currentHintType: HintType = .Unknown

	private static let blurryBackgroundViewTag = 1
	private static let titleFontSize: CGFloat = 30.0
	private static let descriptionFontSize: CGFloat = 18.0

	override func shouldAutorotate() -> Bool {
		return false
	}

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.Portrait
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		guard let contentView = self.contentView else {
			return
		}
		let bgView = contentView.viewWithTag(InteractiveIntroViewController.blurryBackgroundViewTag)
		switch self.currentHintType {
		case .Antitracking:
			bgView?.layer.mask = self.antitrackingMaskLayer()
		case .CliqzSearch:
			bgView?.layer.mask = self.cliqzSearchMaskLayer()
		default:
			debugPrint("Wrong Type")
		}
	}

	func showHint(type: HintType) {
		self.currentHintType = type
		switch type {
		case .Antitracking:
			showAntitrackingHint()
		case .CliqzSearch:
			showCliqzSearchHint()
		default:
			debugPrint("Wrong type")
		}
	}

	private func showCliqzSearchHint() {
		contentView = UIView()
		self.contentView!.backgroundColor = UIColor.clearColor()
		self.view.addSubview(self.contentView!)
		
		let blurrySemiTransparentView = UIView(frame:self.view.bounds)
		blurrySemiTransparentView.backgroundColor = UIColor(rgb: 0x2d3e50).colorWithAlphaComponent(0.9)
		self.contentView!.addSubview(blurrySemiTransparentView)
		blurrySemiTransparentView.tag = InteractiveIntroViewController.blurryBackgroundViewTag
		blurrySemiTransparentView.layer.mask = self.cliqzSearchMaskLayer()

		let title = UILabel()
		title.text = NSLocalizedString("Fast-search", tableName: "Cliqz", comment: "Cliqz search hint title")
		title.font = UIFont.systemFontOfSize(InteractiveIntroViewController.titleFontSize)
		title.textColor = UIColor.whiteColor()
		self.contentView!.addSubview(title)
		let description = UILabel()
		self.contentView!.addSubview(description)
		description.text = NSLocalizedString("Fast-search description", tableName: "Cliqz", comment: "Cliqz search hint description")
		description.textColor = UIColor.whiteColor()
		description.font = UIFont.systemFontOfSize(InteractiveIntroViewController.descriptionFontSize)
		description.numberOfLines = 0
		let button = UIButton()
		button.setTitle("OK", forState: .Normal)
		button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
		button.layer.borderColor = UIColor.whiteColor().CGColor
		button.layer.borderWidth = 2
		button.layer.cornerRadius = 6
		button.backgroundColor = UIColor.clearColor()
		button.addTarget(self, action: #selector(closeHint), forControlEvents: .TouchUpInside)
		self.contentView!.addSubview(button)
		
		self.contentView!.snp_makeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.view)
		}
		
		title.snp_makeConstraints { (make) in
			make.left.equalTo(self.contentView!).offset(15)
			make.right.equalTo(self.contentView!)
			make.top.equalTo(self.contentView!.snp_bottom).offset(-200)
			make.height.equalTo(40)
		}
		
		description.snp_makeConstraints { (make) in
			make.left.equalTo(self.contentView!).offset(15)
			make.right.equalTo(self.contentView!)
			make.top.equalTo(title.snp_bottom)
			make.bottom.equalTo(button.snp_top)
		}
		
		blurrySemiTransparentView.snp_makeConstraints { (make) in
			make.top.left.right.bottom.equalTo(contentView!)
		}
		
		button.snp_makeConstraints { (make) in
			make.centerX.equalTo(self.contentView!)
			make.bottom.equalTo(self.contentView!).offset(-20)
			make.width.equalTo(80)
			make.height.equalTo(40)
		}
	}
	
	private func showAntitrackingHint() {
		contentView = UIView()
		self.contentView!.backgroundColor = UIColor.clearColor()
		self.view.addSubview(self.contentView!)

		let blurrySemiTransparentView = UIView(frame:self.view.bounds)
		blurrySemiTransparentView.backgroundColor = UIColor(rgb: 0x2d3e50).colorWithAlphaComponent(0.9)
		self.contentView!.addSubview(blurrySemiTransparentView)
		blurrySemiTransparentView.tag = InteractiveIntroViewController.blurryBackgroundViewTag
		blurrySemiTransparentView.layer.mask = self.antitrackingMaskLayer()

		let title = UILabel()
		title.text = NSLocalizedString("Anti-Tracking", tableName: "Cliqz", comment: "Anti-tracking hint title")
		title.font = UIFont.systemFontOfSize(InteractiveIntroViewController.titleFontSize)
		title.textColor = UIColor.whiteColor()
		title.textAlignment = .Center
		self.contentView!.addSubview(title)
		let description = UILabel()
		self.contentView!.addSubview(description)
		description.text = NSLocalizedString("Anti-Tracking description", tableName: "Cliqz", comment: "Anti-tracking hint description")
		description.textColor = UIColor.whiteColor()
		description.font = UIFont.systemFontOfSize(InteractiveIntroViewController.descriptionFontSize)
		description.numberOfLines = 0
		description.textAlignment = .Center
		let button = UIButton()
		button.setTitle("OK", forState: .Normal)
		button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
		button.layer.borderColor = UIColor.whiteColor().CGColor
		button.layer.borderWidth = 2
		button.layer.cornerRadius = 6
		button.backgroundColor = UIColor.clearColor()
		button.addTarget(self, action: #selector(closeHint), forControlEvents: .TouchUpInside)
		self.contentView!.addSubview(button)

		self.contentView!.snp_makeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.view)
		}

		title.snp_makeConstraints { (make) in
			make.centerX.centerY.equalTo(self.contentView!)
		}

		description.snp_makeConstraints { (make) in
			make.centerX.equalTo(self.contentView!)
			make.top.equalTo(title.snp_bottom).offset(15)
			make.left.right.equalTo(self.contentView!)
			make.height.equalTo(60)
		}

		blurrySemiTransparentView.snp_makeConstraints { (make) in
			make.top.left.right.bottom.equalTo(contentView!)
		}

		button.snp_makeConstraints { (make) in
			make.centerX.equalTo(self.contentView!)
			make.bottom.equalTo(self.contentView!).offset(-20)
			make.width.equalTo(80)
			make.height.equalTo(40)
		}
	}

	private func cliqzSearchMaskLayer() -> CAShapeLayer {
		let path = UIBezierPath()
		let arcRadius: CGFloat = self.view.frame.size.width / 2 - 15
		path.moveToPoint(CGPointMake(0, 0))
		path.addLineToPoint(CGPointMake(self.view.frame.size.width, 0))
		path.addLineToPoint(CGPointMake(self.view.frame.size.width, 30))
		let center = CGPointMake(arcRadius + 30, arcRadius + 15)
		path.addArcWithCenter(center, radius: arcRadius, startAngle: 0, endAngle: 0.04, clockwise: false)
		path.addLineToPoint(CGPointMake(self.view.frame.size.width, self.view.frame.size.height))
		path.addLineToPoint(CGPointMake(0, self.view.frame.size.height))
		path.closePath()
		let maskLayer = CAShapeLayer()
		maskLayer.path = path.CGPath
		return maskLayer
	}

	private func antitrackingMaskLayer() -> CAShapeLayer {
		let path = UIBezierPath()
		let arcRadius: CGFloat = 80
		path.moveToPoint(CGPointMake(0, 0))
		path.addLineToPoint(CGPointMake(self.view.frame.size.width - arcRadius, 0))
		path.addArcWithCenter(CGPointMake(self.view.frame.size.width, 0), radius: arcRadius, startAngle: 0, endAngle: 1.57, clockwise: false)
		path.addLineToPoint(CGPointMake(self.view.frame.size.width, self.view.frame.size.height))
		path.addLineToPoint(CGPointMake(0, self.view.frame.size.height))
		path.closePath()
		let maskLayer = CAShapeLayer()
		maskLayer.path = path.CGPath
		return maskLayer
	}

	@objc private func closeHint() {
		self.contentView?.removeFromSuperview()
		self.contentView = nil
		self.dismissViewControllerAnimated(true, completion: nil)
	}
}
