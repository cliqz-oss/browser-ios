//
//  OffrView.swift
//  Client
//
//  Created by Sahakyan on 12/7/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

class OffrView: UIView {
    
    private var offr: Offr!
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let logoView = UIImageView()
    private let promoCodeLabel = UILabel()
    private let promoCodeButton = UIButton(type: .custom)
	private let conditionsIcon = UIImageView()
	private let conditionsLabel = UILabel()
	private let myOffrzLogo = UIImageView()
	private let offrButton = UIButton(type: .custom)

    init(offr: Offr) {
        super.init(frame: CGRect.zero)
        self.offr = offr
        
        self.setupComponents()
        self.setStyles()
        self.setConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	func addTapAction(_ target: Any?, action: Selector) {
		self.offrButton.addTarget(target, action: action, for: .touchUpInside)
	}

    private func setupComponents() {
        titleLabel.text = offr.title
        descriptionLabel.text = offr.description
        if let logoURL = offr.logoURL {
            LogoLoader.downloadImage(logoURL, completed: { (logoImage, error) in
                self.logoView.image = logoImage
            })
        }
        promoCodeLabel.text = NSLocalizedString("MyOffrz Copy promocode", tableName: "Cliqz", comment: "[MyOffrz] copy promocode action hint")
        promoCodeButton.setTitle(offr.code, for: .normal)
		promoCodeButton.addTarget(self, action: #selector(copyCode), for: .touchUpInside)
		conditionsLabel.text = NSLocalizedString("MyOffrz Conditions", tableName: "Cliqz", comment: "[MyOffrz] Conditions title")
		conditionsIcon.image = UIImage(named: "trackerInfo")
        offrButton.setTitle(offr.actionTitle, for: .normal)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
        self.addSubview(logoView)
        self.addSubview(promoCodeLabel)
        self.addSubview(promoCodeButton)
		self.addSubview(conditionsIcon)
		self.addSubview(conditionsLabel)
		self.addSubview(myOffrzLogo)
		self.addSubview(offrButton)
    }

    private func setStyles() {
        self.layer.cornerRadius = 35
		self.clipsToBounds = true
        self.backgroundColor = UIColor.white
//        self.dropShadow(color: UIColor.black, opacity: 0.12, offSet: CGSize(width: 0, height: 2), radius: 4)
		
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.numberOfLines = 0

        descriptionLabel.numberOfLines = 0

		logoView.contentMode = .scaleAspectFit
		promoCodeLabel.textColor = UIConstants.CliqzThemeColor
        promoCodeLabel.font = UIFont.boldSystemFont(ofSize: 11)
		promoCodeButton.setTitleColor(UIConstants.CliqzThemeColor, for: .normal)
		promoCodeButton.backgroundColor = UIColor(rgb: 0xE7ECEE)
		promoCodeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
		conditionsLabel.textColor = UIColor.black
		conditionsLabel.font = UIFont.boldSystemFont(ofSize: 10)
		conditionsIcon.tintColor = UIConstants.CliqzThemeColor
		conditionsIcon.contentMode = .scaleAspectFit

		myOffrzLogo.image = UIImage(named: "offrzLogo")
		offrButton.backgroundColor = UIColor(rgb: 0xF67057)
		offrButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
	}

    private func setConstraints() {
        titleLabel.snp.makeConstraints { (make) in
			make.left.right.equalTo(self).inset(15)
            make.top.equalTo(self).inset(20)
			make.height.greaterThanOrEqualTo(20)
        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(15)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
			make.height.greaterThanOrEqualTo(60)
        }
        logoView.snp.makeConstraints { (make) in
//            make.top.equalTo(descriptionLabel.snp.bottom).offset(10)
            make.center.equalTo(self)
			make.width.lessThanOrEqualTo(self).offset(-10)
        }
        promoCodeLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(promoCodeButton.snp.top).offset(-4)
            make.left.right.equalTo(self).inset(15)
        }
        promoCodeButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(conditionsIcon.snp.top).offset(-10)
            make.left.right.equalTo(self).inset(15)
        }
		conditionsIcon.snp.makeConstraints { (make) in
			make.bottom.equalTo(offrButton.snp.top).offset(-10)
			make.left.equalTo(self).inset(15)
		}
		conditionsLabel.snp.makeConstraints { (make) in
			make.bottom.equalTo(offrButton.snp.top).offset(-11)
			make.left.equalTo(conditionsIcon.snp.right).offset(5)
			make.height.equalTo(15)
		}
		myOffrzLogo.snp.makeConstraints { (make) in
			make.right.equalTo(self).offset(-8)
			make.bottom.equalTo(offrButton.snp.top)
		}
		offrButton.snp.makeConstraints { (make) in
			make.bottom.equalTo(self)
			make.left.right.equalTo(self)
			make.height.equalTo(61)
		}
    }

	@objc
	private func copyCode() {
		TelemetryLogger.sharedInstance.logEvent(.MyOffrz("copy", "code"))
		let pastBoard = UIPasteboard.general
		pastBoard.string = offr.code
		self.promoCodeLabel.text = NSLocalizedString("MyOffrz Code copied", tableName: "Cliqz", comment: "[MyOffrz] copy promocode done")
	}

}
