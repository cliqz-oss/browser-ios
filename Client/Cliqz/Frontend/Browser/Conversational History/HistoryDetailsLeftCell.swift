//
//  HistoryDetailsLeftCell.swift
//  Client
//
//  Created by Tim Palade on 8/8/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class HistoryDetailsLeftCell: UITableViewCell {

    let titleLabel = UILabel()
    let urlLabel = UILabel()
    let timeLabel = UILabel()
    
    private let bubbleView = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupComponents()
        
        bubbleView.addSubview(titleLabel)
        bubbleView.addSubview(urlLabel)
        bubbleView.addSubview(timeLabel)
        contentView.addSubview(bubbleView)
        
        setStyles()
        setConstraints()
        
    }
    
    func setupComponents() {
        
    }
    
    func setStyles() {
        
        self.backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        
        bubbleView.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        bubbleView.layer.cornerRadius = 10
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        urlLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        
        urlLabel.textColor = UIColor.lightGray
        timeLabel.textColor = UIColor.lightGray
        
        titleLabel.numberOfLines = 2
        urlLabel.numberOfLines = 1
        timeLabel.numberOfLines = 1
    }
    
    func setConstraints() {
        bubbleView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView).inset(10)
            make.bottom.equalTo(contentView)
            make.left.equalTo(contentView).offset(20)
            make.width.equalTo(contentView.bounds.width * 0.94)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.bubbleView).offset(10)
            make.right.equalTo(self.bubbleView).inset(20)
            make.bottom.equalTo(self.bubbleView.snp.centerY)
        }
        
        urlLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.bubbleView.snp.centerY).offset(6)
            make.left.equalTo(bubbleView).offset(10)
            make.right.equalTo(bubbleView).inset(44)
        }
        
        timeLabel.snp.makeConstraints { (make) in
            make.bottom.right.equalTo(bubbleView).inset(4)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
