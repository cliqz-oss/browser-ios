//
//  BubbleLeftExpandedCell.swift
//  Client
//
//  Created by Mahmoud Adam on 11/7/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class BubbleLeftExpandedCell: BubbleLeftCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    override func setupComponents() {
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
