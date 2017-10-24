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
    
    init(profile: Profile) {
        super.init(nibName: nil, bundle: nil)
        
        tableViewDataSource = createDataSource(profile)
        tableViewDataSource.delegate = self

        historyTableView = BubbleTableView(customDataSource: tableViewDataSource, customDelegate: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createDataSource(_ profile: Profile) -> HistoryDataSource {
        return HistoryDataSource(profile: profile)
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
                self?.scrollToBottom()
            }
        })
    }
    
    private func componentSetUp() {
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
    func cellPressed(indexPath: IndexPath) {
        if tableViewDataSource.useRightCell(indexPath: indexPath) {
            let query = tableViewDataSource.title(indexPath: indexPath)
            self.delegate?.didSelectQuery(query)
        } else if let url = tableViewDataSource.url(indexPath: indexPath) {
            self.delegate?.didSelectURL(url)
        }
    }
    
    func deleteItem(at indexPath: IndexPath) {
        tableViewDataSource.deleteItem(at: indexPath)
    }
}


extension HistoryViewController: HasDataSource {
    func dataSourceWasUpdated() {
        DispatchQueue.main.async { [weak self] in
            self?.historyTableView.reloadData()
        }
    }
}

