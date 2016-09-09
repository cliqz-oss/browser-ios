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

	private lazy var antitrackingButton: UIButton = {
		let button = UIButton(type: .Custom)
		button.setTitle("0", forState: .Normal)
		button.titleLabel?.font = UIFont.systemFontOfSize(12)
		button.backgroundColor = UIColor(rgb: 0x2CBA84)
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
			locationContainer.snp_updateConstraints { make in
				let x = -(UIConstants.ToolbarHeight + 10)
				make.trailing.equalTo(self).offset(x)
			}
			self.antitrackingButton.snp_updateConstraints(closure: { (make) in
				make.size.equalTo(CGSizeMake(42, CGFloat(URLBarViewUX.LocationHeight)))
			})
		} else {
			self.antitrackingButton.snp_updateConstraints(closure: { (make) in
				make.size.equalTo(CGSizeMake(0, 0))
			})
		}
	}

	func updateTrackersCount(count: Int) {
		self.antitrackingButton.setTitle("\(count)", forState: .Normal)
		self.setNeedsDisplay()
	}

	func showAntitrackingButton(hidden: Bool) {
		self.antitrackingButton.hidden = !hidden
		self.setNeedsUpdateConstraints()
	}

	private func commonInit() {
		let img = UIImage(named: "shieldButton")
		self.antitrackingButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
		self.antitrackingButton.setImage(img, forState: .Normal)
		self.antitrackingButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 2, bottom: 5, right: 0)
		self.antitrackingButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 5, bottom: 4, right: 20)
		self.antitrackingButton.addTarget(self, action: #selector(openAntitrackingView), forControlEvents: .TouchUpInside)
		addSubview	(self.antitrackingButton)
		antitrackingButton.snp_makeConstraints { make in
			make.centerY.equalTo(self.locationContainer)
			make.leading.equalTo(self.locationContainer.snp_trailing)
			make.size.equalTo(CGSizeMake(40, CGFloat(URLBarViewUX.LocationHeight)))
		}
	}
	
	@objc private func openAntitrackingView(sender: UIButton) {
		self.delegate?.urlBarDidClickAntitracking(self)
	}
}