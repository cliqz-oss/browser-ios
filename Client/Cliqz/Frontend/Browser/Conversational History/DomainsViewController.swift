//
//  ConversationalHistory.swift
//  Client
//
//  Created by Sahakyan on 12/8/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import SnapKit
import Alamofire
import Shared

protocol DomainsProtocol: class{
    func numberOfCells() -> Int
    func urlLabelText(indexPath:IndexPath) -> String
    func titleLabelText(indexPath:IndexPath) -> String
    func timeLabelText(indexPath:IndexPath) -> String
    func baseUrl(indexPath:IndexPath) -> String
	// TODO: change the name, it isn't exactly an image
	func image(indexPath:IndexPath, completionBlock: @escaping (_ image: UIImage?, _ view: UIView?) -> Void)
    func shouldShowNotification(indexPath:IndexPath) -> Bool
    func notificationNumber(indexPath:IndexPath) -> Int
}

class DomainsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	var historyTableView: UITableView!
	let historyCellID = "DomainsCell"

    var dataSource: DomainsDataSource = DomainsDataSource()
    var first_appear:Bool = true
    
    let emptyStateLabel = UILabel()
    
    var didPressCell:(_ indexPath:IndexPath) -> () = { _ in }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        dataSource.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func viewDidLoad() {
		super.viewDidLoad()
		self.historyTableView = UITableView(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0), style: .plain)
		self.view.addSubview(self.historyTableView)
		self.historyTableView.snp.remakeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.view)
		}
		self.historyTableView.delegate = self
		self.historyTableView.dataSource = self
		self.historyTableView.register(DomainsCell.self, forCellReuseIdentifier: historyCellID)
		self.historyTableView.tableFooterView = UIView()
		self.historyTableView.separatorStyle = .singleLine
		self.historyTableView.separatorColor = UIColor.darkGray
        self.historyTableView.backgroundColor = UIColor.clear
        
        self.emptyStateLabel.text = NSLocalizedString("Your History will appear here", tableName: "Cliqz", comment: "Text for empty history state")
        self.emptyStateLabel.textColor = UIColor.init(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        self.view.addSubview(self.emptyStateLabel)
        self.emptyStateLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        self.updateEmptyStateLabel()
        
        NotificationCenter.default.addObserver(self, selector: #selector(newsReady), name: NewsManager.notification_updated, object: nil)
	}
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

	override func viewWillDisappear(_ animated: Bool) {
		self.navigationController?.isNavigationBarHidden = true
		super.viewWillDisappear(animated)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.isNavigationBarHidden = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfCells()
    }

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
		let cell =  self.historyTableView.dequeueReusableCell(withIdentifier: self.historyCellID) as! DomainsCell
		cell.delegate = self
        cell.tag = indexPath.row
        
        let articleLink = dataSource.urlLabelText(indexPath: indexPath)
        cell.URLLabel.text   = articleLink
        cell.titleLabel.text = dataSource.titleLabelText(indexPath: indexPath)
        self.dataSource.image(indexPath: indexPath) { (image, customView) in
			if cell.tag == indexPath.row {
				if let img = image {
					cell.logoButton.setImage(img)
				} else if let view = customView {
					cell.logoButton.setView(view)
				}
            }
        }

        if dataSource.shouldShowNotification(indexPath: indexPath) {
            cell.notificationView.isHidden = false
            cell.notificationView.numberLabel.text = String(dataSource.notificationNumber(indexPath: indexPath))
        }
        else{
            cell.notificationView.isHidden = true
        }

		cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		cell.accessoryType = .disclosureIndicator
		cell.selectionStyle = .none
		return cell
	}
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! DomainsCell
        didPressCell(indexPath)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
			self.dataSource.removeDomain(at: indexPath.row)
            // handle delete (by removing the data from your array and updating the tableview)
        }
    }
    
    @objc
    func newsReady(sender:NSNotification) {
//        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
//        self.historyTableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
    
    func updateEmptyStateLabel() {
        if self.dataSource.numberOfCells() > 0 {
            self.emptyStateLabel.isHidden = true
        }
        else {
            self.emptyStateLabel.isHidden = false
        }
    }
	
}

extension DomainsViewController: HistoryActionDelegate {
	func didSelectLogo(atIndex index: Int) {

	}
}

extension DomainsViewController: KeyboardHelperDelegate {
    
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        updateViewConstraints()
    }
    
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        updateViewConstraints()
    }
    
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
        
    }
	
}

extension DomainsViewController: HasDataSource {
    func dataSourceWasUpdated(identifier: String) {
        self.updateEmptyStateLabel()
        UIView.animate(withDuration: 0.2) { 
            self.historyTableView.reloadData()
            self.view.layoutIfNeeded()
        }
    }
}


