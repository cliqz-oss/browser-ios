//
//  CustomButton.swift
//  Client
//
//  Created by Sahakyan on 10/2/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

class CustomButton: UIView {

	var action: (() -> ())?

	init() {
		super.init(frame: CGRect.zero)
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CustomButton.tapped))
		self.addGestureRecognizer(tapGesture)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setImage(_ image: UIImage) {
		self.purgeSubviews()
		let imgView = UIImageView(image: image)
		self.addSubview(imgView)
		imgView.snp.makeConstraints { (make) in
			make.edges.equalTo(self)
		}
	}

	func setView(_ view: UIView) {
		self.purgeSubviews()
		self.addSubview(view)
		view.snp.makeConstraints { (make) in
			make.edges.equalTo(self)
		}
	}

	func purgeSubviews() {
		for v in self.subviews {
			v.removeFromSuperview()
		}
	}

	func tapped(_ sender: UITapGestureRecognizer) {
		self.action?()
	}
}
