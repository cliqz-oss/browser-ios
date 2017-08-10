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

protocol HistoryDetailsProtocol: class {
    func urlLabelText(indexPath: IndexPath) -> String
    func titleLabelText(indexPath: IndexPath) -> String
    func sectionTitle(section: Int) -> String
    func timeLabelText(indexPath: IndexPath) -> String
    func isQuery(indexPath: IndexPath) -> Bool
    func numberOfSections() -> Int
    func numberOfCells() -> Int
    func image() -> UIImage?
    func isNews() -> Bool
    func baseUrl() -> String
}

// This is the View Controller for the Domain Details View (What you see after you press on a certain domain)

// Attention!!!!
// To Do: Take out the table view into a separate component

class ConversationalHistoryDetails: UIViewController {
	
	var historyTableView: UITableView!
	let historyCellID_Left = "HistoryCellLeft"
    let historyCellID_Right = "HistoryCellRight"
	var sortedURLs = [String]()
    var dataSource: HistoryDetailsProtocol? = nil
    let headerView = DetailHeaderView()
    let recommendationsCollection = RecommedationsCollectionView()

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
        
        //this will have to be moved to the table view controller.
        //when I make it a separate class.
        if dataSource?.numberOfCells() == 0 {
            historyTableView.isHidden = true
        }
	}
    
    func componentSetUp() {
        
        headerView.delegate = self
        headerView.logo.setImage(dataSource?.image() ?? UIImage(named: "coolLogo"), for: .normal)
        headerView.title.text = dataSource?.baseUrl() ?? "www.test.com"
        
        recommendationsCollection.recomDataSource = RecommendationsDataSource()
        
        self.historyTableView = UITableView(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0), style: .plain)
        self.historyTableView.delegate = self
        self.historyTableView.dataSource = self
        self.historyTableView.register(HistoryDetailsLeftCell.self, forCellReuseIdentifier: historyCellID_Left)
        self.historyTableView.register(HistoryDetailsRightCell.self, forCellReuseIdentifier: historyCellID_Right)
    }
    
    func setStyling() {
        
        self.view.backgroundColor = UIColor.clear
        
        self.historyTableView.separatorStyle = .none
        self.historyTableView.backgroundColor = UIColor.clear
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

extension ConversationalHistoryDetails: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.numberOfCells() ?? 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource?.numberOfSections() ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if dataSource?.isQuery(indexPath: indexPath) == true {
            let cell =  self.historyTableView.dequeueReusableCell(withIdentifier: self.historyCellID_Right) as! HistoryDetailsRightCell
            cell.titleLabel.text = dataSource?.titleLabelText(indexPath: indexPath)
            cell.timeLabel.text = dataSource?.timeLabelText(indexPath: indexPath)
            return cell
        }
        
        let cell =  self.historyTableView.dequeueReusableCell(withIdentifier: self.historyCellID_Left) as! HistoryDetailsLeftCell
        cell.titleLabel.text = dataSource?.titleLabelText(indexPath: indexPath)
        cell.urlLabel.text = dataSource?.urlLabelText(indexPath: indexPath)
        cell.timeLabel.text = dataSource?.timeLabelText(indexPath: indexPath)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if dataSource?.isQuery(indexPath: indexPath) == true {
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
        label.text = dataSource?.sectionTitle(section: section)
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
        if let urlString = dataSource?.urlLabelText(indexPath: indexPath), let url = NSURL(string: urlString) {
            ReadNewsManager.sharedInstance.markAsRead(articleLink: urlString)
            self.navigationController?.popViewController(animated: false)
            self.delegate?.navigateToURL(url as URL)
        }
    }
    
}

extension ConversationalHistoryDetails: DetailHeaderViewDelegate {
    func headerLogoPressed() {
        
    }
    
    func headerGoBackPressed() {
        didPressBack()
    }
}

protocol DetailHeaderViewDelegate {
    func headerGoBackPressed()
    func headerLogoPressed()
}

class DetailHeaderView: UIView {
    
    let backBtn = UIButton(type: .custom)
    let title = UILabel()
    let logo = UIButton(type: .custom)
    let sep = UIView()
    
    var delegate: DetailHeaderViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        componentSetUp()
        
        self.addSubview(backBtn)
        self.addSubview(title)
        self.addSubview(logo)
        self.addSubview(sep)
        
        setConstraints()
        setStyling()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func componentSetUp() {
        backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        logo.addTarget(self, action: #selector(logoPressed), for: .touchUpInside)
    }
    
    func setConstraints() {
        
        backBtn.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self)
            make.left.equalTo(self)
            make.height.width.equalTo(40)
        }
        
        logo.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self)
            make.top.equalTo(self).offset(6)
            make.width.equalTo(38)
            make.height.equalTo(38)
        }
        
        title.snp.remakeConstraints { (make) in
            make.top.equalTo(logo.snp.bottom)
            make.left.right.equalTo(self)
            make.height.equalTo(20)
        }
        
        sep.snp.remakeConstraints { (make) in
            make.bottom.equalTo(self)
            make.left.right.equalTo(self)
            make.height.equalTo(1)
        }
    }
    
    func setStyling() {
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        backBtn.tintColor = UIColor.white
        backBtn.setImage(UIImage(named:"cliqzBackWhite"), for: .normal)
        
        title.textAlignment = .center
        title.numberOfLines = 0
        title.font = UIFont.boldSystemFont(ofSize: 10)
        title.textColor = UIColor(colorString: "F8F8F8")
        
        logo.layer.cornerRadius = 4
        logo.clipsToBounds = true
        
        sep.backgroundColor = UIColor.clear
    }
    
    @objc
    func goBack(_ sender: UIButton) {
        self.delegate?.headerGoBackPressed()
    }
    
    @objc
    func logoPressed(_ sender: UIButton) {
        self.delegate?.headerLogoPressed()
    }
    
}
