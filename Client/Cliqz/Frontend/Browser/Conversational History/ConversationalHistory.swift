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

protocol HistoryProtocol: class{
    func numberOfCells() -> Int
    func urlLabelText(indexPath:NSIndexPath) -> String
    func titleLabelText(indexPath:NSIndexPath) -> String
    func timeLabelText(indexPath:NSIndexPath) -> String
    func baseUrl(indexPath:NSIndexPath) -> String
    func image(indexPath:NSIndexPath, completionBlock:(result:UIImage?) -> Void)
    func shouldShowNotification(indexPath:NSIndexPath) -> Bool
    func notificationNumber(indexPath:NSIndexPath) -> Int
}

class ConversationalHistory: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	var historyTableView: UITableView!
	let historyCellID = "HistoryCell"
    
    var dataSource: HistoryDataSource = HistoryDataSource()
    var first_appear:Bool = true
    
    var didPressCell:(indexPath:NSIndexPath, image: UIImage?) -> () = { _ in }

	weak var delegate: BrowserNavigationDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()
		self.historyTableView = UITableView(frame: CGRectZero, style: .Plain)
		self.view.addSubview(self.historyTableView)
		self.historyTableView.snp_makeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.view)
		}
		self.historyTableView.delegate = self
		self.historyTableView.dataSource = self
		self.historyTableView.registerClass(HistoryCell.self, forCellReuseIdentifier: historyCellID)
		self.historyTableView.tableFooterView = UIView()
		self.historyTableView.separatorStyle = .SingleLine
		self.historyTableView.separatorColor = UIColor.lightGrayColor()
	}

	override func viewWillDisappear(animated: Bool) {
        //dataSource.clean()
		self.navigationController?.navigationBarHidden = true
		super.viewWillDisappear(animated)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.navigationBarHidden = true
//		self.backButton.hidden = true
        self.loadData()        
    }
    
    func loadData() {
        dataSource.loadData { (ready) in
            self.historyTableView.reloadData()
        }
    }

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource.numberOfCells()
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
		let cell =  self.historyTableView.dequeueReusableCellWithIdentifier(self.historyCellID) as! HistoryCell
		cell.delegate = self
        cell.tag = indexPath.row
        
        let articleLink = dataSource.urlLabelText(indexPath)
        cell.URLLabel.text   = articleLink
        cell.titleLabel.text = dataSource.titleLabelText(indexPath)
        dataSource.image(indexPath) { (result) in
            if cell.tag == indexPath.row && result != nil{
                cell.logoButton.setImage(result, forState: .Normal)
            }
        }
        
        if dataSource.shouldShowNotification(indexPath) {
            cell.notificationView.hidden = false
            cell.notificationView.numberLabel.text = String(dataSource.notificationNumber(indexPath))
        }
        else{
            cell.notificationView.hidden = true
        }

		cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		cell.accessoryType = .DisclosureIndicator
		cell.selectionStyle = .None
		return cell
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 70
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! HistoryCell
        let image = cell.logoButton.imageView?.image
        didPressCell(indexPath: indexPath, image: image)
	}
	
}

extension ConversationalHistory: HistoryActionDelegate {
	func didSelectLogo(atIndex index: Int) {
        if index == 0{
            //pressed on the cliqz news logo
        }
        else{
            let key = dataSource.domains[index]
            if let value = dataSource.domainsInfo.valueForKey(key) as? NSDictionary,
                baseURL = value.valueForKey("baseUrl") as? String,
                url = NSURL(string: baseURL) {
                self.delegate?.navigateToURL(url)
            }
        }
	}
}

//extension ConversationalHistory: KeyboardHelperDelegate {
//	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
//		updateViewConstraints()
//		
//	}
//	
//	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
//		updateViewConstraints()
//	}
//	
//	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
//	}
//}

protocol HistoryActionDelegate: class {
	func didSelectLogo(atIndex index: Int)
}

class HistoryCell: UITableViewCell {
	let titleLabel = UILabel()
	let URLLabel = UILabel()
	let logoButton = UIButton() //UIImageView()
    let defaultImage = UIImage.fromColor(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1), size: CGSize(width: 60, height: 60))
    
    let notificationView: CellNotificationView
    let notificationHeight: CGFloat = CGFloat(21)

	weak var delegate: HistoryActionDelegate?

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        
        notificationView = CellNotificationView(frame: CGRect(x: 0, y: 0, width: notificationHeight, height: notificationHeight))
		
        super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.contentView.addSubview(titleLabel)
		titleLabel.font = UIFont.systemFontOfSize(14, weight: UIFontWeightMedium)
		titleLabel.textColor = UIColor.lightGrayColor()
		titleLabel.backgroundColor = UIColor.clearColor()
		titleLabel.textAlignment = .Left
		self.contentView.addSubview(URLLabel)
		URLLabel.font = UIFont.systemFontOfSize(18, weight: UIFontWeightMedium)
		URLLabel.textColor = UIColor.blackColor() //UIColor(rgb: 0x77ABE6)
		URLLabel.backgroundColor = UIColor.clearColor()
		URLLabel.textAlignment = .Left
		self.contentView.addSubview(logoButton)
		logoButton.layer.cornerRadius = 20
		logoButton.clipsToBounds = true
		self.logoButton.addTarget(self, action: #selector(logoPressed), forControlEvents: .TouchUpInside)
        logoButton.setImage(defaultImage, forState: .Normal)
        self.contentView.addSubview(notificationView)
    }
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.logoButton.setImage(defaultImage, forState: .Normal)
    }

	override func layoutSubviews() {
		super.layoutSubviews()
		self.logoButton.snp_remakeConstraints { (make) in
			make.left.equalTo(self.contentView).offset(10)
			make.centerY.equalTo(self.contentView)
			make.width.equalTo(40)
			make.height.equalTo(40)
		}
		self.URLLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.contentView).offset(15)
			make.left.equalTo(self.logoButton.snp_right).offset(15)
			make.height.equalTo(20)
			make.right.equalTo(self.contentView).offset(40)
		}
		self.titleLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.URLLabel.snp_bottom).offset(5)
			make.left.equalTo(self.URLLabel.snp_left)
			make.height.equalTo(20)
			make.right.equalTo(self.contentView).offset(40)
		}
        self.notificationView.snp_remakeConstraints { (make) in
            make.width.height.equalTo(notificationHeight)
            make.centerY.equalTo(self.contentView)
            make.right.equalTo(self.contentView).inset(12)
        }
	}
	
	@objc private func logoPressed() {
		self.delegate?.didSelectLogo(atIndex: self.tag)
	}
	
}

class CellNotificationView: UIView {
    
    let numberLabel: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit(){
        let bounds = self.bounds
        self.layer.cornerRadius = min(bounds.width/2, bounds.height/2)
        self.backgroundColor = UIColor(colorString: "4FACED")
        self.clipsToBounds = true
        self.addSubview(numberLabel)
        numberLabel.frame = bounds
        numberLabel.text = "0"
        numberLabel.textColor = UIColor.whiteColor()
        numberLabel.textAlignment = .Center
        numberLabel.font = UIFont.systemFontOfSize(14)
    }
}

extension UIImage {
    static func fromColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context!, color.CGColor)
        CGContextFillRect(context!, rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
