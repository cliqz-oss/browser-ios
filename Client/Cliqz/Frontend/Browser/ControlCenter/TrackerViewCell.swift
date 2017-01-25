//
//  TrackerViewCell.swift
//  Client
//
//  Created by Sahakyan on 8/29/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class TrackerViewCell: UITableViewCell {

	let iconImageView = UIImageView()

	let nameLabel = UILabel()
	let countLabel = UILabel()

	var isPrivateMode = false {
		didSet {
			iconImageView.tintColor = self.textColor()
			nameLabel.textColor = self.textColor()
			countLabel.textColor = self.textColor()
			self.setNeedsDisplay()
		}
	}

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.contentView.backgroundColor = UIColor.clearColor()
		iconImageView.backgroundColor = UIColor.clearColor()
		let img = UIImage(named: "trackerInfo")
		iconImageView.image = img?.imageWithRenderingMode(.AlwaysTemplate)
		iconImageView.tintColor = self.textColor()
		self.contentView.addSubview(iconImageView)
		nameLabel.backgroundColor = UIColor.clearColor()
		nameLabel.textColor = self.textColor()
		self.contentView.addSubview(nameLabel)
		countLabel.backgroundColor = UIColor.clearColor()
		countLabel.textColor = self.textColor()
		countLabel.textAlignment = .Right
		self.contentView.addSubview(countLabel)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.iconImageView.snp_makeConstraints { (make) in
			make.left.equalTo(self.contentView)
			make.top.equalTo(self.contentView).offset(3)
			var sz: CGSize = CGSizeMake(0, 0)
			if let img = self.iconImageView.image {
				sz = img.size
			}
			make.size.equalTo(sz)
		}
		self.nameLabel.snp_makeConstraints { (make) in
			make.left.equalTo(self.iconImageView.snp_right).offset(10)
			make.top.equalTo(self.contentView)
			make.right.equalTo(self.countLabel.snp_left)
		}
		self.countLabel.snp_makeConstraints { (make) in
			make.left.equalTo(self.nameLabel.snp_right)
			make.width.equalTo(20)
			make.right.equalTo(self.contentView).offset(-10)
		}
	}

	private func textColor() -> UIColor {
		if self.isPrivateMode == true {
			return UIConstants.PrivateModeTextColor
		}
		return UIConstants.NormalModeTextColor
	}
}
