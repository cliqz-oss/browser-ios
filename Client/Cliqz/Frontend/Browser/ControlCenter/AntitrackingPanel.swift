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
    fileprivate static let trackerInfoURL = "https://cliqz.com/whycliqz/anti-tracking/tracker#"
    fileprivate let trackerCellIdentifier = "TabCell"
    
    //MARK: - Instance variables
    //MARK: data
    var trackersList: [(String, Int)]!
    var trackersCount = 0
    
    //MARK: views
    fileprivate let trackersCountLabel = UILabel()
    fileprivate let configContainerView = UIView()
    fileprivate let domainLabel = UILabel()
    fileprivate let enableFeatureSwitch = UISwitch()
    
    lazy var legendView : UIView! = {
       return self.createLegendView()
    }()
    
    fileprivate let trackersTableView = UITableView()
    
    //MARK: LandscapeRegular specific views.
    let toTableViewButton = UIButton()
    
    let secondViewTitleLabel = UILabel()
    let secondViewBackButton = UIButton()
    
    override init(webViewID: Int, url: URL, privateMode: Bool = false) {
        super.init(webViewID: webViewID, url: url, privateMode: privateMode)
	}
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
	deinit {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationBadRequestDetected), object: nil)
	}
    
    //MARK: - View LifeCycle
	override func viewDidLoad() {
		super.viewDidLoad()
		NotificationCenter.default.addObserver(self, selector: #selector(SELBadRequestDetected), name: NSNotification.Name(rawValue: NotificationBadRequestDetected), object: nil)
		
		trackersCountLabel.textColor = self.textColor()
		trackersCountLabel.font = UIFont.systemFont(ofSize: 30)
		self.view.addSubview(trackersCountLabel)
		trackersCountLabel.textAlignment = .center

        // Configuration view
        self.view.addSubview(configContainerView)
        if let domain = self.currentURL.host {
            domainLabel.text = domain
        }
        domainLabel.font = UIFont.boldSystemFont(ofSize: 16)
        domainLabel.textColor = UIColor.black
        if let privateMode = self.isPrivateMode, privateMode == true {
            domainLabel.textColor = UIColor.white
        }
        self.configContainerView.addSubview(domainLabel)
        
		enableFeatureSwitch.setOn(isFeatureEnabledForCurrentWebsite(), animated: false)
        enableFeatureSwitch.addTarget(self, action: #selector(toggleFeatureForCurrentWebsite), for: .valueChanged)
        enableFeatureSwitch.onTintColor = UIConstants.CliqzThemeColor
        self.configContainerView.addSubview(enableFeatureSwitch)
        
        
        self.view.addSubview(legendView)
        
        trackersTableView.register(TrackerViewCell.self, forCellReuseIdentifier: self.trackerCellIdentifier)
        trackersTableView.delegate = self
        trackersTableView.dataSource = self
        trackersTableView.backgroundColor = UIColor.clear
        trackersTableView.tableFooterView = UIView()
        trackersTableView.separatorStyle = .none
        trackersTableView.clipsToBounds = true
        trackersTableView.allowsSelection = true
        self.view.addSubview(trackersTableView)
        
        self.customizeToTableViewButton(toTableViewButton)
        self.view.addSubview(toTableViewButton)
        
        let secondViewTitle = NSLocalizedString("AntiTracking Information", tableName: "Cliqz", comment: "AntiTracking Information text for landscape mode.")
        secondViewTitleLabel.text = secondViewTitle
        secondViewTitleLabel.textColor = UIConstants.CliqzThemeColor
        secondViewTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        secondViewTitleLabel.textAlignment = .center
        secondViewTitleLabel.isHidden = true
        self.view.addSubview(secondViewTitleLabel)
        
        
        let backButtonImage = UIImage(named: "cliqzBack")
        secondViewBackButton.setImage(backButtonImage,for: UIControlState())
        secondViewBackButton.imageView?.tintColor = UIConstants.CliqzThemeColor
        secondViewBackButton.backgroundColor = UIColor.clear
        secondViewBackButton.addTarget(self, action: #selector(hideTableView), for: .touchUpInside)
        secondViewBackButton.isHidden = true
        self.view.addSubview(secondViewBackButton)
        
        let panelLayout = OrientationUtil.controlPanelLayout()
        
        if panelLayout == .landscapeRegularSize {
            trackersTableView.isHidden = true
            legendView.isHidden = true
        }
        else{
            toTableViewButton.isHidden = true
        }
        
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetViewForLandscapeRegularSize()
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        let panelLayout = OrientationUtil.controlPanelLayout()
        
        if panelLayout == .portrait {
            trackersCountLabel.snp.remakeConstraints { make in
                make.left.right.equalTo(self.view)
                make.top.equalTo(panelIcon.snp.bottom).offset(15)
                make.height.equalTo(30)
            }
            subtitleLabel.snp.remakeConstraints({ (make) in
				make.top.equalTo(trackersCountLabel.snp.bottom).offset(15)
				make.left.equalTo(self.view).offset(20)
				make.width.equalTo(self.view.frame.width - 40)
				make.height.equalTo(20)
			})
            
            configContainerView.snp.remakeConstraints { make in
                make.left.right.equalTo(trackersTableView)
                make.top.equalTo(subtitleLabel.snp.bottom).offset(20)
                make.height.equalTo(40)
            }
            enableFeatureSwitch.snp.remakeConstraints { make in
                make.centerY.equalTo(configContainerView)
                make.right.equalTo(configContainerView)
            }
            domainLabel.snp.remakeConstraints { make in
                make.centerY.equalTo(configContainerView)
                make.left.equalTo(configContainerView)
                make.right.equalTo(enableFeatureSwitch.snp.left).offset(-5)
            }
            
            legendView.snp.remakeConstraints { make in
                make.left.right.equalTo(trackersTableView)
                make.top.equalTo(configContainerView.snp.bottom).offset(10)
                make.height.equalTo(25)
            }
            
            trackersTableView.snp.remakeConstraints { (make) in
                make.left.equalTo(self.view).offset(25)
                make.right.equalTo(self.view).offset(-25)
                make.top.equalTo(legendView.snp.bottom)
                make.bottom.equalTo(self.okButton.snp.top).offset(-15)
            }
        }
        else if panelLayout == .landscapeCompactSize{
            
            trackersCountLabel.snp.remakeConstraints { make in
                make.left.equalTo(titleLabel)
                make.width.equalTo(titleLabel)
                make.top.equalTo(panelIcon.snp.bottom).offset(15)
                make.height.equalTo(30)
            }
            
            subtitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(trackersCountLabel.snp.bottom).offset(16)
                make.left.equalTo(self.view).offset(20)
                make.width.equalTo(self.view.bounds.width/2 - 40)
                make.height.equalTo(20)
            }
            
            configContainerView.snp.remakeConstraints { make in
                make.left.equalTo(self.view.bounds.width/2)
                make.width.equalTo(self.view.bounds.width/2)
                make.top.equalTo(self.view).offset(0)
                make.height.equalTo(40)
            }
            enableFeatureSwitch.snp.remakeConstraints { make in
                make.centerY.equalTo(configContainerView)
                make.right.equalTo(configContainerView).inset(20)
            }
            domainLabel.snp.remakeConstraints { make in
                make.centerY.equalTo(configContainerView)
                make.left.equalTo(configContainerView)
                make.right.equalTo(enableFeatureSwitch.snp.left).offset(-5)
            }

            legendView.snp.remakeConstraints { make in
                make.left.equalTo(self.view.bounds.width/2)
                make.width.equalTo(self.view.bounds.width/2 - 20)
                make.top.equalTo(configContainerView.snp.bottom).offset(10)
                make.height.equalTo(25)
            }
            
            trackersTableView.snp.remakeConstraints { (make) in
                make.left.equalTo(self.view.bounds.width/2)
                make.width.equalTo(self.view.bounds.width/2 - 20)
                make.top.equalTo(legendView.snp.bottom)
                make.bottom.equalTo(self.okButton.snp.top).offset(-10)
            }
            
            okButton.snp.remakeConstraints { (make) in
                make.size.equalTo(CGSize(width: 80, height: 40))
                make.bottom.equalTo(self.view).offset(-12)
                make.centerX.equalTo(configContainerView)
            }
        }
        else
        {
            secondViewTitleLabel.snp.remakeConstraints({ (make) in
                make.top.equalTo(self.view)
                make.right.left.equalTo(self.view)
                make.height.equalTo(34)
            })
            
            secondViewBackButton.snp.remakeConstraints {make in
                make.top.equalTo(self.view)
                make.left.equalTo(20)
                make.height.width.equalTo(34)
            }
            
            trackersCountLabel.snp.remakeConstraints { make in
                make.left.right.equalTo(self.view)
                make.top.equalTo(panelIcon.snp.bottom).offset(10)
                make.height.equalTo(24)
            }
            
            subtitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(trackersCountLabel.snp.bottom).offset(10)
                make.left.equalTo(self.view).offset(20)
                make.width.equalTo(self.view.frame.width - 40)
                make.height.equalTo(20)
            }
            
            configContainerView.snp.remakeConstraints { make in
                make.bottom.equalTo(toTableViewButton.snp.top)
                make.height.equalTo(40)
                make.left.equalTo(self.view).offset(20)
                make.right.equalTo(self.view).inset(20)
            }
            
            enableFeatureSwitch.snp.remakeConstraints { make in
                make.centerY.equalTo(configContainerView)
                make.right.equalTo(configContainerView)
            }
            
            domainLabel.snp.remakeConstraints { make in
                make.centerY.equalTo(configContainerView)
                make.left.equalTo(configContainerView)
                make.right.equalTo(enableFeatureSwitch.snp.left).offset(-5)
            }
            
            toTableViewButton.snp.remakeConstraints { (make) in
                make.width.equalTo(self.view)
                make.height.equalTo(48)
                make.left.equalTo(self.view)
                make.bottom.equalTo(okButton.snp.top)
            }
            
            legendView.snp.remakeConstraints { make in
                make.left.right.equalTo(self.trackersTableView)
                make.top.equalTo(self.secondViewTitleLabel.snp.bottom).offset(8)
                make.height.equalTo(30)
            }
            
            trackersTableView.snp.remakeConstraints { (make) in
                make.left.equalTo(self.view.frame.width)
                make.width.equalTo(self.view.frame.width - 40)
                make.top.equalTo(self.legendView.snp.bottom).offset(4)
                make.bottom.equalTo(self.okButton.snp.top).offset(-15)
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
    
    override func getLearnMoreURL() -> URL? {
        return URL(string: "https://cliqz.com/whycliqz/anti-tracking")
    }
    
    override func isFeatureEnabledForCurrentWebsite() -> Bool {
        if let host = self.currentURL.host{
            let whitelisted = AntiTrackingModule.sharedInstance.isDomainWhiteListed(host)
            return !whitelisted
        }
        return false
    }
    
    func toggleFeatureForCurrentWebsite() {
        logDomainSwitchTelemetrySignal()
        AntiTrackingModule.sharedInstance.toggleAntiTrackingForURL(self.currentURL)
        self.updateView()
        self.setupConstraints()
        self.controlCenterPanelDelegate?.reloadCurrentPage()
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
            configContainerView.isHidden = false
            
            if isFeatureEnabledForCurrentWebsite() {
                trackersCountLabel.isHidden = false
                legendView.isHidden = trackersList.isEmpty ? true : false
                trackersTableView.isHidden =  trackersList.isEmpty ? true : false
                toTableViewButton.isHidden = trackersList.isEmpty || (OrientationUtil.controlPanelLayout() != .landscapeRegularSize) ? true : false
            } else {
                trackersCountLabel.isHidden = true
                legendView.isHidden = true
                trackersTableView.isHidden =  true
                toTableViewButton.isHidden = true
            }
        } else {
            configContainerView.isHidden = true
            trackersCountLabel.isHidden = true
            legendView.isHidden = true
            trackersTableView.isHidden =  true
            toTableViewButton.isHidden = true
        }
        
    }

    
    
    func showTableView(){
        UIView.animate(withDuration: 0.08, animations: {
            self.titleLabel.alpha = 0
            self.trackersCountLabel.alpha = 0
            self.subtitleLabel.alpha = 0
            self.panelIcon.alpha = 0
            self.configContainerView.alpha = 0
            self.toTableViewButton.alpha = 0
            
        }, completion: { (finished) in
            if finished {
                
                self.trackersTableView.alpha  = 0
                self.trackersTableView.isHidden = false
                
                self.legendView.alpha = 0
                self.legendView.isHidden = false
                
                self.secondViewTitleLabel.alpha = 0
                self.secondViewTitleLabel.isHidden = false
                
                self.secondViewBackButton.alpha = 0
                self.secondViewBackButton.isHidden = false
                
                UIView.animate(withDuration: 0.22, animations: {
                    
                    self.trackersTableView.alpha = 1
                    self.trackersTableView.frame.origin.x = 20
                    
                    self.legendView.alpha = 1
                    self.legendView.frame.origin.x = 20
                    
                    self.secondViewTitleLabel.alpha = 1
                    self.secondViewBackButton.alpha = 1
                    
                }, completion: {finished in

                })
            }
        })
        
        logTelemetrySignal("click", target: getAdditionalInfoName(), customData: nil)
        isAdditionalInfoVisible = true
    }
    
    func hideTableView(){
        
        UIView.animate(withDuration: 0.18, animations: {
            
            self.trackersTableView.frame.origin.x = self.view.frame.width
            self.legendView.frame.origin.x = self.view.frame.width
            
            self.trackersTableView.alpha  = 0
            self.legendView.alpha = 0
            self.secondViewTitleLabel.alpha = 0
            self.secondViewBackButton.alpha = 0
            
        }, completion: { (finished) in
            if finished {
                
                self.trackersTableView.isHidden = true
                self.legendView.isHidden = true
                self.secondViewTitleLabel.isHidden = true
                self.secondViewBackButton.isHidden = true
                
                UIView.animate(withDuration: 0.08, animations: {
                    
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
        
        logTelemetrySignal("click", target: "back", customData: nil)
        isAdditionalInfoVisible = false
    }
    
    func resetViewForLandscapeRegularSize(){
        
        if OrientationUtil.controlPanelLayout() == .landscapeRegularSize{
            
            self.trackersTableView.alpha = 1
            self.legendView.alpha = 1
            self.secondViewTitleLabel.alpha = 1
            self.secondViewBackButton.alpha = 1
            
            self.trackersTableView.isHidden = true
            self.legendView.isHidden = true
            self.secondViewTitleLabel.isHidden = true
            self.secondViewBackButton.isHidden = true
            
            self.titleLabel.alpha = 1
            self.trackersCountLabel.alpha = 1
            self.subtitleLabel.alpha = 1
            self.panelIcon.alpha = 1
            self.configContainerView.alpha = 1
            self.toTableViewButton.alpha = 1
            
        }
        
    }
    
    override func getViewName() -> String {
        return "attrack"
    }
    
    override func getAdditionalInfoName() -> String {
        return "info_tracker"
    }
    
    //MARK: - Helper methods
	@objc fileprivate func SELBadRequestDetected(_ notification: Notification) {
		DispatchQueue.main.async {
			self.updateView()
		}
	}

    
    fileprivate func createLegendView() -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        let underline = UIView()
        underline.backgroundColor = self.textColor()
        header.addSubview(underline)
        
        let nameTitle = UILabel()
        nameTitle.text = NSLocalizedString("Companies title", tableName: "Cliqz", comment: "Antitracking UI title for companies column")
        
        nameTitle.font = UIFont.systemFont(ofSize: 12)
        nameTitle.textColor = self.textColor()
        nameTitle.textAlignment = .left
nameTitle.tag = 10
        header.addSubview(nameTitle)
        
        let countTitle = UILabel()
        countTitle.text = NSLocalizedString("Trackers count title", tableName: "Cliqz", comment: "Antitracking UI title for tracked count column")
        countTitle.font = UIFont.systemFont(ofSize: 12)
        countTitle.textColor = self.textColor()
        countTitle.textAlignment = .right
        countTitle.tag = 20
        header.addSubview(countTitle)
        
        nameTitle.snp.makeConstraints { (make) in
            make.left.top.equalTo(header)
            make.height.equalTo(20)
            make.right.equalTo(countTitle.snp.left)
        }
        underline.snp.makeConstraints { (make) in
            make.left.right.equalTo(header)
            make.height.equalTo(1)
            make.top.equalTo(nameTitle.snp.bottom)
        }
        countTitle.snp.makeConstraints { (make) in
            make.right.top.equalTo(header)
            make.height.equalTo(20)
            make.width.equalTo(header).multipliedBy(0.5)
        }
        
        return header
    }
    
    func customizeToTableViewButton(_ button: UIButton){
        
        //let button = UIButton()
        button.backgroundColor = UIColor.clear
        button.addTarget(self, action: #selector(showTableView), for: .touchUpInside)
        
        //TODO: Localize this string
        let toTableViewButtonTitle = NSLocalizedString("AntiTracking Information", tableName: "Cliqz", comment: "AntiTracking Information text for landscape mode.")
        
        let label = UILabel()
        label.text = toTableViewButtonTitle
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 18)
        button.addSubview(label)
        
        let toastImage = UIImage(named: "toastInfo")
        let infoImageView = UIImageView()
        infoImageView.image = toastImage
        button.addSubview(infoImageView)
        
        let backButtonImage = UIImage(named: "cliqzBack")
        let arrowImage = UIImage(cgImage: (backButtonImage?.cgImage)!, scale: 1.0, orientation: UIImageOrientation.upMirrored)
        let arrowImageView = UIImageView()
        arrowImageView.image = arrowImage
        button.addSubview(arrowImageView)
        
        let separatorView1 = UIView()
        separatorView1.backgroundColor = UIColor.lightGray
        let separatorView2 = UIView()
        separatorView2.backgroundColor = UIColor.lightGray
        button.addSubview(separatorView1)
        button.addSubview(separatorView2)
        
        if let privateMode = self.isPrivateMode, privateMode == true {
            label.textColor = UIColor.white
            changeTintColor(arrowImageView, color: UIColor.white)
            changeTintColor(infoImageView, color: UIColor.white)
        }
        
        label.snp.makeConstraints { (make) in
            make.centerY.equalTo(button)
            make.left.equalTo(50)
        }
        
        infoImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(button)
            make.left.equalTo(8)
            make.height.width.equalTo(30)
        }
        
        arrowImageView.snp.makeConstraints{ make in
            make.centerY.equalTo(button)
            make.right.equalTo(button).inset(14)
            make.width.height.equalTo(30)
        }
        
        separatorView1.snp.makeConstraints{make in
            make.width.equalTo(button)
            make.height.equalTo(1)
            make.top.left.equalTo(button)
        }
        
        separatorView2.snp.makeConstraints{make in
            make.width.equalTo(button)
            make.height.equalTo(1)
            make.bottom.left.equalTo(button)
        }
        
    }
    
}

func changeTintColor(_ imageView: UIImageView, color: UIColor){
    let templateImage = imageView.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
    imageView.image = templateImage
    imageView.tintColor = color
}

extension AntitrackingPanel: UITableViewDataSource, UITableViewDelegate {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let list = self.trackersList else {
            return 0
        }
        return list.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = self.trackersTableView.dequeueReusableCell(withIdentifier: trackerCellIdentifier, for: indexPath) as! TrackerViewCell
		cell.isPrivateMode = self.isPrivateMode
		let item = self.trackersList[indexPath.row]
		cell.nameLabel.text = item.0
		cell.countLabel.text = "\(item.1)"
		cell.selectionStyle = .none
		cell.backgroundColor = UIColor.clear
		return cell
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 30
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 3
	}

	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let footer = UIView()
		footer.backgroundColor = UIColor.clear
		let underline = UIView()
		underline.backgroundColor = self.textColor()
		footer.addSubview(underline)
		underline.snp.makeConstraints { (make) in
			make.left.right.bottom.equalTo(footer)
			make.height.equalTo(1)
		}
		return footer
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = self.trackersList[indexPath.row]
		let tracker = item.0.replacingOccurrences(of: " ", with: "-")
		let url = URL(string: AntitrackingPanel.trackerInfoURL + tracker)
		if let u = url {
            logTelemetrySignal("click", target: "info_company", customData: ["index": indexPath.row])
			self.delegate?.navigateToURLInNewTab(u)
			closePanel()
		}
	}
}
