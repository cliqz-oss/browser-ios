//
//  HistoryViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 11/25/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import UIKit
import Shared


protocol HasDataSource: class {
    func dataSourceWasUpdated()
}

class HistoryViewController: UIViewController {

    weak var delegate: BrowsingDelegate?
    var historyTableView: BubbleTableView!
    var tableViewDataSource: HistoryDataSource!
    var emptyHistroyLabel = UILabel()
    fileprivate var lastContentOffset = CGPoint(x: 0, y: 0)
    
    init(profile: Profile) {
        super.init(nibName: nil, bundle: nil)
        
        tableViewDataSource = createDataSource(profile)
        tableViewDataSource.delegate = self

        historyTableView = BubbleTableView(customDataSource: tableViewDataSource, customDelegate: self)
        historyTableView.scrollViewDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createDataSource(_ profile: Profile) -> HistoryDataSource {
        return HistoryDataSource(profile: profile)
    }
    
    func emptyViewText() -> String {
        return NSLocalizedString("Here you will find your history.\n\n\nYou haven't searched or visited any website so far.", tableName: "Cliqz", comment: "[History] Text for empty history")
    }
    
    func getViewName() -> String {
        return "history"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        componentSetUp()
        setStyling()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setConstraints()
        self.tableViewDataSource.reloadHistory(completion: { [weak self] in
            DispatchQueue.main.async {
                self?.dataSourceWasUpdated()
                self?.historyTableView.reloadData()
                self?.scrollToBottom()
            }
        })
    }
    
    private func componentSetUp() {
        emptyHistroyLabel.text = emptyViewText()
        emptyHistroyLabel.textAlignment = .center
        emptyHistroyLabel.numberOfLines = 0
        emptyHistroyLabel.isHidden = true
        emptyHistroyLabel.textColor = UIColor(colorString: "AAAAAA")
        self.view.addSubview(emptyHistroyLabel)
        
        self.view.addSubview(historyTableView)
    }
    
    private func setStyling() {
        self.view.backgroundColor = UIConstants.AppBackgroundColor
        historyTableView.backgroundColor = UIColor.clear
    }
    
    private func setConstraints() {
        self.historyTableView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(self.view)
        }
        self.emptyHistroyLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.view).inset(25)
            make.top.equalTo(self.view).inset(45)
        }
    }
    
    private func scrollToBottom() {
        guard self.tableViewDataSource.numberOfSections() > 0 else { return }
        
        let lastSection = self.tableViewDataSource.numberOfSections() - 1
        let lastRow = self.tableViewDataSource.numberOfRows(section: lastSection) - 1
        let lastIndexPath = IndexPath(row: lastRow, section: lastSection)
        self.historyTableView.scrollToRow(at: lastIndexPath, at: .top, animated: false)
    }

}

extension HistoryViewController: BubbleTableViewDelegate {
    func cellPressed(indexPath: IndexPath, clickedElement: String) {
        
        if tableViewDataSource.useRightCell(indexPath: indexPath) {
            let query = tableViewDataSource.title(indexPath: indexPath)
            self.delegate?.didSelectQuery(query)
            TelemetryLogger.sharedInstance.logEvent(.DashBoard(getViewName(), "click", "query", ["element" : clickedElement]))
        } else if let url = tableViewDataSource.url(indexPath: indexPath) {
            self.delegate?.didSelectURL(url)
            TelemetryLogger.sharedInstance.logEvent(.DashBoard(getViewName(), "click", "site", ["element" : clickedElement]))
        }
    }
    
    func deleteItem(at indexPath: IndexPath, direction: SwipeDirection, completion: (() -> Void )?) {
        tableViewDataSource.deleteItem(at: indexPath, completion: completion)
        
        let target = tableViewDataSource.useRightCell(indexPath: indexPath) ? "query" : "site"
        let action = direction == .Right ? "swipe_right" : "swipe_left"
        TelemetryLogger.sharedInstance.logEvent(.DashBoard(getViewName(), action, target, nil))
    }
}

extension HistoryViewController: HasDataSource {
    func dataSourceWasUpdated() {
        if let isEmpty = self.tableViewDataSource?.isEmpty(), isEmpty == true {
            self.emptyHistroyLabel.isHidden = false
            self.historyTableView.isHidden = true
        } else {
            self.emptyHistroyLabel.isHidden = true
            self.historyTableView.isHidden = false
        }
    }
}

extension HistoryViewController : CustomScrollDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y < lastContentOffset.y ) {
            TelemetryLogger.sharedInstance.logEvent(.DashBoard(getViewName(), "scroll_up", nil, nil))
        } else if (scrollView.contentOffset.y > lastContentOffset.y) {
            TelemetryLogger.sharedInstance.logEvent(.DashBoard(getViewName(), "scroll_down", nil, nil))
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {

    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastContentOffset = scrollView.contentOffset;
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

    }
}
