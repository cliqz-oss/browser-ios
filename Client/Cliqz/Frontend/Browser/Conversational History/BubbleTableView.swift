//
//  BubbleTableView.swift
//  Client
//
//  Created by Tim Palade on 8/14/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

protocol BubbleTableViewDataSource {
    func numberOfSections() -> Int
    func numberOfRows(section: Int) -> Int
    func titleSectionHeader(section: Int) -> String
    func title(indexPath: IndexPath) -> String
    func url(indexPath: IndexPath) -> String
    func time(indexPath: IndexPath) -> String
    func useRightCell(indexPath: IndexPath) -> Bool //default is left cell
}

protocol BubbleTableViewDelegate {
    func cellPressed(indexPath: IndexPath)
}

protocol CustomScrollDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
}

class BubbleTableView: UITableView {
    
    let bubble_left_id = "BubbleLeftCell"
    let bubble_right_id = "BubbleRightCell"
    
    let customDataSource: BubbleTableViewDataSource
    let customDelegate: BubbleTableViewDelegate?
    
    var scrollViewDelegate: CustomScrollDelegate? = nil
    
    init(frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0), style: UITableViewStyle = .plain, customDataSource: BubbleTableViewDataSource, customDelegate: BubbleTableViewDelegate? = nil) {
        self.customDataSource = customDataSource
        self.customDelegate = customDelegate
        super.init(frame: frame, style: style)
        componentSetUp()
        setStyling()
        setConstraints()
    }
    
    func componentSetUp() {
        self.delegate = self
        self.dataSource = self
        self.register(BubbleLeftCell.self, forCellReuseIdentifier: bubble_left_id)
        self.register(BubbleRightCell.self, forCellReuseIdentifier: bubble_right_id)
    }
    
    func setStyling() {
        self.separatorStyle = .none
        self.backgroundColor = UIColor.clear
    }
    
    func setConstraints() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension BubbleTableView: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return customDataSource.numberOfRows(section: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if customDataSource.numberOfSections() == 0 {
            self.isHidden = true
        }
        else {
            self.isHidden = false
        }
        
        return customDataSource.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if customDataSource.useRightCell(indexPath: indexPath) == true {
            let cell =  self.dequeueReusableCell(withIdentifier: bubble_right_id) as! BubbleRightCell
            cell.titleLabel.text = customDataSource.title(indexPath: indexPath)
            cell.timeLabel.text = customDataSource.time(indexPath: indexPath)
            return cell
        }
        
        let cell =  self.dequeueReusableCell(withIdentifier: bubble_left_id) as! BubbleLeftCell
        cell.titleLabel.text = customDataSource.title(indexPath: indexPath)
        cell.urlLabel.text = customDataSource.url(indexPath: indexPath)
        cell.timeLabel.text = customDataSource.time(indexPath: indexPath)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if customDataSource.useRightCell(indexPath: indexPath) == true {
            return 70
        }
        
        return 90
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let container = UIView()
        let bubble = UIView()
        let label = UILabel()
        
        //setup
        label.text = customDataSource.titleSectionHeader(section: section)
        label.font = UIFont.boldSystemFont(ofSize: 14)
        
        bubble.addSubview(label)
        container.addSubview(bubble)
        
        //styling
        bubble.backgroundColor = UIColor.white
        bubble.layer.cornerRadius = 10
        
        
        //constraints
        bubble.snp.makeConstraints { (make) in
            make.center.equalTo(container)
            make.width.equalTo(label.snp.width).multipliedBy(1.5)
            make.height.equalTo(20)
        }
        
        label.snp.makeConstraints { (make) in
            make.center.equalTo(bubble)
        }
        
        
        return container
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        //To Do: Create a delegate
        self.customDelegate?.cellPressed(indexPath: indexPath)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewDelegate?.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewDelegate?.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
}
