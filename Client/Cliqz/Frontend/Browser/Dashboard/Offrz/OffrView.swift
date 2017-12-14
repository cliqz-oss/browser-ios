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
    
    private func setupComponents() {
        titleLabel.text = "TEST TITLE"//offr.title
        descriptionLabel.text = "TEST DESCRIPTION\nTEST DESCRIPTION"//offr.description
        if let logoURL = offr.logoURL {
            
            LogoLoader.downloadImage(logoURL, completed: { (logoImage, error) in
                self.logoView.image = logoImage
            })
        }
        promoCodeLabel.text = NSLocalizedString("Click on the promocode to copy", tableName: "Cliqz", comment: "[MyOffrz] copy promocode title")
        promoCodeLabel.textColor = UIConstants.CliqzThemeColor
        promoCodeButton.setTitle("MYOFFRZ17", for: .normal)
        promoCodeButton.setTitleColor(UIConstants.CliqzThemeColor, for: .normal)
        
        
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
        self.addSubview(logoView)
        self.addSubview(promoCodeLabel)
        self.addSubview(promoCodeButton)
    }
    
    private func setStyles() {
        self.layer.cornerRadius = 20
        self.layer.masksToBounds = true
        self.backgroundColor = UIColor.white
        self.dropShadow(color: UIColor.black, opacity: 0.12, offSet: CGSize(width: 0, height: 2), radius: 4)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.numberOfLines = 2
        
        descriptionLabel.numberOfLines = 0
        promoCodeLabel.font = UIFont.systemFont(ofSize: 12)
    }
    
    private func setConstraints() {
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self).inset(35)
            make.left.right.equalTo(self).inset(15)
        }
        
        descriptionLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(15)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        
        logoView.snp.makeConstraints { (make) in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(10)
            make.centerX.equalTo(self)
            make.size.equalTo(self.snp.width)
        }
        
        promoCodeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(logoView.snp.bottom).offset(10)
            make.left.right.equalTo(self).inset(15)
        }
        
        promoCodeButton.snp.makeConstraints { (make) in
            make.top.equalTo(promoCodeLabel.snp.bottom)
            make.left.right.equalTo(self).inset(15)
        }
    }
}
