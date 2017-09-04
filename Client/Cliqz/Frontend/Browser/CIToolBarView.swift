//
//  CIToolBarView.swift
//  Client
//
//  Created by Tim Palade on 9/4/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

protocol CIToolBarDelegate: class {
    func backPressed()
    func forwardPressed()
    func middlePressed()
    func sharePressed()
    func tabsPressed()
}

final class CIToolBarView: UIView {
    
    let backButton = UIButton()
    let forwardButton = UIButton()
    let middleButton = UIButton()
    let shareButton = UIButton()
    let tabsButton = UIButton()
    
    weak var delegate: CIToolBarDelegate? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setUpComponent()
        setStyling()
        setConstraints()
    }
    
    private func setUpComponent() {
        self.addSubview(backButton)
        self.addSubview(forwardButton)
        self.addSubview(middleButton)
        self.addSubview(shareButton)
        self.addSubview(tabsButton)
        
        backButton.setImage(UIImage.templateImageNamed("bottomNav-back"), for: .normal)
        forwardButton.setImage(UIImage.templateImageNamed("bottomNav-forward"), for: .normal)
        middleButton.setImage(UIImage.templateImageNamed("homeButton"), for: .normal)
        shareButton.setImage(UIImage.templateImageNamed("bottomNav-send"), for: .normal)
        tabsButton.setImage(UIImage.templateImageNamed("tabs"), for: .normal)
        
        backButton.tintColor = .white
        forwardButton.tintColor = .white
        middleButton.tintColor = .white
        shareButton.tintColor = .white
        tabsButton.tintColor = .white
        
        
        backButton.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardPressed), for: .touchUpInside)
        middleButton.addTarget(self, action: #selector(middlePressed), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(sharePressed), for: .touchUpInside)
        tabsButton.addTarget(self, action: #selector(tabsPressed), for: .touchUpInside)
    }
    
    private func setStyling() {
        self.backgroundColor = .clear
    }
    
    private func setConstraints() {
        
        backButton.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(self.snp.width).dividedBy(5)
        }
        
        forwardButton.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.width.equalTo(self.snp.width).dividedBy(5)
            make.left.equalTo(backButton.snp.right)
        }
        
        middleButton.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.width.equalTo(self.snp.width).dividedBy(5)
            make.left.equalTo(forwardButton.snp.right)
        }
        
        shareButton.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.width.equalTo(self.snp.width).dividedBy(5)
            make.left.equalTo(middleButton.snp.right)
        }
        
        tabsButton.snp.makeConstraints { (make) in
            make.right.top.bottom.equalToSuperview()
            make.width.equalTo(self.snp.width).dividedBy(5)
            make.left.equalTo(shareButton.snp.right)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//button selectors
extension CIToolBarView {
    
    @objc
    func backPressed(_ sender: UIButton) {
        delegate?.backPressed()
    }
    
    @objc
    func forwardPressed(_ sender: UIButton) {
        delegate?.forwardPressed()
    }
    
    @objc
    func middlePressed(_ sender: UIButton) {
        delegate?.middlePressed()
    }
    
    @objc
    func sharePressed(_ sender: UIButton) {
        delegate?.sharePressed()
    }
    
    @objc
    func tabsPressed(_ sender: UIButton) {
        delegate?.tabsPressed()
    }
}














