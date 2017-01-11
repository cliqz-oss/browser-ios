//
//  AntitrackingViewController.swift
//  Client
//
//  Created by Sahakyan on 8/29/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import Shared

protocol AntitrackingViewDelegate: class {

	func antitrackingViewWillClose(antitrackingView: UIView)

}

class AntitrackingViewController: UIViewController, UIGestureRecognizerDelegate {

	private var blurryBackgroundView: UIVisualEffectView!
	private var backgroundView: UIView!
	private let titleLabel = UILabel()
	private let titleIcon = UIImageView()
	private let trackersCountLabel = UILabel()
	private let subtitleLabel = UILabel()
    lazy var legendView : UIView! = {
       return self.createLegendView()
    }()
    
	private let trackersTableView = UITableView()

	private let helpButton = UIButton(type: .Custom)

	private let antitrackingGreen = UIColor(rgb: 0x2CBA84)

	private let trackedWebViewID: Int!
	private var trackersList: [(String, Int)]!

	private let trackerCellIdentifier = "TabCell"

	private static let antitrackingHelpURL = "https://cliqz.com/whycliqz/anti-tracking"
	private static let trackerInfoURL = "https://cliqz.com/whycliqz/anti-tracking/tracker#"

	weak var delegate: BrowserNavigationDelegate? = nil
	weak var antitrackingDelegate: AntitrackingViewDelegate? = nil

	private let isPrivateMode: Bool!
    
    var viewOpenTime: Double?

