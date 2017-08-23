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
    func image(indexPath:IndexPath, completionBlock: @escaping (_ result:UIImage?) -> Void)
    func shouldShowNotification(indexPath:IndexPath) -> Bool
    func notificationNumber(indexPath:IndexPath) -> Int
}

class DomainsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	var historyTableView: UITableView!
	let historyCellID = "DomainsCell"
    
    var dataSource: DomainsDataSource = DomainsDataSource()
    var first_appear:Bool = true
    
    var didPressCell:(_ indexPath:IndexPath, _ image: UIImage?) -> () = { _ in }

	weak var delegate: BrowserNavigationDelegate?

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
		self.historyTableView.separatorColor = UIColor.lightGray
        self.historyTableView.backgroundColor = UIColor.clear
        
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
        self.loadData()        
    }
    
    func loadData() {
        dataSource.loadData { (ready) in
            self.historyTableView.reloadData()
        }
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
        dataSource.image(indexPath: indexPath) { (result) in
            if cell.tag == indexPath.row && result != nil{
                cell.logoButton.setImage(result, for: .normal)
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
        let image = cell.logoButton.imageView?.image
        didPressCell(indexPath, image)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            // handle delete (by removing the data from your array and updating the tableview)
        }
    }
    
    @objc
    func newsReady(sender:NSNotification) {
//        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
//        self.historyTableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
	
}

extension DomainsViewController: HistoryActionDelegate {
	func didSelectLogo(atIndex index: Int) {
        if index == 0{
            //pressed on the cliqz news logo
        }
        else{
            let indexPath = IndexPath(row: index, section: 0)
            let url = dataSource.baseUrl(indexPath: indexPath)
            if let url = URL(string: url){
                self.delegate?.navigateToURL(url)
            }
        }
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

extension UIImage {
    static func fromColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
