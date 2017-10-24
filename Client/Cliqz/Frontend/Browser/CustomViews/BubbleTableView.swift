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
}

protocol BubbleTableViewDelegate {
    func cellPressed(indexPath: IndexPath)
    func deleteItem(at: IndexPath)
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
            cell.timeLabel.text  = customDataSource.time(indexPath: indexPath)
            cell.selectionStyle  = .none
            return cell
        }
        
        let cell =  self.dequeueReusableCell(withIdentifier: bubble_left_id) as! BubbleLeftCell
        cell.titleLabel.text = customDataSource.title(indexPath: indexPath)
//        cell.titleLabel.sizeToFit()
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
            return 70
        }
        
        return 90
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
//        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor(colorString: "666666")
        
        bubble.addSubview(label)
        container.addSubview(bubble)
        
        //styling
        bubble.backgroundColor = UIColor.white
        bubble.layer.cornerRadius = 5
        
        
        //constraints
        bubble.snp.makeConstraints { (make) in
            make.center.equalTo(container)
            make.width.equalTo(label.snp.width).multipliedBy(1.5)
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
        self.customDelegate?.cellPressed(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.customDelegate?.deleteItem(at: indexPath)
        }
    }
    
    @available (iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = self.contextualDeleteAction(forRowAtIndexPath: indexPath)
        let swipeConfig = UISwipeActionsConfiguration(actions: [deleteAction])
        return swipeConfig
    }
    
    @available (iOS 11.0, *)
    func contextualDeleteAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let deleteTitle = NSLocalizedString("Delete", tableName: "Cliqz", comment: "[History] delete button title")
        let action = UIContextualAction(style: .destructive, title: deleteTitle) { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
            self.customDelegate?.deleteItem(at: indexPath)
            completionHandler(true)
        }
        return action
    }
    
}
