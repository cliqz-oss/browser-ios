//
//  HistoryDetailsRightCell.swift
//  Client
//
//  Created by Tim Palade on 8/8/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class BubbleRightCell: UITableViewCell {
    
    let titleLabel = UILabel()
    let timeLabel  = UILabel()
    
    private let bubbleView = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupComponents()
        
        bubbleView.addSubview(titleLabel)
        bubbleView.addSubview(timeLabel)
        contentView.addSubview(bubbleView)
        
        setStyles()
        setConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupComponents() {
        
    }
    
    func setStyles() {
        
        self.backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        
        bubbleView.layer.cornerRadius = 10
        bubbleView.backgroundColor = UIColor(colorString: "00B3EF")
        
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        
        titleLabel.textColor = UIColor.white
        timeLabel.textColor = UIColor.white
        
        titleLabel.numberOfLines = 2
        timeLabel.numberOfLines = 1
        
    }
    
    func setConstraints() {
        bubbleView.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView).inset(10)
            make.bottom.equalTo(self.contentView)
            make.right.equalTo(self.contentView).inset(20)
            make.width.equalTo(self.contentView.bounds.width * 0.7)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.bubbleView.snp.centerY).offset(9)
            make.left.equalTo(self.bubbleView).offset(10)
            make.right.equalTo(self.bubbleView).inset(10)
        }
        
        timeLabel.snp.makeConstraints { (make) in
            make.bottom.right.equalTo(self.bubbleView).inset(4)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
