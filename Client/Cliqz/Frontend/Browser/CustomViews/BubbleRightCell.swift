//
//  HistoryDetailsRightCell.swift
//  Client
//
//  Created by Tim Palade on 8/8/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class BubbleRightCell: BubbleCell {
    
    let bubbleView = UIView()
    let titleLabel = UILabel()
    let timeLabel  = UILabel()
    
    override func setupComponents() {
        super.setupComponents()
        
        bubbleView.addSubview(titleLabel)
        bubbleView.addSubview(timeLabel)
        bubbleContainerView.addSubview(bubbleView)
        
    }
    
    override func cellPressed(_ gestureRecognizer: UIGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: self.bubbleView)
        
        if titleLabel.frame.contains(touchLocation) {
            clickedElement = "title"
        } else if timeLabel.frame.contains(touchLocation) {
            clickedElement = "time"
        }
    }
    
    override func setStyles() {
        super.setStyles()
        
        self.backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        
        bubbleView.layer.cornerRadius = 5
        bubbleView.backgroundColor = UIColor(colorString: "c8e9ef")
        
        titleLabel.lineBreakMode = .byTruncatingTail
        
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        
        titleLabel.textColor = UIColor(colorString: "333333")
        timeLabel.textColor = UIColor(colorString: "aaaaaa")
        
        titleLabel.numberOfLines = 1
        timeLabel.numberOfLines = 1
        
        timeLabel.textAlignment = .right
        
    }
    
    override func setConstraints() {
        super.setConstraints()
        
        bubbleView.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView).inset(10)
            make.bottom.equalTo(self.contentView)
            make.right.equalTo(timeLabel.snp.right).offset(5)
            make.left.equalTo(titleLabel.snp.left).offset(-10)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView.snp.top).offset(15)
            make.right.equalTo(self.timeLabel.snp.left)
            make.width.lessThanOrEqualTo(self.contentView.frame.width * 0.65)
        }
        
        timeLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self.contentView).inset(30)
            make.bottom.equalTo(self.contentView).inset(5)
            if (is24Hours) {
                make.width.equalTo(35)
            } else {
                make.width.equalTo(55)
            }
        }
    }

    override func remakeConstraints() {
        titleLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.contentView.snp.top).offset(15)
            make.right.equalTo(self.timeLabel.snp.left)
            make.width.lessThanOrEqualTo(self.contentView.frame.width * 0.65)
        }
    }

}
