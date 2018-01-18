//
//  DashboardViewController.swift
//  Client
//
//  Created by Sahakyan on 8/12/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import QuartzCore

protocol BrowsingDelegate: class {
    
    func didSelectURL(_ url: URL)
    func didSelectQuery(_ query: String)
}

enum DashBoardPanelType: Int {
    case TabsPanel = 0, HistoryPanel, FavoritesPanel, OffrzPanel
}

class DashboardViewController: UIViewController, BrowsingDelegate {
	
	var profile: Profile!
	let tabManager: TabManager
    
    var viewOpenTime : Double?
    var panelOpenTime : Double?
    var currentPanel : DashBoardPanelType = .TabsPanel

    fileprivate var panelSwitchControl = UISegmentedControl(items: [])
	fileprivate var panelSwitchContainerView: UIView!
	fileprivate var panelContainerView: UIView!

	fileprivate let dashboardThemeColor = UIConstants.CliqzThemeColor

	weak var delegate: BrowserNavigationDelegate!

	fileprivate lazy var historyViewController: HistoryViewController = {
		let historyViewController = HistoryViewController(profile: self.profile)
		historyViewController.delegate = self
		return historyViewController
	}()

	fileprivate lazy var favoritesViewController: FavoritesViewController = {
		let favoritesViewController = FavoritesViewController(profile: self.profile)
		favoritesViewController.delegate = self
		return favoritesViewController
	}()

	fileprivate lazy var tabsViewController: TabsViewController = {
		let tabsViewController = TabsViewController(tabManager: self.tabManager)
		return tabsViewController
	}()

	fileprivate lazy var offrzViewController: OffrzViewController = {
		let offrz = OffrzViewController(profile: self.profile)
		offrz.delegate = self
		return offrz
	}()

	init(profile: Profile, tabManager: TabManager) {
		self.tabManager = tabManager
		self.profile = profile
		super.init(nibName: nil, bundle: nil)
	}

