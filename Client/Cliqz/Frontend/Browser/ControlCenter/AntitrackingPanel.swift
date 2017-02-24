//
//  AntitrackingPanel.swift
//  Client
//
//  Created by Mahmoud Adam on 12/29/16.
//  Copyright © 2016 CLIQZ. All rights reserved.
//

import Foundation
import Shared

class AntitrackingPanel: ControlCenterPanel {
    //MARK: - Constants
    private static let trackerInfoURL = "https://cliqz.com/whycliqz/anti-tracking/tracker#"
    private let trackerCellIdentifier = "TabCell"
    
    //MARK: - Instance variables
    //MARK: data
    private var trackersList: [(String, Int)]!
    private var trackersCount = 0
    
    //MARK: views
    private let trackersCountLabel = UILabel()
    private let configContainerView = UIView()
    private let domainLabel = UILabel()
    private let enableFeatureSwitch = UISwitch()
    
    lazy var legendView : UIView! = {
       return self.createLegendView()
    }()
    
    private let trackersTableView = UITableView()
    
    //MARK: LandscapeRegular specific views.
    let toTableViewButton = UIButton()
    
    let secondViewTitleLabel = UILabel()
    let secondViewBackButton = UIButton()
    
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
        
        self.customizeToTableViewButton(toTableViewButton)
        self.view.addSubview(toTableViewButton)
        
        //TODO: Localize this string
        let secondViewTitle = "Tracking-Information"
        secondViewTitleLabel.text = secondViewTitle
        secondViewTitleLabel.textColor = UIConstants.CliqzThemeColor
        secondViewTitleLabel.font = UIFont.boldSystemFontOfSize(18)
        secondViewTitleLabel.textAlignment = .Center
        secondViewTitleLabel.hidden = true
        self.view.addSubview(secondViewTitleLabel)
        
        
        let backButtonImage = UIImage.init(imageLiteral: "cliqzBack")
        secondViewBackButton.setImage(backButtonImage,forState: .Normal)
        secondViewBackButton.imageView?.tintColor = UIConstants.CliqzThemeColor
        secondViewBackButton.backgroundColor = UIColor.clearColor()
        secondViewBackButton.addTarget(self, action: #selector(hideTableView), forControlEvents: .TouchUpInside)
        secondViewBackButton.hidden = true
        self.view.addSubview(secondViewBackButton)
        
        let panelLayout = OrientationUtil.controlPanelLayout()
        
        if panelLayout == .LandscapeRegularSize {
            trackersTableView.hidden = true
            legendView.hidden = true
            legendView.frame = CGRectMake(self.view.frame.width, 0, self.view.frame.size.width/2, 30)
            
            var frame = self.view.frame
            frame.origin.x = self.view.frame.size.width
            frame.origin.y = legendView.frame.origin.y + legendView.frame.size.height
            trackersTableView.frame = frame
            
        }
        else{
            toTableViewButton.hidden = true
        }

	}
    
