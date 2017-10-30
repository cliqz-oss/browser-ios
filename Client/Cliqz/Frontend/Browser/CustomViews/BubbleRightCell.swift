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
    
    func setConstraints() {
        bubbleView.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView).inset(10)
            make.bottom.equalTo(self.contentView)
            make.right.equalTo(timeLabel.snp.right).offset(5)
            make.left.equalTo(titleLabel.snp.left).offset(-10)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView.snp.top).offset(15)
            make.right.equalTo(self.timeLabel.snp.left).inset(10)
            make.width.lessThanOrEqualTo(self.contentView.frame.width * 0.65)
        }
        
        timeLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self.contentView).inset(30)
            make.bottom.equalTo(self.contentView).inset(5)
            make.width.equalTo(45)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.remakeConstraints()
    }
    
    func remakeConstraints() {
        titleLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.contentView.snp.top).offset(15)
            make.right.equalTo(self.timeLabel.snp.left).inset(10)
            make.width.lessThanOrEqualTo(self.contentView.frame.width * 0.65)
        }
    }

}
