//
//  HistoryDetailsLeftCell.swift
//  Client
//
//  Created by Tim Palade on 8/8/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class BubbleLeftCell: BubbleCell {

    let bubbleView = UIView()
    let titleLabel = UILabel()
    let urlLabel = UILabel()
    let timeLabel = UILabel()
    let iconImageView = UIImageView()
    let iconView = UIView()
    
    override func setupComponents() {
        super.setupComponents()
        
        bubbleView.addSubview(iconImageView)
        bubbleView.addSubview(iconView)
        bubbleView.addSubview(urlLabel)
        bubbleView.addSubview(titleLabel)
        bubbleView.addSubview(timeLabel)
        bubbleContainerView.addSubview(bubbleView)
    }
    
    override func cellPressed(_ gestureRecognizer: UIGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: self.bubbleView)
        
        if titleLabel.frame.contains(touchLocation) {
            clickedElement = "title"
        } else if urlLabel.frame.contains(touchLocation) {
            clickedElement = "url"
        } else if timeLabel.frame.contains(touchLocation) {
            clickedElement = "time"
        } else if iconImageView.frame.contains(touchLocation) || iconView.frame.contains(touchLocation) {
            clickedElement = "logo"
        }
    }
    
    override func setStyles() {
        super.setStyles()
        
        self.backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        
        bubbleView.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        bubbleView.layer.cornerRadius = 5
        
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        urlLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        
        titleLabel.textColor = UIColor(colorString: "333333")
        urlLabel.textColor = UIColor(colorString: "551A8B")
        timeLabel.textColor = UIColor(colorString: "aaaaaa")
        
        titleLabel.numberOfLines = 2
        urlLabel.numberOfLines = 1
        timeLabel.numberOfLines = 1
        
        timeLabel.textAlignment = .right
    }
    
    override func setConstraints() {
        super.setConstraints()
        
        iconImageView.snp.makeConstraints { (make) in
            make.top.equalTo(self.bubbleView)
            make.left.equalTo(bubbleView).offset(11)
            make.size.equalTo(32)
        }
        
        iconView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(self.iconImageView)
        }
        
        urlLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.bubbleView).offset(5)
            make.left.equalTo(iconImageView.snp.right).offset(10)
            make.right.equalTo(bubbleView).inset(44)
            make.height.equalTo(21)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.bubbleView).offset(10)
            make.right.equalTo(self.timeLabel.snp.left).offset(-5)
            make.top.equalTo(self.urlLabel.snp.bottom).offset(10)
            make.bottom.equalTo(self.bubbleView).offset(-10)
        }
        
        timeLabel.snp.makeConstraints { (make) in
            make.bottom.right.equalTo(bubbleView).inset(4)
            if (is24Hours) {
                make.width.equalTo(35)
            } else {
                make.width.equalTo(55)
            }
        }
    }
    
    func updateIconView(_ image: UIImage?, logoInfo: LogoInfo?) {
        
        if let image = image {
            iconImageView.image = image
            iconImageView.isHidden = false
            
        } else if let info = logoInfo {
            let view = LogoPlaceholder(logoInfo: info)
            iconView.addSubview(view)
            view.snp.makeConstraints({ (make) in
                make.top.left.bottom.right.equalTo(iconView)
            })
            iconView.isHidden = false
            
        } else {
            iconImageView.image = UIImage(named: "defaultFavicon")
            iconImageView.isHidden = false
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.isHidden = true
        iconView.isHidden = true
        iconView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    override func remakeConstraints() {
        super.remakeConstraints()
        setBubbleViewConstraints()
    }
    
    func setBubbleViewConstraints() {
        bubbleView.snp.remakeConstraints { (make) in
            make.top.equalTo(contentView).inset(7)
            make.bottom.equalTo(contentView).inset(7)
            make.left.equalTo(contentView).offset(20)
            make.width.equalTo(contentView.bounds.width * 0.75)
        }
    }
    
}
