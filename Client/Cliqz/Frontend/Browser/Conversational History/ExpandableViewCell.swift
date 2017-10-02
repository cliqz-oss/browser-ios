//
//  ExpandableViewCellTableViewCell.swift
//  DashboardComponent
//
//  Created by Tim Palade on 8/10/17.
//  Copyright © 2017 Tim Palade. All rights reserved.
//

import UIKit

class ExpandableViewCell: UITableViewCell {
    
    
    let titleLabel = UILabel()
    let URLLabel = UILabel()
    
    lazy var logoContainerView = UIView()
    let logoImageView = UIView()
    var fakeLogoView: UIView?
    
    let cardView = UIView()
    var clickedElement = ""
    
    //styling
    
    let cardViewLeftOffset = 0
    let cardViewRightOffset = -13
    let cardViewTopOffset = 0
    let cardViewBottomOffset = -5
    let contentOffset = 15
    let logoSize = CGSize(width: 48, height: 48)
    let URLLeftOffset = 15
    let URLHeight = 18
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setUpComponent()
        setStyling()
        setConstraints()
    }
    
    func setUpComponent() {
        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(URLLabel)
        cardView.addSubview(logoContainerView)
        
        // tab gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(newsPressed(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func setStyling() {
        
        self.contentView.backgroundColor = UIColor.white
        self.backgroundColor = UIColor.white
        
        cardView.backgroundColor = UIColor.clear
        cardView.layer.cornerRadius = 4
        
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
        titleLabel.textColor = .black
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.numberOfLines = 2
        
        URLLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
        URLLabel.textColor = UIColor.darkGray
        URLLabel.backgroundColor = UIColor.clear
        
        logoContainerView.addSubview(logoImageView)
        logoContainerView.layer.cornerRadius = 7
        logoContainerView.layer.masksToBounds = true
        logoContainerView.backgroundColor = UIColor.lightGray
        
    }
    
    func setConstraints() {
        
//        URLLabel.snp.makeConstraints { (make) in
//            make.top.equalTo(logoContainerView.snp.top)
//            make.left.equalTo(logoImageView.snp.right).offset(URLLeftOffset)
//            make.right.equalTo(cardView)
//        }
        
//        titleLabel.snp.remakeConstraints { (make) in
//            make.top.equalTo(URLLabel.snp.bottom).offset(2)
//            make.left.equalTo(logoImageView.snp.right).offset(URLLeftOffset)
//            make.right.equalTo(cardView).offset(-contentOffset)
//        }
        
        URLLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(titleLabel.snp.top)
            make.left.equalTo(logoImageView.snp.right).offset(URLLeftOffset)
            make.right.equalTo(cardView)
            make.height.equalTo(16)
        }
        
        titleLabel.snp.remakeConstraints { (make) in
            make.centerY.equalTo(logoContainerView.snp.centerY).offset(10)
            make.left.equalTo(logoImageView.snp.right).offset(URLLeftOffset)
            make.right.equalTo(cardView).offset(-contentOffset)
        }
        
        cardView.snp.makeConstraints { (make) in
            make.left.equalTo(contentView).offset(cardViewLeftOffset)
            make.right.equalTo(contentView).offset(cardViewRightOffset)
            make.top.equalTo(contentView).offset(cardViewTopOffset)
            make.bottom.equalTo(contentView).offset(cardViewBottomOffset)
        }
        
        logoContainerView.snp.makeConstraints { make in
            make.centerY.equalTo(cardView)
            make.left.equalTo(cardView).offset(10)
            make.size.equalTo(logoSize)
        }
        
        logoImageView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalTo(logoContainerView)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func newsPressed(_ gestureRecognizer: UIGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: self.cardView)
        
        if titleLabel.frame.contains(touchLocation) {
            clickedElement = "title"
        } else if URLLabel.frame.contains(touchLocation) {
            clickedElement = "url"
        } else if logoContainerView.frame.contains(touchLocation) {
            clickedElement = "logo"
        }
    }
    
    override func prepareForReuse() {
        self.cardView.transform = CGAffineTransform.identity
        self.cardView.alpha = 1
		for v in self.logoImageView.subviews {
			v.removeFromSuperview()
		}
        self.fakeLogoView?.removeFromSuperview()
        self.fakeLogoView = nil
        clickedElement = ""
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        
    }

	func setLogoImage(_ image: UIImage) {
		let imgView = UIImageView(image: image)
		self.logoImageView.addSubview(imgView)
		imgView.snp.makeConstraints { (make) in
			make.edges.equalTo(self.logoImageView)
		}
	}

	func setCustomLogo(_ customView: UIView) {
		self.logoImageView.addSubview(customView)
		customView.snp.makeConstraints { (make) in
			make.edges.equalTo(self.logoImageView)
		}
	}
}
