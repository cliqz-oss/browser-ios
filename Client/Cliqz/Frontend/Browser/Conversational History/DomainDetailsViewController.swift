//
//  ConversationalHistoryDetails.swift
//  Client
//
//  Created by Sahakyan on 12/8/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Alamofire
import QuartzCore

protocol DomainDetailsProtocol: class {
    func urlLabelText(indexPath: IndexPath) -> String
    func titleLabelText(indexPath: IndexPath) -> String
    func sectionTitle(section: Int) -> String
    func timeLabelText(indexPath: IndexPath) -> String
    func isQuery(indexPath: IndexPath) -> Bool
    func numberOfSections() -> Int
    func numberOfCells(section: Int) -> Int
    func image() -> UIImage?
    func isNews() -> Bool
    func baseUrl() -> String
}

// This is the View Controller for the Domain Details View (What you see after you press on a certain domain)

// Attention!!!!
// To Do: Take out the table view into a separate component

class DomainDetailsViewController: UIViewController {
	
	var historyTableView: BubbleTableView!
	var sortedURLs = [String]()
    let headerView = DomainDetailsHeaderView()
    let recommendationsCollection = RecommedationsCollectionView()
    
    var dataSource: DomainDetailsProtocol? = nil

	weak var delegate: BrowserNavigationDelegate?
	
	private var urls: NSArray!
    
    var didPressBack: () -> () = { _ in }

	override func viewDidLoad() {
		super.viewDidLoad()
        
        componentSetUp()
        
        self.view.addSubview(headerView)
        self.view.addSubview(recommendationsCollection)
		self.view.addSubview(historyTableView)
        
        setStyling()
        setConstraints()
	}
    
    func componentSetUp() {
        
        headerView.delegate = self
        headerView.logo.setImage(dataSource?.image() ?? UIImage(named: "coolLogo"), for: .normal)
        headerView.title.text = dataSource?.baseUrl() ?? "www.test.com"
        
        recommendationsCollection.recomDataSource = RecommendationsDataSource()
        
        self.historyTableView = BubbleTableView(customDataSource: self, customDelegate: self)
        
    }
    
    func setStyling() {
        self.view.backgroundColor = UIColor.clear
    }
    
    func setConstraints() {
        
        self.headerView.snp.remakeConstraints { (make) in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(64)
        }
        
        self.recommendationsCollection.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.headerView.snp.bottom)
            make.height.equalTo(204)
        }
        
        self.historyTableView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
            make.top.equalTo(self.recommendationsCollection.snp.bottom)
        }
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.isNavigationBarHidden = true
	}
	
	@objc private func logoPressed() {
		if let baseURL = dataSource?.baseUrl(), let url = NSURL(string: baseURL) {
            self.navigationController?.popViewController(animated: false)
			self.delegate?.navigateToURL(url as URL)
		}

	}
}

extension DomainDetailsViewController: BubbleTableViewDataSource {
    func numberOfSections() -> Int {
        return dataSource?.numberOfSections() ?? 0
    }
    
    func numberOfRows(section: Int) -> Int {
        return dataSource?.numberOfCells(section: section) ?? 0
    }
    
    func titleSectionHeader(section: Int) -> String {
        return dataSource?.sectionTitle(section:section) ?? ""
    }
    
    func title(indexPath: IndexPath) -> String {
        return dataSource?.titleLabelText(indexPath: indexPath) ?? ""
    }
    
    func url(indexPath: IndexPath) -> String {
        return dataSource?.urlLabelText(indexPath: indexPath) ?? ""
    }
    
    func time(indexPath: IndexPath) -> String {
        return dataSource?.timeLabelText(indexPath: indexPath) ?? ""
    }
    
    func useRightCell(indexPath: IndexPath) -> Bool {
        return dataSource?.isQuery(indexPath: indexPath) ?? false
    }
}

extension DomainDetailsViewController: BubbleTableViewDelegate {
    func cellPressed(indexPath: IndexPath) {
        
    }
}

extension DomainDetailsViewController: DomainDetailsHeaderViewDelegate {
    func headerLogoPressed() {
        
    }
    
    func headerGoBackPressed() {
        didPressBack()
    }
}

