//
//  TabCellView.swift
//  Client
//
//  Created by Sahakyan on 8/17/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class TabViewCell: UITableViewCell {

	let titleLabel = UILabel()
	let URLLabel = UILabel()
	let logoImageView = UIImageView()
    let closeButton = UIButton()
	let cardView = UIView()
    var clickedElement: String?
    var selectedTab: Tab?
    weak var delegate :TabViewCellDelegate?
	
	var animator: SwipeAnimator!

	var isPrivateTabCell: Bool = false {
		didSet {
			cardView.backgroundColor = self.backgroundColor()
			titleLabel.textColor = self.textColor()
            closeButton.tintColor = self.closeButtonTintColor()
			setNeedsDisplay()
		}
	}

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.contentView.backgroundColor = UIConstants.AppBackgroundColor
		cardView.backgroundColor = self.backgroundColor()
		cardView.layer.cornerRadius = 4
		contentView.addSubview(cardView)
		cardView.addSubview(titleLabel)
		titleLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)
		titleLabel.textColor = self.textColor()
		titleLabel.backgroundColor = UIColor.clear
		cardView.addSubview(URLLabel)
		URLLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
		URLLabel.textColor = UIColor(rgb: 0x77ABE6)
		URLLabel.backgroundColor = UIColor.clear
		cardView.addSubview(logoImageView)
        closeButton.setImage(UIImage.templateImageNamed("closeTab"), for: .normal)
        closeButton.addTarget(self, action: #selector(SELcloseTab(_:)), for: .touchUpInside)
        cardView.addSubview(closeButton)
        
		self.isPrivateTabCell = false

		let swipeParams = SwipeAnimationParameters(
			totalRotationInDegrees: 0,
			deleteThreshold: 80,
			totalScale: 0.9,
			totalAlpha: 0,
			minExitVelocity: 800,
			recenterAnimationDuration: 0.15)
		self.animator = SwipeAnimator(animatingView: self.cardView, container: self, params: swipeParams)
        
        // tab gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapPressed(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        self.addGestureRecognizer(tapGestureRecognizer)
        
	}
    
    func tapPressed(_ gestureRecognizer: UIGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: self.cardView)
        
        if titleLabel.frame.contains(touchLocation) {
            clickedElement = "title"
        } else if URLLabel.frame.contains(touchLocation) {
            clickedElement = "url"
        } else if logoImageView.frame.contains(touchLocation) {
            clickedElement = "logo"
        } 
    }
    
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		let cardViewLeftOffset = 25
		let cardViewRightOffset = -25
		let cardViewTopOffset = 5
		let cardViewBottomOffset = -5
		self.cardView.snp_remakeConstraints { (make) in
			make.left.equalTo(self.contentView).offset(cardViewLeftOffset)
			make.right.equalTo(self.contentView).offset(cardViewRightOffset)
			make.top.equalTo(self.contentView).offset(cardViewTopOffset)
			make.bottom.equalTo(self.contentView).offset(cardViewBottomOffset)
		}

		let contentLeftOffset = 15
		let logoSize = CGSize(width: 32, height: 32)
		self.logoImageView.snp_remakeConstraints { (make) in
			make.top.equalTo(self.cardView)
			make.left.equalTo(self.cardView).offset(contentLeftOffset)
			if let _ = self.logoImageView.image {
				make.size.equalTo(logoSize)
			} else {
				make.size.equalTo(CGSize(width: 0, height: 0))
			}
		}
		let URLLeftOffset = 15
		let URLHeight = 24
		self.URLLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.cardView).offset(7)
			if let _ = self.logoImageView.image {
				make.left.equalTo(self.logoImageView.snp_right).offset(URLLeftOffset)
			} else {
				make.left.equalTo(self.cardView).offset(URLLeftOffset)
			}
			make.height.equalTo(URLHeight)
			make.right.equalTo(self.cardView)
		}
		self.titleLabel.snp_remakeConstraints { (make) in
			if let _ = self.logoImageView.image {
				make.top.equalTo(self.logoImageView.snp_bottom).offset(5)
			} else {
				make.top.equalTo(self.URLLabel.snp_bottom).offset(5)
			}
			make.left.equalTo(self.cardView).offset(contentLeftOffset)
			make.height.equalTo(24)
			make.right.equalTo(self.cardView).offset(-contentLeftOffset)
		}
        
        self.closeButton.snp_makeConstraints { (make) in
            make.size.height.equalTo(54.0)
            make.right.equalTo(self.cardView).offset(18)
            make.top.equalTo(self.cardView).offset(-6)
        }
        
        self.closeButton.imageEdgeInsets = UIEdgeInsetsMake(-24, 0, 0, 5)
    }

	override func prepareForReuse() {
		self.cardView.transform = CGAffineTransform.identity
		self.cardView.alpha = 1
	}

	fileprivate func backgroundColor() -> UIColor {
		return isPrivateTabCell ? UIColor.darkGray : UIColor.white
	}

    fileprivate func closeButtonTintColor() -> UIColor {
        return isPrivateTabCell ? UIColor.white : UIColor.darkGray
    }
	fileprivate func textColor() -> UIColor {
		return isPrivateTabCell ? UIConstants.PrivateModeTextColor : UIConstants.NormalModeTextColor
	}

    func SELcloseTab(_ button: UIButton) {
        if let tab = selectedTab {
            delegate?.closeTab(tab)
        }
    }
}