    deinit {
        // Removed observers for Connect features
        NotificationCenter.default.removeObserver(self, name: ShowBrowserViewControllerNotification, object: nil)
    }

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
	override func viewDidLoad() {
		super.viewDidLoad()
		
		panelSwitchContainerView = UIView()
		panelSwitchContainerView.backgroundColor = UIColor.white
		view.addSubview(panelSwitchContainerView)
        
		panelContainerView = UIView()
		view.addSubview(panelContainerView)

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "cliqzBack"), style: .plain, target: self, action: #selector(goBack))
		self.navigationItem.title = NSLocalizedString("Overview", tableName: "Cliqz", comment: "Dashboard navigation bar title")
		self.navigationController?.navigationBar.tintColor = UIColor.black
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title:  NSLocalizedString("Settings", tableName: "Cliqz", comment: "Setting menu title"), style: .plain, target: self, action: #selector(openSettings))
		self.navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSFontAttributeName : UIFont.boldSystemFont(ofSize: 17)], for: UIControlState())
		self.navigationItem.rightBarButtonItem?.tintColor = self.dashboardThemeColor
		view.backgroundColor = UIColor.white
        
        viewOpenTime = Date.getCurrentMillis()
        // Add observers for Connection features
        NotificationCenter.default.addObserver(self, selector: #selector(dismissView), name: ShowBrowserViewControllerNotification, object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		getApp().changeStatusBarStyle(.default, backgroundColor: self.view.backgroundColor!, isNormalMode: true)
		self.navigationController?.isNavigationBarHidden = false
		self.navigationController?.navigationBar.shadowImage = UIImage()
		self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for:  .default)
        
        adJustPanelSwitchControl()
        self.switchToCurrentPanel()
    }
    
    private func createPanelSwitchControl(numberOfSegments: Int) {
        guard panelSwitchControl.numberOfSegments != numberOfSegments else {
            return
        }

        let tabs = UIImage(named: "tabs")
        let history = UIImage(named: "history_quick_access")
        let fav = UIImage(named: "favorite_quick_access")
		let offrz = (self.profile.offrzDataSource?.hasUnseenOffrz() ?? false) ? UIImage(named: "offrz_active") : UIImage(named: "offrz_inactive")
        var items = [tabs, history, fav]
        if numberOfSegments == 4 {
            items.append(offrz)
        }
        if currentPanel.rawValue >= numberOfSegments {
            currentPanel = .TabsPanel
        }
        
        panelSwitchControl.removeFromSuperview()
        panelSwitchControl = UISegmentedControl(items: items)
        panelSwitchControl.tintColor = self.dashboardThemeColor
        panelSwitchControl.addTarget(self, action: #selector(switchPanel), for: .valueChanged)
        panelSwitchContainerView.addSubview(panelSwitchControl)
       
        panelSwitchControl.snp.makeConstraints { make in
            make.centerY.equalTo(panelSwitchContainerView)
            make.left.equalTo(panelSwitchContainerView).offset(10)
            make.right.equalTo(panelSwitchContainerView).offset(-10)
            make.height.equalTo(30)
        }
    }
    
    private func adJustPanelSwitchControl() {
        let region = SettingsPrefs.shared.getRegionPref()
        if region == "DE" { // TODO: Should call `DataSource.ShouldShowOffers()`
            createPanelSwitchControl(numberOfSegments: 4)
        } else {
            createPanelSwitchControl(numberOfSegments: 3)
        }
    }
    
	override func viewWillDisappear(_ animated: Bool) {
		self.navigationController?.isNavigationBarHidden = true
		super.viewWillDisappear(animated)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.setupConstraints()
	}

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        // setting the navigation bar origin to (0,0) to prevent shifting it when rotating from landscape to portrait orientation
        self.navigationController?.navigationBar.frame.origin = CGPoint(x: 0, y: 0)
    }
    
    // Called when send tab notification sent from Connect while dashboard is presented
    func dismissView() {
        self.navigationController?.popViewController(animated: false)
    }

	func didSelectURL(_ url: URL) {
		self.navigationController?.popViewController(animated: false)
		self.delegate?.navigateToURL(url)
	}

	func didSelectQuery(_ query: String) {
		CATransaction.begin()
		CATransaction.setCompletionBlock({
			self.delegate?.navigateToQuery(query)
		})
		self.navigationController?.popViewController(animated: false)
		CATransaction.commit()
	}
    
    func switchPanel(_ sender: UISegmentedControl) {
        if let panelType = DashBoardPanelType(rawValue: sender.selectedSegmentIndex) {
            currentPanel = panelType
            self.switchToCurrentPanel()
        }
    }
    
    private func switchToCurrentPanel() {
        self.panelSwitchControl.selectedSegmentIndex = currentPanel.rawValue
        var target = "UNDEFINED"
        
        self.hideCurrentPanelViewController()
        switch currentPanel {
            
        case .TabsPanel:
            self.showPanelViewController(self.tabsViewController)
            target = "openTabs"
            
        case .HistoryPanel:
            self.showPanelViewController(self.historyViewController)
            target = "history"
            
        case .FavoritesPanel:
            self.showPanelViewController(self.favoritesViewController)
            target = "favorites"
            
        case .OffrzPanel:
            self.showPanelViewController(self.offrzViewController)
            target = "offrz"
            
        }
        logToolbarSignal("click", target: target, customData: nil)
    }
    
	fileprivate func setupConstraints() {
		panelSwitchContainerView.snp.makeConstraints { make in
			make.left.right.equalTo(self.view)
			make.top.equalTo(topLayoutGuide.snp.bottom)
			make.height.equalTo(65)
		}
		panelContainerView.snp.makeConstraints { make in
			make.top.equalTo(self.panelSwitchContainerView.snp.bottom)
			make.left.right.bottom.equalTo(self.view)
		}
	}

	fileprivate func showPanelViewController(_ viewController: UIViewController) {
		addChildViewController(viewController)
		self.panelContainerView.addSubview(viewController.view)
		viewController.view.snp.makeConstraints { make in
			make.top.left.right.bottom.equalTo(self.panelContainerView)
		}
		viewController.didMove(toParentViewController: self)
        logShowPanelSignal(viewController)
        
        panelOpenTime = Date.getCurrentMillis()
	}

	fileprivate func hideCurrentPanelViewController() {
		if let panel = childViewControllers.first {
			panel.willMove(toParentViewController: nil)
			panel.view.removeFromSuperview()
			panel.removeFromParentViewController()
            logHidePanelSignal(panel)
		}
	}

	@objc fileprivate func goBack() {
		self.navigationController?.popViewController(animated: false)
        if let openTime = viewOpenTime {
            let duration = Int(Date.getCurrentMillis() - openTime)
            logToolbarSignal("click", target: "back", customData: ["show_duration" :duration])
            viewOpenTime = nil
        }
	}

	@objc fileprivate func openSettings() {
		let settingsTableViewController = AppSettingsTableViewController()
		settingsTableViewController.profile = profile
		settingsTableViewController.tabManager = tabManager
		settingsTableViewController.settingsDelegate = self
		
		let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
		controller.popoverDelegate = self
		controller.modalPresentationStyle = UIModalPresentationStyle.formSheet
		present(controller, animated: true, completion: nil)
        
        logToolbarSignal("click", target: "settings", customData: nil)
	}
}

extension DashboardViewController: SettingsDelegate {

	func settingsOpenURLInNewTab(_ url: URL) {
		let tab = self.tabManager.addTab(URLRequest(url: url))
		self.tabManager.selectTab(tab)
		self.navigationController?.popViewController(animated: false)
	}
}

extension DashboardViewController:PresentingModalViewControllerDelegate {

	func dismissPresentedModalViewController(_ modalViewController: UIViewController, animated: Bool) {
		self.dismiss(animated: animated, completion: nil)
	}

}

//MARK: - telemetry singals

extension DashboardViewController {
    
    fileprivate func logToolbarSignal(_ action: String, target: String, customData: [String: Any]?) {
        TelemetryLogger.sharedInstance.logEvent(.Toolbar(action, target, "overview", nil, customData))
    }
    
    fileprivate func logShowPanelSignal(_ panel: UIViewController) {
        let type = getPanelType(panel)
        TelemetryLogger.sharedInstance.logEvent(.DashBoard(type, "show", nil, nil))
        panelOpenTime = nil
    }
    
    fileprivate func logHidePanelSignal(_ panel: UIViewController) {
        guard  let openTime = panelOpenTime else {
            return
        }
        let duration = Int(Date.getCurrentMillis() - openTime)
        let customData = ["show_duration" : duration]
        let type = getPanelType(panel)
        
        TelemetryLogger.sharedInstance.logEvent(.DashBoard(type, "hide", nil, customData))
        panelOpenTime = nil
        
    }
    
    private func getPanelType(_ panel: UIViewController) -> String {
        switch panel {
        case tabsViewController:
            return "open_tabs"

        case historyViewController:
            return "history"

        case favoritesViewController:
            return "favorites"

        default:
            return "UNDEFINED"
        }
    }
}
