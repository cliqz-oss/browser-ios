//
//  HistoryCell.swift
//  Client
//
//  Created by Tim Palade on 8/8/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

protocol HistoryActionDelegate: class {
    func didSelectLogo(atIndex index: Int)
}

class DomainsCell: UITableViewCell {
    
    let titleLabel = UILabel()
    let URLLabel = UILabel()
    let logoButton = CustomButton()
    let defaultImage = UIImage.fromColor(color: UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1), size: CGSize(width: 60, height: 60))
    
    let notificationView: CellNotificationView
    let notificationHeight: CGFloat = CGFloat(21)
    
    weak var delegate: HistoryActionDelegate?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        
        notificationView = CellNotificationView(frame: CGRect(x: 0, y: 0, width: notificationHeight, height: notificationHeight))
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
        titleLabel.textColor = UIColor.lightGray
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textAlignment = .left
        self.contentView.addSubview(URLLabel)
        URLLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)
        URLLabel.textColor = UIColor.white
        URLLabel.backgroundColor = UIColor.clear
        URLLabel.textAlignment = .left
        self.contentView.addSubview(logoButton)
        logoButton.layer.cornerRadius = 6
        logoButton.clipsToBounds = true
		self.logoButton.action = logoPressed
        logoButton.setImage(defaultImage)
        self.contentView.addSubview(notificationView)
        
        
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.logoButton.setImage(defaultImage)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.logoButton.snp.remakeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(10)
            make.centerY.equalTo(self.contentView)
            make.width.equalTo(50)
            make.height.equalTo(50)
        }
        self.URLLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.contentView).offset(15)
            make.left.equalTo(self.logoButton.snp.right).offset(15)
            make.height.equalTo(20)
            make.right.equalTo(self.contentView).offset(40)
        }
        self.titleLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.URLLabel.snp.bottom).offset(5)
            make.left.equalTo(self.URLLabel.snp.left)
            make.height.equalTo(20)
            make.right.equalTo(self.contentView).offset(40)
        }
        self.notificationView.snp.remakeConstraints { (make) in
            make.width.height.equalTo(notificationHeight)
            make.centerY.equalTo(self.contentView)
            make.right.equalTo(self.contentView).inset(12)
        }
    }
    
    @objc private func logoPressed() {
        self.delegate?.didSelectLogo(atIndex: self.tag)
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

class CellNotificationView: UIView {
    
    let numberLabel: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit(){
        let bounds = self.bounds
        self.layer.cornerRadius = min(bounds.width/2, bounds.height/2)
        self.backgroundColor = UIColor(colorString: "4FACED")
        self.clipsToBounds = true
        self.addSubview(numberLabel)
        numberLabel.frame = bounds
        numberLabel.text = "0"
        numberLabel.textColor = UIColor.white
        numberLabel.textAlignment = .center
        numberLabel.font = UIFont.systemFont(ofSize: 14)
    }
}

