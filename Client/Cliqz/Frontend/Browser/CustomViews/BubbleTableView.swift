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
    func url(indexPath: IndexPath) -> URL?
    func time(indexPath: IndexPath) -> String
    func logo(indexPath: IndexPath, completionBlock: @escaping (_ url: URL, _ image: UIImage?, _ logoInfo: LogoInfo?) -> Void)
    func useRightCell(indexPath: IndexPath) -> Bool //default is left cell
    func useLeftExpandedCell() -> Bool //default is left cell
    func isEmpty() -> Bool
    func accessibilityLabel(indexPath: IndexPath) -> String
}

protocol BubbleTableViewDelegate {
    func cellPressed(indexPath: IndexPath, clickedElement: String)
    func deleteItem(at: IndexPath, direction: SwipeDirection, completion: (() -> Void )?)
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
    let bubble_left_expanded_id = "BubbleLeftExpandedCell"
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
        self.register(BubbleLeftExpandedCell.self, forCellReuseIdentifier: bubble_left_expanded_id)
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
            cell.timeLabel.text  = customDataSource.time(indexPath: indexPath)
            cell.accessibilityLabel = customDataSource.accessibilityLabel(indexPath: indexPath)
            cell.selectionStyle  = .none
            cell.swipeDelegate = self
            return cell
        }
        var cell =  self.dequeueReusableCell(withIdentifier: bubble_left_id) as! BubbleLeftCell
        if customDataSource.useLeftExpandedCell() == true {
            cell =  self.dequeueReusableCell(withIdentifier: bubble_left_expanded_id) as! BubbleLeftExpandedCell
        }
        
        cell.swipeDelegate = self
        cell.accessibilityLabel = customDataSource.accessibilityLabel(indexPath: indexPath)
        cell.titleLabel.text = customDataSource.title(indexPath: indexPath)
        cell.timeLabel.text = customDataSource.time(indexPath: indexPath)
        
        let cellUrl = customDataSource.url(indexPath: indexPath)
        cell.urlLabel.text  = cellUrl?.host?.replace("www.", replacement: "")
        customDataSource.logo(indexPath: indexPath) { (url, image, logoInfo) in
            // as this block is called asynchronously, we want to make sure that we are rendering the same cell not another cell (user might scroll before the call back is called)
            if url == cellUrl {
                cell.updateIconView(image, logoInfo: logoInfo)
            }
        }
        cell.selectionStyle = .none
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if customDataSource.useRightCell(indexPath: indexPath) == true {
            return 45
        }
        
        return 100
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if customDataSource.useLeftExpandedCell() == true {
            return 0
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == customDataSource.numberOfSections() - 1 {
            return 30
        }
        return 0
        
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == customDataSource.numberOfSections() - 1 {
            return UIView()
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let container = UIView()
        let bubble = UIView()
        let label = UILabel()
        
        //setup
        label.text = customDataSource.titleSectionHeader(section: section)
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.white
        
        bubble.addSubview(label)
        container.addSubview(bubble)
        container.accessibilityIdentifier = "date"
        
        //styling
        bubble.backgroundColor = UIConstants.CliqzThemeColor
        bubble.layer.cornerRadius = 5
        
        
        //constraints
        bubble.snp.makeConstraints { (make) in
            make.center.equalTo(container)
            make.width.equalTo(label.snp.width).multipliedBy(1.2)
            make.height.equalTo(27)
        }
        
        label.snp.makeConstraints { (make) in
            make.center.equalTo(bubble)
        }
        
        
        return container
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        //To Do: Create a delegate
        if let currentCell = tableView.cellForRow(at: indexPath) as? ClickableUITableViewCell {
            self.customDelegate?.cellPressed(indexPath: indexPath, clickedElement: currentCell.clickedElement)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension BubbleTableView : CustomScrollDelegate {
    
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

extension BubbleTableView : BubbleCellSwipeDelegate {
    func didSwipe(atCell cell: UITableViewCell, direction: SwipeDirection) {
        if let indexPath = self.indexPath(for: cell){
            let oldSectionsCount = self.customDataSource.numberOfSections()
            self.customDelegate?.deleteItem(at: indexPath, direction: direction, completion: { [weak self] in
                DispatchQueue.main.async {
                    if let newSectionsCount = self?.customDataSource.numberOfSections() {
                        if oldSectionsCount > newSectionsCount {
                            self?.deleteSections(IndexSet([indexPath.section]), with: .none)
                        } else {
                            self?.deleteRows(at: [indexPath], with: .none)
                        }
                    }
                }
            })
        }
    }
}
