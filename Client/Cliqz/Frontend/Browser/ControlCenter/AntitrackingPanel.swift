//
//  AntitrackingPanel.swift
//  Client
//
//  Created by Mahmoud Adam on 12/29/16.
//  Copyright © 2016 CLIQZ. All rights reserved.
//

import Foundation
import Shared
import jsengine

class AntitrackingPanel: ControlCenterPanel {
    //MARK: - Constants
    private static let trackerInfoURL = "https://cliqz.com/whycliqz/anti-tracking/tracker#"
    private let trackerCellIdentifier = "TabCell"
    
    //MARK: - Instance variables
    //MARK: data
    var trackersList: [(String, Int)]!
    var trackersCount = 0
    
    //MARK: views
    private let trackersCountLabel = UILabel()
    private let configContainerView = UIView()
    private let domainLabel = UILabel()
    private let enableFeatureSwitch = UISwitch()
    lazy var legendView : UIView! = {
       return self.createLegendView()
    }()
    
	private let trackersTableView = UITableView()
    
    
    override init(webViewID: Int, url: NSURL, privateMode: Bool = false) {
        super.init(webViewID: webViewID, url: url, privateMode: privateMode)
	}
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationBadRequestDetected, object: nil)
	}
    
    //MARK: - View LifeCycle
	override func viewDidLoad() {
		super.viewDidLoad()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SELBadRequestDetected), name: NotificationBadRequestDetected, object: nil)
		
		trackersCountLabel.textColor = self.textColor()
		trackersCountLabel.font = UIFont.systemFontOfSize(30)
		self.view.addSubview(trackersCountLabel)
		trackersCountLabel.textAlignment = .Center

        // Configuration view
        self.view.addSubview(configContainerView)
        if let domain = self.currentURL.host {
            domainLabel.text = domain
        }
        domainLabel.font = UIFont.boldSystemFontOfSize(16)
        domainLabel.textColor = UIColor.blackColor()
        self.configContainerView.addSubview(domainLabel)
        
        enableFeatureSwitch.setOn(isFeatureEnabledForCurrentWebsite(), animated: false)
        enableFeatureSwitch.addTarget(self, action: #selector(toggleFeatureForCurrentWebsite), forControlEvents: .ValueChanged)
        self.configContainerView.addSubview(enableFeatureSwitch)
        
        
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

	}
    
    override func setupConstraints() {
        super.setupConstraints()
        
        trackersCountLabel.snp_makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.top.equalTo(panelIcon.snp_bottom).offset(15)
            make.height.equalTo(30)
        }
        subtitleLabel.snp_updateConstraints { make in
            make.top.equalTo(trackersCountLabel.snp_bottom).offset(15)
        }
        
        configContainerView.snp_makeConstraints { make in
            make.left.right.equalTo(trackersTableView)
            make.top.equalTo(subtitleLabel.snp_bottom).offset(20)
            make.height.equalTo(40)
        }
        enableFeatureSwitch.snp_makeConstraints { make in
            make.centerY.equalTo(configContainerView)
            make.right.equalTo(configContainerView)
        }
        domainLabel.snp_makeConstraints { make in
            make.centerY.equalTo(configContainerView)
            make.left.equalTo(configContainerView)
            make.right.equalTo(enableFeatureSwitch.snp_left).offset(-5)
        }
        
        legendView.snp_makeConstraints { make in
            make.left.right.equalTo(trackersTableView)
            make.top.equalTo(configContainerView.snp_bottom).offset(10)
            make.height.equalTo(25)
        }
        trackersTableView.snp_makeConstraints { (make) in
            make.left.equalTo(self.view).offset(25)
            make.right.equalTo(self.view).offset(-25)
            make.top.equalTo(legendView.snp_bottom)
            make.bottom.equalTo(self.okButton.snp_top).offset(-15)
        }
        
    }
    
    //MARK: - Abstract methods implementation
    override func getPanelTitle() -> String {
        if isFeatureEnabledForCurrentWebsite() {
            return NSLocalizedString("Your data is protected", tableName: "Cliqz", comment: "Anti-tracking panel title in the control center when it is enabled.")
        } else {
            return NSLocalizedString("Your data is not protected", tableName: "Cliqz", comment: "Anti-tracking panel title in the control center when it is disabled")
        }
    }
    
    override func getPanelSubTitle() -> String {
        if isFeatureEnabledForCurrentWebsite() {
            return NSLocalizedString("Private data points have been removed", tableName: "Cliqz", comment: "Anti-tracking panel subtitle in the control center when it is enabled.")
        } else {
            return NSLocalizedString("Anti-Tracking is turned off for this website", tableName: "Cliqz", comment: "Anti-tracking panel subtitle in the control center when it is disabled")
        }
    }
    
    override func getPanelIcon() -> UIImage? {
        return UIImage(named: "shieldIcon")
    }
    
    override func getLearnMoreURL() -> NSURL? {
        return NSURL(string: "https://cliqz.com/whycliqz/anti-tracking")
    }
    
    override func isFeatureEnabledForCurrentWebsite() -> Bool {
        return JSEngineAdapter.sharedInstance.isAntiTrakcingEnabledForURL(self.currentURL)
    }
    
    func toggleFeatureForCurrentWebsite() {
        JSEngineAdapter.sharedInstance.toggleAntiTrackingForURL(self.currentURL)
        self.updateView()
        self.setupConstraints()
        self.controlCenterPanelDelegate?.reloadCurrentPage()
    }
    
    func updateTrackers() {
        trackersList = JSEngineAdapter.sharedInstance.getAntiTrackingStatistics(trackedWebViewID)
        trackersCount = trackersList.reduce(0){$0 + $1.1}
    }
    
    override func updateView() {
        super.updateView()
        
        updateTrackers()
        enableFeatureSwitch.setOn(isFeatureEnabledForCurrentWebsite(), animated: false)
        trackersCountLabel.text = "\(trackersCount)"
        trackersTableView.reloadData()
        
        
        if isFeatureEnabled() {
            configContainerView.hidden = false
            
            if isFeatureEnabledForCurrentWebsite() {
                trackersCountLabel.hidden = false
                legendView.hidden = trackersCount > 0 ? false : true
                trackersTableView.hidden =  trackersCount > 0 ? false : true
            } else {
                trackersCountLabel.hidden = true
                legendView.hidden = true
                trackersTableView.hidden =  true
            }
        } else {
            configContainerView.hidden = true
            trackersCountLabel.hidden = true
            legendView.hidden = true
            trackersTableView.hidden =  true
        }
        
    }
    
    //MARK: - Helper methods
	@objc private func SELBadRequestDetected(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) {
			self.updateView()
		}
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

extension AntitrackingPanel: UITableViewDataSource, UITableViewDelegate {

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
		let url = NSURL(string: AntitrackingPanel.trackerInfoURL.stringByAppendingString(tracker))
		if let u = url {
			self.delegate?.navigateToURLInNewTab(u)
			closePanel()
            TelemetryLogger.sharedInstance.logEvent(.Attrack("click", "info_company", indexPath.row))
		}
	}
}
