//
//  BubbleLeftExpandedCell.swift
//  Client
//
//  Created by Mahmoud Adam on 11/7/17.
//  Copyright © 2017 Cliqz. All rights reserved.
//

import UIKit

class BubbleLeftExpandedCell: BubbleLeftCell {

    override func setStyles() {
        super.setStyles()
        urlLabel.textColor = UIColor(colorString: "4A90E2")
    }
    
    override func setupComponents() {
        super.setupComponents()
        timeLabel.isHidden = true
    }
    
    override func setBubbleViewConstraints() {
        bubbleView.snp.remakeConstraints { (make) in
            make.top.equalTo(contentView).inset(7)
            make.bottom.equalTo(contentView).inset(7)
            make.left.equalTo(contentView).offset(20)
            make.right.equalTo(contentView).inset(20)
        }
    }
}
