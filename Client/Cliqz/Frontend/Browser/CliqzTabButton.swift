//
//  CliqzTabButton.swift
//  Client
//
//  Created by Sahakyan on 8/11/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import SnapKit

class CliqzTabsButton: TabsButton {

	let BackgroundInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

	fileprivate var _image: UIImage?
	var image: UIImage? {
		set {
			_image = newValue?.withRenderingMode(.alwaysTemplate)
			self.backgroundImage.image = _image
		}
		get {
			return _image
		}
	}

	lazy var backgroundImage: UIImageView = {
		let imageView = UIImageView()
		if let i = self.image {
			imageView.image = i
		}
		return imageView
	}()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.addSubview(self.backgroundImage)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func updateConstraints() {
		super.updateConstraints()
		backgroundImage.snp_remakeConstraints { (make) -> Void in
			make.edges.equalTo(self).inset(BackgroundInsets)
		}
	}
	
	override func clone() -> UIView {
		let button = CliqzTabsButton()
		button.accessibilityLabel = accessibilityLabel
		button.title.text = title.text
		
		// Copy all of the styable properties over to the new TabsButton
		button.title.font = title.font
		button.title.textColor = title.textColor
		button.title.layer.cornerRadius = title.layer.cornerRadius

		button.titleBackgroundColor = self.titleBackgroundColor

		button.borderWidth = self.borderWidth
		button.borderColor = self.borderColor

		button.image = image
		return button
	}
	
	override dynamic var textColor: UIColor? {
		get { return title.textColor }
		set {
			title.textColor = newValue
			self.backgroundImage.tintColor = textColor
		}
	}

}
