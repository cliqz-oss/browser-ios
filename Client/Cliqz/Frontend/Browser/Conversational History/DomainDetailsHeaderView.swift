//
//  DomainDetailsHeaderView.swift
//  Client
//
//  Created by Tim Palade on 8/14/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

protocol DomainDetailsHeaderViewDelegate {
    func headerGoBackPressed()
    func headerLogoPressed()
}

class DomainDetailsHeaderView: UIView {
    
    let backBtn = UIButton(type: .custom)
    let title = UILabel()
    let logo = UIButton(type: .custom)
    let sep = UIView()
    
    var delegate: DomainDetailsHeaderViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        componentSetUp()
        
        self.addSubview(backBtn)
        self.addSubview(title)
        self.addSubview(logo)
        self.addSubview(sep)
        
        setConstraints()
        setStyling()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func componentSetUp() {
        backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        logo.addTarget(self, action: #selector(logoPressed), for: .touchUpInside)
    }
    
    func setConstraints() {
        
        backBtn.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self)
            make.left.equalTo(self)
            make.height.width.equalTo(40)
        }
        
        logo.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self)
            make.top.equalTo(self).offset(6)
            make.width.equalTo(38)
            make.height.equalTo(38)
        }
        
        title.snp.remakeConstraints { (make) in
            make.top.equalTo(logo.snp.bottom)
            make.left.right.equalTo(self)
            make.height.equalTo(20)
        }
        
        sep.snp.remakeConstraints { (make) in
            make.bottom.equalTo(self)
            make.left.right.equalTo(self)
            make.height.equalTo(1)
        }
    }
    
    func setStyling() {
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        backBtn.tintColor = UIColor.white
        backBtn.setImage(UIImage(named:"cliqzBackWhite"), for: .normal)
        
        title.textAlignment = .center
        title.numberOfLines = 0
        title.font = UIFont.boldSystemFont(ofSize: 10)
        title.textColor = UIColor(colorString: "F8F8F8")
        
        logo.layer.cornerRadius = 4
        logo.clipsToBounds = true
        
        sep.backgroundColor = UIColor.clear
    }
    
    @objc
    func goBack(_ sender: UIButton) {
        self.delegate?.headerGoBackPressed()
    }
    
    @objc
    func logoPressed(_ sender: UIButton) {
        self.delegate?.headerLogoPressed()
    }
    
}
