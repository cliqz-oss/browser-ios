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

protocol DomainDetailsHeaderViewProtocol {
    func image() -> UIImage?
    func baseUrl() -> String
}

final class DomainDetailsHeaderView: UIView {
    
    let backBtn = UIButton(type: .custom)
    let title = UILabel()
    let logo = UIButton(type: .custom)
    let sep = UIView()
    
    var delegate: DomainDetailsHeaderViewDelegate?
    var dataSource: DomainDetailsHeaderViewProtocol
    
    init(frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0), dataSource: DomainDetailsHeaderViewProtocol) {
        
        self.dataSource = dataSource
        super.init(frame: frame)
        
        componentSetUp()
        setConstraints()
        setStyling()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func componentSetUp() {
        
        self.addSubview(backBtn)
        self.addSubview(title)
        self.addSubview(logo)
        self.addSubview(sep)
        
        backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        logo.addTarget(self, action: #selector(logoPressed), for: .touchUpInside)
        
        logo.setImage(dataSource.image(), for: .normal) //?? UIImage(named: "coolLogo")
        title.text = dataSource.baseUrl()
    }
    
    private func setConstraints() {
        
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
    
    private func setStyling() {
        
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
    private func goBack(_ sender: UIButton) {
        self.delegate?.headerGoBackPressed()
    }
    
    @objc
    private func logoPressed(_ sender: UIButton) {
        self.delegate?.headerLogoPressed()
    }
    
}