	init(webViewID: Int, privateMode: Bool = false) {
		trackedWebViewID = webViewID
		trackersList = AntiTrackingModule.sharedInstance.getAntiTrackingStatistics(trackedWebViewID)
		isPrivateMode = privateMode
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationBadRequestDetected, object: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
        viewOpenTime = NSDate.getCurrentMillis()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SELBadRequestDetected), name: NotificationBadRequestDetected, object: nil)
		let blurEffect = UIBlurEffect(style: .Light)
		self.blurryBackgroundView = UIVisualEffectView(effect: blurEffect)
		self.view.insertSubview(blurryBackgroundView, atIndex: 0)
		self.backgroundView = UIView()
		self.backgroundView.backgroundColor = self.backgroundColor().colorWithAlphaComponent(0.8)
		self.view.addSubview(self.backgroundView)

		titleLabel.textColor = antitrackingGreen
		titleLabel.font = UIFont.systemFontOfSize(22)
		titleLabel.textAlignment = .Center
		self.view.addSubview(titleLabel)
		titleLabel.text = NSLocalizedString("Data is protected", tableName: "Cliqz", comment: "Antitracking UI top title")

		let img = UIImage(named: "shieldIcon")
		titleIcon.image = img!.imageWithRenderingMode(.AlwaysTemplate)
		titleIcon.tintColor = antitrackingGreen
		self.view.addSubview(titleIcon)

		trackersCountLabel.textColor = self.textColor()
		trackersCountLabel.font = UIFont.systemFontOfSize(30)
		self.view.addSubview(trackersCountLabel)
		trackersCountLabel.textAlignment = .Center

		subtitleLabel.textColor = antitrackingGreen
		subtitleLabel.font = UIFont.boldSystemFontOfSize(16)
		subtitleLabel.textAlignment = .Center
		self.view.addSubview(subtitleLabel)
		subtitleLabel.text = NSLocalizedString("Private data points", tableName: "Cliqz", comment: "Persönliche Daten wurden entfernt")
		
        self.view.addSubview(legendView)
        
		trackersTableView.registerClass(TrackerViewCell.self, forCellReuseIdentifier: self.trackerCellIdentifier)
		trackersTableView.delegate = self
		trackersTableView.dataSource = self
		trackersTableView.backgroundColor = UIColor.clearColor()
		trackersTableView.tableFooterView = UIView()
        trackersTableView.separatorStyle = .None
		trackersTableView.clipsToBounds = true
		trackersTableView.allowsSelection = true
		self.view.addSubview(trackersTableView)

		let title = NSLocalizedString("Help", comment: "Show the SUMO support page from the Support section in the settings")
		self.helpButton.setTitle(title, forState: .Normal)
		self.helpButton.setTitleColor(self.textColor(), forState: .Normal)
		self.helpButton.titleLabel?.font = UIFont.boldSystemFontOfSize(14)
		self.helpButton.layer.borderColor = self.textColor().CGColor
		self.helpButton.layer.borderWidth = 1.5
		self.helpButton.layer.cornerRadius = 6
		self.helpButton.backgroundColor = UIColor.clearColor()
		self.helpButton.addTarget(self, action: #selector(openHelp), forControlEvents: .TouchUpInside)
		self.view.addSubview(self.helpButton)

		let tap = UITapGestureRecognizer(target: self, action: #selector(tapRecognizer))
		tap.cancelsTouchesInView = false
		self.view.addGestureRecognizer(tap)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.setupConstraints()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.trackersCountLabel.text = "\(AntiTrackingModule.sharedInstance.getTrackersCount(self.trackedWebViewID))"
	}

	@objc func tapRecognizer(sender: UITapGestureRecognizer) {
		let p = sender.locationInView(self.view)
		if p.y <= 44 {
			closeAntitrackingView()
		}
	}

	private func setupConstraints() {
		blurryBackgroundView.snp_makeConstraints { (make) in
			make.left.right.bottom.equalTo(self.view)
			make.top.equalTo(self.view).offset(44)
		}
		backgroundView.snp_makeConstraints { (make) in
			make.left.right.bottom.equalTo(self.view)
			make.top.equalTo(self.view).offset(44)
		}
		titleLabel.snp_makeConstraints { make in
			make.left.right.equalTo(self.view)
			make.top.equalTo(self.view).offset(88)
			make.height.equalTo(24)
		}
		titleIcon.snp_makeConstraints { make in
			make.centerX.equalTo(self.view)
			make.top.equalTo(titleLabel.snp_bottom).offset(20)
		}
		trackersCountLabel.snp_makeConstraints { make in
			make.left.right.equalTo(self.view)
			make.top.equalTo(titleIcon.snp_bottom).offset(7)
			make.height.equalTo(30)
		}
		subtitleLabel.snp_makeConstraints { make in
			make.left.right.equalTo(self.view)
			make.top.equalTo(trackersCountLabel.snp_bottom).offset(7)
			make.height.equalTo(20)
		}
        legendView.snp_makeConstraints { make in
            make.left.right.equalTo(trackersTableView)
            make.top.equalTo(subtitleLabel.snp_bottom).offset(10)
            make.height.equalTo(25)
        }
		trackersTableView.snp_makeConstraints { (make) in
			make.left.equalTo(self.view).offset(25)
			make.right.equalTo(self.view).offset(-25)
			make.top.equalTo(legendView.snp_bottom)
			make.bottom.equalTo(self.helpButton.snp_top).offset(-5)
		}
		helpButton.snp_makeConstraints { (make) in
			make.size.equalTo(CGSizeMake(80, 35))
			make.centerX.equalTo(self.view)
			make.bottom.equalTo(self.view).offset(-10)
		}
	}

	private func closeAntitrackingView() {
		self.antitrackingDelegate?.antitrackingViewWillClose(self.view)
		UIView.animateWithDuration(0.5, animations: {
			var p = self.view.center
			p.y -= self.view.frame.size.height
			self.view.center = p
		}) { (finished) in
			if finished {
				self.view.removeFromSuperview()
				self.removeFromParentViewController()
			}
		}
        if let openTime = viewOpenTime {
            let showDuration = Int(NSDate.getCurrentMillis() - openTime)
            TelemetryLogger.sharedInstance.logEvent(.Attrack("hide", nil, showDuration))
            viewOpenTime = nil
        }
	}

	@objc private func openHelp(sender: UIButton) {
		let url = NSURL(string: AntitrackingViewController.antitrackingHelpURL)
		if let u = url {
			self.delegate?.navigateToURLInNewTab(u)
			closeAntitrackingView()
            TelemetryLogger.sharedInstance.logEvent(.Attrack("click", "help", nil))
		}
	}

	@objc private func SELBadRequestDetected(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) {
			self.trackersList = AntiTrackingModule.sharedInstance.getAntiTrackingStatistics(self.trackedWebViewID)
			self.updateView()
		}
	}

	private func updateView() {
		self.trackersCountLabel.text = "\(AntiTrackingModule.sharedInstance.getTrackersCount(self.trackedWebViewID))"
		self.trackersTableView.reloadData()
	}

	private func textColor() -> UIColor {
		if self.isPrivateMode == true {
			return UIConstants.PrivateModeTextColor
		}
		return UIConstants.NormalModeTextColor
	}

	private func backgroundColor() -> UIColor {
		if self.isPrivateMode == true {
			return UIColor(rgb: 0x222222)
		}
		return UIColor(rgb: 0xE8E8E8)
	}

    private func createLegendView() -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clearColor()
        let underline = UIView()
        underline.backgroundColor = self.textColor()
        header.addSubview(underline)
        
        let nameTitle = UILabel()
        nameTitle.text = NSLocalizedString("Companies title", tableName: "Cliqz", comment: "Antitracking UI title for companies column")
        
        nameTitle.font = UIFont.systemFontOfSize(12)
        nameTitle.textColor = self.textColor()
        nameTitle.textAlignment = .Left
        header.addSubview(nameTitle)
        
        let countTitle = UILabel()
        countTitle.text = NSLocalizedString("Trackers count title", tableName: "Cliqz", comment: "Antitracking UI title for tracked count column")
        countTitle.font = UIFont.systemFontOfSize(12)
        countTitle.textColor = self.textColor()
        countTitle.textAlignment = .Right
        header.addSubview(countTitle)
        
        nameTitle.snp_makeConstraints { (make) in
            make.left.top.equalTo(header)
            make.height.equalTo(20)
            make.right.equalTo(countTitle.snp_left)
        }
        underline.snp_makeConstraints { (make) in
            make.left.right.equalTo(header)
            make.height.equalTo(1)
            make.top.equalTo(nameTitle.snp_bottom)
        }
        countTitle.snp_makeConstraints { (make) in
            make.right.top.equalTo(header)
            make.height.equalTo(20)
            make.width.equalTo(header).multipliedBy(0.5)
        }
        
        return header
    }
}