    override func setupConstraints() {
        super.setupConstraints()
        
        let panelLayout = OrientationUtil.controlPanelLayout()
        
        if panelLayout == .Portrait {
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
        else if panelLayout == .LandscapeCompactSize{
            
            trackersCountLabel.snp_makeConstraints { make in
                make.left.equalTo(titleLabel)
                make.width.equalTo(titleLabel)
                make.top.equalTo(panelIcon.snp_bottom).offset(15)
                make.height.equalTo(30)
            }
            
            subtitleLabel.snp_updateConstraints { make in
                make.top.equalTo(trackersCountLabel.snp_bottom).offset(16)
            }
            
            configContainerView.snp_makeConstraints { make in
                make.left.equalTo(self.view.bounds.width/2)
                make.width.equalTo(self.view.bounds.width/2)
                make.top.equalTo(self.view).offset(0)
                make.height.equalTo(40)
            }
            enableFeatureSwitch.snp_makeConstraints { make in
                make.centerY.equalTo(configContainerView)
                make.right.equalTo(configContainerView).inset(20)
            }
            domainLabel.snp_makeConstraints { make in
                make.centerY.equalTo(configContainerView)
                make.left.equalTo(configContainerView)
                make.right.equalTo(enableFeatureSwitch.snp_left).offset(-5)
            }

            legendView.snp_makeConstraints { make in
                make.left.equalTo(self.view.bounds.width/2)
                make.width.equalTo(self.view.bounds.width/2 - 20)
                make.top.equalTo(configContainerView.snp_bottom).offset(10)
                make.height.equalTo(25)
            }
            
            trackersTableView.snp_makeConstraints { (make) in
                make.left.equalTo(self.view.bounds.width/2)
                make.width.equalTo(self.view.bounds.width/2 - 20)
                make.top.equalTo(legendView.snp_bottom)
                make.bottom.equalTo(self.okButton.snp_top).offset(-10)
            }
            
            okButton.snp_updateConstraints { (make) in
                make.centerX.equalTo(configContainerView)
            }
        }
        else
        {
            secondViewTitleLabel.snp_makeConstraints(closure: { (make) in
                make.top.equalTo(self.view)
                make.right.left.equalTo(self.view)
                make.height.equalTo(34)
            })
            
            secondViewBackButton.snp_makeConstraints {make in
                make.top.equalTo(self.view)
                make.left.equalTo(20)
                make.height.width.equalTo(34)
            }
            
            trackersCountLabel.snp_makeConstraints { make in
                make.left.right.equalTo(self.view)
                make.top.equalTo(panelIcon.snp_bottom).offset(10)
                make.height.equalTo(24)
            }
            
            subtitleLabel.snp_updateConstraints { make in
                make.top.equalTo(trackersCountLabel.snp_bottom).offset(10)
            }
            
            configContainerView.snp_makeConstraints { make in
                make.bottom.equalTo(toTableViewButton.snp_top)
                make.height.equalTo(40)
                make.left.equalTo(self.view).offset(20)
                make.right.equalTo(self.view).inset(20)
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
            
            toTableViewButton.snp_makeConstraints { (make) in
                make.width.equalTo(self.view)
                make.height.equalTo(48)
                make.left.equalTo(self.view)
                make.bottom.equalTo(okButton.snp_top)
            }
            
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
        if let host = self.currentURL.host{
            return !AntiTrackingModule.sharedInstance.isDomainWhiteListed(host)
        }
        return false
    }
    
    func toggleFeatureForCurrentWebsite() {
        AntiTrackingModule.sharedInstance.toggleAntiTrackingForURL(self.currentURL)
        self.updateView()
        self.setupConstraints()
    }
    
    func updateTrackers() {
        trackersList = AntiTrackingModule.sharedInstance.getAntiTrackingStatistics(trackedWebViewID)
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
            toTableViewButton.hidden = true
        }
        
    }
    
    func showTableView(){
        UIView.animateWithDuration(0.08, animations: {
            self.titleLabel.alpha = 0
            self.trackersCountLabel.alpha = 0
            self.subtitleLabel.alpha = 0
            self.panelIcon.alpha = 0
            self.configContainerView.alpha = 0
            self.toTableViewButton.alpha = 0
            
        }, completion: { (finished) in
            if finished {
                
                self.trackersTableView.alpha  = 0
                self.trackersTableView.hidden = false
                
                self.legendView.alpha = 0
                self.legendView.hidden = false
                
                self.secondViewTitleLabel.alpha = 0
                self.secondViewTitleLabel.hidden = false
                
                self.secondViewBackButton.alpha = 0
                self.secondViewBackButton.hidden = false
                
                UIView.animateWithDuration(0.22, animations: {
                    
                    self.trackersTableView.alpha = 1
                    self.trackersTableView.frame.origin.x = 20
                    
                    self.legendView.alpha = 1
                    self.legendView.frame.origin.x = 20
                    
                    self.secondViewTitleLabel.alpha = 1
                    self.secondViewBackButton.alpha = 1
                    
                    self.legendView.snp_makeConstraints { make in
                        make.left.right.equalTo(self.trackersTableView)
                        make.top.equalTo(self.secondViewTitleLabel.snp_bottom).offset(8)
                        make.height.equalTo(30)
                    }
                    
                    self.trackersTableView.snp_makeConstraints { (make) in
                        make.left.equalTo(self.view).offset(20)
                        make.right.equalTo(self.view).offset(-20)
                        make.top.equalTo(self.legendView.snp_bottom).offset(4)
                        make.bottom.equalTo(self.okButton.snp_top).offset(-15)
                    }
                    
                }, completion: {finished in

                })
            }
        })
    }
    
    func hideTableView(){
        
        UIView.animateWithDuration(0.18, animations: {
            
            self.trackersTableView.frame.origin.x = self.view.frame.width
            self.legendView.frame.origin.x = self.view.frame.width
            
            self.trackersTableView.alpha  = 0
            self.legendView.alpha = 0
            self.secondViewTitleLabel.alpha = 0
            self.secondViewBackButton.alpha = 0
            
        }, completion: { (finished) in
            if finished {
                
                self.trackersTableView.hidden = true
                self.legendView.hidden = true
                self.secondViewTitleLabel.hidden = true
                self.secondViewBackButton.hidden = true
                
                UIView.animateWithDuration(0.08, animations: {
                    
                    self.titleLabel.alpha = 1
                    self.trackersCountLabel.alpha = 1
                    self.subtitleLabel.alpha = 1
                    self.panelIcon.alpha = 1
                    self.configContainerView.alpha = 1
                    self.toTableViewButton.alpha = 1
                    
                }, completion: {finished in
                    
                })
            }
        })
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
    
    func customizeToTableViewButton(button: UIButton){
        
        //let button = UIButton()
        button.backgroundColor = UIColor.clearColor()
        button.addTarget(self, action: #selector(showTableView), forControlEvents: .TouchUpInside)
        
        //TODO: Localize this string
        let toTableViewButtonTitle = "Tracking-Information"
        
        let label = UILabel()
        label.text = toTableViewButtonTitle
        label.textColor = UIColor.blackColor()
        label.font = UIFont.systemFontOfSize(18)
        button.addSubview(label)
        
        let toastImage = UIImage.init(imageLiteral: "toastInfo")
        let infoImageView = UIImageView()
        infoImageView.image = toastImage
        button.addSubview(infoImageView)
        
        let backButtonImage = UIImage.init(imageLiteral: "cliqzBack")
        let arrowImage = UIImage(CGImage: backButtonImage.CGImage!, scale: 1.0, orientation: UIImageOrientation.UpMirrored)
        let arrowImageView = UIImageView()
        arrowImageView.image = arrowImage
        button.addSubview(arrowImageView)
        
        let separatorView1 = UIView()
        separatorView1.backgroundColor = UIColor.lightGrayColor()
        let separatorView2 = UIView()
        separatorView2.backgroundColor = UIColor.lightGrayColor()
        button.addSubview(separatorView1)
        button.addSubview(separatorView2)
        
        
        label.snp_makeConstraints { (make) in
            make.centerY.equalTo(button)
            make.left.equalTo(50)
        }
        
        infoImageView.snp_makeConstraints { (make) in
            make.centerY.equalTo(button.center.y)
            make.left.equalTo(8)
            make.height.width.equalTo(30)
        }
        
        arrowImageView.snp_makeConstraints{ make in
            make.centerY.equalTo(button.center.y)
            make.right.equalTo(button).inset(14)
            make.width.height.equalTo(30)
        }
        
        separatorView1.snp_makeConstraints{make in
            make.width.equalTo(button)
            make.height.equalTo(1)
            make.top.left.equalTo(button)
        }
        
        separatorView2.snp_makeConstraints{make in
            make.width.equalTo(button)
            make.height.equalTo(1)
            make.bottom.left.equalTo(button)
        }
        
    }
    
}

extension AntitrackingPanel: UITableViewDataSource, UITableViewDelegate {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let list = self.trackersList else {
            return 0
        }
        return list.count
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
