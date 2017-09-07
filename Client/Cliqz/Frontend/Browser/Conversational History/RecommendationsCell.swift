//
//  RecommendationsCell.swift
//  Client
//
//  Created by Tim Palade on 8/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

protocol RecommendationsCellDelegate {
    func deletePressed(indexPath: IndexPath)
}

class RecommendationsCell: UICollectionViewCell {
    
    class CustomHeaderView: UIView {
        
        let roundedView = UIView()
        let coverView = UIView()
        
        let bgColor: UIColor
        let radius: CGFloat
        
        init(frame: CGRect, cornerRadius: CGFloat, color: UIColor) {
            bgColor = color
            radius = cornerRadius
            super.init(frame: frame)
            setUpComponents()
            setStyling()
            setConstraints()
        }
        
        func setUpComponents() {
            self.addSubview(roundedView)
            self.addSubview(coverView)
        }
        
        func setStyling() {
            
            self.backgroundColor = .clear
            
            roundedView.layer.cornerRadius = radius
            roundedView.backgroundColor = bgColor
            
            coverView.backgroundColor = bgColor
        }
        
        func setConstraints() {
            roundedView.snp.makeConstraints { (make) in
                make.left.right.top.bottom.equalTo(self)
            }
            
            coverView.snp.makeConstraints { (make) in
                make.bottom.left.right.equalTo(self)
                make.height.equalTo(radius)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class CustomDeleteButton: UIButton {
        var indexPath: IndexPath = []
    }
    
    let textLabel = UILabel()
    let timeLabel = UILabel()
    let headerLabel = UILabel()
    let pictureView = UIImageView()
    let headerView: CustomHeaderView
    let cellTypeImageView = UIImageView()
    let circle = UIView()
    let backView = UIView()
    let deleteButton = CustomDeleteButton()
    
    let container = UIView()
    let containerTop = UIView()
    let containerBottom = UIView()
    
    var cellType: RecommendationsCellType = .Reminder //default
    
    var delegate: RecommendationsCellDelegate? = nil
    
    
    //styling
    
    let headerHeight: CGFloat = 30.0
    let cornerRadius: CGFloat = 10.0
    let customRed = UIColor(colorString: "EF372E")
    let circleRadius: CGFloat = 40.0
    
    override init(frame: CGRect) {
        headerView = CustomHeaderView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), cornerRadius: cornerRadius, color: customRed)
        super.init(frame: frame)
        setUpComponents()
        setStyling()
        setConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpComponents() {
        headerView.addSubview(headerLabel)
        containerTop.addSubview(pictureView)
        containerTop.addSubview(timeLabel)
        containerBottom.addSubview(textLabel)
        container.addSubview(containerTop)
        container.addSubview(containerBottom)
        backView.addSubview(headerView)
        backView.addSubview(container)
        contentView.addSubview(backView)
        circle.addSubview(cellTypeImageView)
        contentView.addSubview(circle)
        contentView.addSubview(deleteButton)
        
        deleteButton.addTarget(self, action: #selector(deletePressed), for: .touchUpInside)
    }
    
    func setStyling() {
        
        self.backgroundColor = .clear
        contentView.backgroundColor = .clear
        container.backgroundColor = .clear
        containerTop.backgroundColor = .clear
        containerBottom.backgroundColor = .clear
        pictureView.backgroundColor = .clear
        backView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        circle.backgroundColor = customRed
        cellTypeImageView.backgroundColor = .clear
        deleteButton.backgroundColor = .clear
        
        backView.layer.cornerRadius = cornerRadius
        circle.layer.cornerRadius = circleRadius / 2.0
        circle.layer.shadowColor = UIColor.black.cgColor
        circle.layer.shadowOffset = CGSize(width: 0, height: 2)
        circle.layer.shadowRadius = 4
        circle.layer.shadowOpacity = 0.4
        
        cellTypeImageView.clipsToBounds = true
        cellTypeImageView.contentMode = .center
        
        deleteButton.setImage(UIImage(named: "whiteTabClose"), for: .normal)
        
        headerLabel.textAlignment = .center
        headerLabel.font = UIFont.systemFont(ofSize: 15, weight: 100)
        headerLabel.textColor = .white
        
        timeLabel.textColor = .white
        timeLabel.font = UIFont.boldSystemFont(ofSize: 44)
        
        textLabel.numberOfLines = 4
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 12)
        textLabel.textAlignment = .left
        
        pictureView.clipsToBounds = true
        pictureView.contentMode = .scaleAspectFill
        
    }
    
    func setConstraints() {
        
        backView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(contentView)
            make.top.equalTo(contentView).inset(20)
        }
        
        headerView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(backView)
            make.height.equalTo(headerHeight)
        }
        
        headerLabel.snp.makeConstraints { (make) in
            make.left.equalTo(circle.snp.right)
            make.right.equalTo(deleteButton.snp.left)
            make.centerY.equalTo(headerView)
        }
        
        deleteButton.snp.makeConstraints { (make) in
            make.width.equalTo(headerHeight)
            make.right.equalTo(headerView)
            make.bottom.top.equalTo(headerView)
        }
        
        circle.snp.makeConstraints { (make) in
            make.height.width.equalTo(circleRadius)
            make.top.equalTo(contentView)
            make.left.equalTo(headerView).offset(6)
        }
        
        cellTypeImageView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(circle)
        }
        
        container.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
        }
        
        containerTop.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(container.snp.centerY)
        }
        
        containerBottom.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(containerTop.snp.bottom)
        }
        
        timeLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        pictureView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        textLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().inset(4)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(2)
        }
    }
    
    @objc
    func deletePressed(_ sender: CustomDeleteButton) {
        self.delegate?.deletePressed(indexPath: sender.indexPath)
    }
    
    func updateState(indexPath: IndexPath) {
        
        deleteButton.indexPath = indexPath
        
        if cellType == .Reminder {
            cellTypeImageView.image = UIImage(named: "whiteBell")
        }
        else {
            cellTypeImageView.image = UIImage(named: "filledStar")
        }
        
    }
    
}

