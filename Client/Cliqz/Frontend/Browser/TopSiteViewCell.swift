//
//  TopSiteViewCell.swift
//  Client
//
//  Created by Sahakyan on 1/26/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

protocol TopSiteCellDelegate: NSObjectProtocol {
	
	func topSiteHided(index: Int)
}

class TopSiteViewCell: UICollectionViewCell {

	weak var delegate: TopSiteCellDelegate?

	lazy var logoContainerView = UIView()
	lazy var logoImageView: UIImageView = UIImageView()
	var fakeLogoView: UIView?
	lazy var logoHostLabel = UILabel()

	lazy var deleteButton: UIButton = {
		let b = UIButton(type: .Custom)
		b.setImage(UIImage(named: "removeTopsite"), forState: .Normal)
		b.addTarget(self, action: #selector(hideTopSite), forControlEvents: .TouchUpInside)
		return b
	}()
	
	var isDeleteMode = false {
		didSet {
			if isDeleteMode && !self.isEmptyContent() {
				self.contentView.addSubview(self.deleteButton)
				self.deleteButton.snp_makeConstraints(closure: { (make) in
					make.top.equalTo(self.contentView.frame.origin.y)
                    make.left.equalTo(self.contentView.frame.origin.x)
				})
				self.startWobbling()
			} else {
				self.deleteButton.removeFromSuperview()
				self.stopWobbling()
			}
		}
	}
	
	private func isEmptyContent() -> Bool {
		return self.logoContainerView.subviews.count == 0 || (self.logoImageView.image == nil && self.fakeLogoView?.superview == nil)
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColor = UIColor.clearColor()
		self.contentView.backgroundColor = UIColor.clearColor()

		self.contentView.addSubview(self.logoContainerView)
		logoContainerView.snp_makeConstraints { make in
			make.top.equalTo(self.contentView.frame.origin.y + 8)
			make.left.equalTo(self.contentView.frame.origin.x + 8)
			make.height.width.equalTo(60)
		}

		self.logoContainerView.addSubview(self.logoImageView) //isn't this a retain cycle?
		logoImageView.snp_makeConstraints { make in
			make.top.left.bottom.right.equalTo(self.logoContainerView)
		}
		self.logoContainerView.backgroundColor = UIColor.lightGrayColor()
		self.logoContainerView.layer.cornerRadius = 12
        self.logoContainerView.layer.borderWidth = 2
        self.logoContainerView.layer.borderColor = UIColor.clearColor().CGColor//UIConstants.AppBackgroundColor.CGColor
        self.logoContainerView.layer.shouldRasterize = false
		self.logoContainerView.clipsToBounds = true
		
		self.contentView.addSubview(self.logoHostLabel);
		self.logoHostLabel.snp_makeConstraints { (make) in
			make.left.right.bottom.equalTo(self.contentView)
			make.top.equalTo(self.logoContainerView.snp_bottom).offset(3)
		}
		self.logoHostLabel.textAlignment = .Center
		self.logoHostLabel.font = UIFont.systemFontOfSize(10)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		self.logoImageView.image = nil
		self.fakeLogoView?.removeFromSuperview()
		self.fakeLogoView = nil
		self.deleteButton.removeFromSuperview()
		self.logoHostLabel.text = ""
	}
	
	private func startWobbling() {
		let startAngle = -M_PI_4/10
		let endAngle = M_PI_4/10
		
		let wobblingAnimation = CAKeyframeAnimation.init(keyPath: "transform.rotation")
		wobblingAnimation.values = [startAngle, endAngle]
		wobblingAnimation.duration = 0.13
		wobblingAnimation.autoreverses = true
		wobblingAnimation.repeatCount = FLT_MAX
		wobblingAnimation.timingFunction = CAMediaTimingFunction.init(name:kCAMediaTimingFunctionLinear)
        self.logoContainerView.layer.shouldRasterize = true
		self.layer.addAnimation(wobblingAnimation, forKey: "rotation")
	}
	
	private func stopWobbling() {
		self.layer.removeAllAnimations()
        self.logoContainerView.layer.shouldRasterize = false
	}
	
	@objc private func hideTopSite() {
        self.logoImageView.image = nil
        self.fakeLogoView?.removeFromSuperview()
        self.fakeLogoView = nil
        self.isDeleteMode = false
		self.logoHostLabel.text = ""
		self.delegate?.topSiteHided(self.tag)
	}
}
