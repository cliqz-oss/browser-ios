//
//  NewsViewCell.swift
//  Client
//
//  Created by Sahakyan on 1/26/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

class NewsViewCell: UITableViewCell {
	
	let titleLabel = UILabel()
	let URLLabel = UILabel()

	lazy var logoContainerView = UIView()
	let logoImageView = UIImageView()
	var fakeLogoView: UIView?

	let cardView = UIView()
    var clickedElement = ""
    
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.contentView.backgroundColor = UIColor.white // UIColor(colorString: "BBB9BD")
		self.backgroundColor = UIColor.white //UIColor(colorString: "BBB9BD")
		cardView.backgroundColor = UIColor.clear
		cardView.layer.cornerRadius = 4
		contentView.addSubview(cardView)
		cardView.addSubview(titleLabel)
		titleLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)
		titleLabel.textColor = self.textColor()
		titleLabel.backgroundColor = UIColor.clear
		cardView.addSubview(URLLabel)
		URLLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
		URLLabel.textColor = UIColor.darkGray
		URLLabel.backgroundColor = UIColor.clear
		titleLabel.numberOfLines = 2
		self.cardView.addSubview(self.logoContainerView)
		logoContainerView.addSubview(logoImageView)
        logoContainerView.layer.cornerRadius = 7
		logoContainerView.layer.masksToBounds = true
        // tab gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(newsPressed(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        self.addGestureRecognizer(tapGestureRecognizer)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
    func newsPressed(_ gestureRecognizer: UIGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: self.cardView)
        
        if titleLabel.frame.contains(touchLocation) {
            clickedElement = "title"
        } else if URLLabel.frame.contains(touchLocation) {
            clickedElement = "url"
        } else if logoContainerView.frame.contains(touchLocation) {
            clickedElement = "logo"
        }
    }
    
	override func layoutSubviews() {
		super.layoutSubviews()
		let cardViewLeftOffset = 0
		let cardViewRightOffset = -13
		let cardViewTopOffset = 0
		let cardViewBottomOffset = -5
		self.cardView.snp.remakeConstraints { (make) in
			make.left.equalTo(self.contentView).offset(cardViewLeftOffset)
			make.right.equalTo(self.contentView).offset(cardViewRightOffset)
			make.top.equalTo(self.contentView).offset(cardViewTopOffset)
			make.bottom.equalTo(self.contentView).offset(cardViewBottomOffset)
		}
		
		let contentOffset = 15
		let logoSize = CGSize(width: 48, height: 48)
		logoContainerView.snp.makeConstraints { make in
			make.top.equalTo(self.cardView).offset(10)
			make.left.equalTo(self.cardView).offset(10)
			make.size.equalTo(logoSize)
		}
		self.logoImageView.snp.remakeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.logoContainerView)
		}
		let URLLeftOffset = 15
		let URLHeight = 18
		self.URLLabel.snp.remakeConstraints { (make) in
			make.top.equalTo(self.cardView).offset(5)
			make.left.equalTo(self.logoImageView.snp.right).offset(URLLeftOffset)
			make.height.equalTo(URLHeight)
			make.right.equalTo(self.cardView)
		}
		self.titleLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.URLLabel.snp.bottom)
			make.left.equalTo(self.logoImageView.snp.right).offset(URLLeftOffset)
			make.height.equalTo(38)
			make.right.equalTo(self.cardView).offset(-contentOffset)
		}
	}
	
	override func prepareForReuse() {
		self.cardView.transform = CGAffineTransform.identity
		self.cardView.alpha = 1
		self.logoImageView.image = nil
		self.fakeLogoView?.removeFromSuperview()
		self.fakeLogoView = nil
        clickedElement = ""
	}
	
	fileprivate func textColor() -> UIColor {
		return UIConstants.NormalModeTextColor
	}
	
}