extension AntitrackingViewController: UITableViewDataSource, UITableViewDelegate {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.trackersList.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = self.trackersTableView.dequeueReusableCellWithIdentifier(trackerCellIdentifier, forIndexPath: indexPath) as! TrackerViewCell
		cell.isPrivateMode = self.isPrivateMode
		let item = self.trackersList[indexPath.row]
		cell.nameLabel.text = item.0
		cell.countLabel.text = "\(item.1)"
		cell.selectionStyle = .None
		cell.backgroundColor = UIColor.clearColor()
		return cell
	}

	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 30
	}
	
	func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 3
	}

	func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let footer = UIView()
		footer.backgroundColor = UIColor.clearColor()
		let underline = UIView()
		underline.backgroundColor = self.textColor()
		footer.addSubview(underline)
		underline.snp_makeConstraints { (make) in
			make.left.right.bottom.equalTo(footer)
			make.height.equalTo(1)
		}
		return footer
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let item = self.trackersList[indexPath.row]
		let tracker = item.0.stringByReplacingOccurrencesOfString(" ", withString: "-")
		let url = NSURL(string: AntitrackingViewController.trackerInfoURL.stringByAppendingString(tracker))
		if let u = url {
			self.delegate?.navigateToURLInNewTab(u)
			closeAntitrackingView()
            TelemetryLogger.sharedInstance.logEvent(.Attrack("click", "info_company", indexPath.row))
		}
	}
}
