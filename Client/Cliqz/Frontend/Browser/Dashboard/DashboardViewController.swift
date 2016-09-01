//
//  DashboardViewController.swift
//  Client
//
//  Created by Sahakyan on 8/12/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class DashboardViewController: UIViewController, HistoryDelegate, FavoritesDelegate {
	
	var profile: Profile!
	let tabManager: TabManager

	private var panelSwitchControl: UISegmentedControl!
	private var panelSwitchContainerView: UIView!
	private var panelContainerView: UIView!

	weak var delegate: BrowserNavigationDelegate!

	private lazy var historyViewController: HistoryViewController = {
		let historyViewController = HistoryViewController(profile: self.profile)
		historyViewController.delegate = self
		return historyViewController
	}()

	private lazy var favoritesViewController: FavoritesViewController = {
		let favoritesViewController = FavoritesViewController(profile: self.profile)
		favoritesViewController.delegate = self
		return favoritesViewController
	}()

	private lazy var tabsViewController: TabsViewController = {
		let tabsViewController = TabsViewController(tabManager: self.tabManager)
		return tabsViewController
	}()

	init(profile: Profile, tabManager: TabManager) {
		self.tabManager = tabManager
		self.profile = profile
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		panelSwitchContainerView = UIView()
		panelSwitchContainerView.backgroundColor = UIColor.whiteColor()
		view.addSubview(panelSwitchContainerView)
		
		let fav = NSLocalizedString("Favorites", tableName: "Cliqz", comment: "Settings item for clearing favorite history")
		let history = NSLocalizedString("History", tableName: "Cliqz", comment: "History title on dashboard")

		panelSwitchControl = UISegmentedControl(items: ["Tabs", history, fav])
		panelSwitchControl.tintColor = UIColor(rgb: 0x78C9D9)
		panelSwitchControl.addTarget(self, action: #selector(switchPanel), forControlEvents: .ValueChanged)
		panelSwitchContainerView.addSubview(panelSwitchControl)
		self.panelSwitchControl.selectedSegmentIndex = 0

		panelContainerView = UIView()
		view.addSubview(panelContainerView)

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "cliqzBack"), style: .Plain, target: self, action: #selector(goBack))
		self.navigationItem.title = NSLocalizedString("Overview", tableName: "Cliqz", comment: "Dashboard navigation bar title")
		self.navigationController?.navigationBar.tintColor = UIColor.blackColor()

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title:  NSLocalizedString("Settings", tableName: "Cliqz", comment: "Setting menu title"), style: .Plain, target: self, action: #selector(openSettings))
		view.backgroundColor = UIColor.whiteColor()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.navigationBarHidden = false
		self.navigationController?.navigationBar.shadowImage = UIImage()
		self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics:  .Default)
		self.switchPanel(self.panelSwitchControl)
	}

	override func viewWillDisappear(animated: Bool) {
		self.navigationController?.navigationBarHidden = true
		super.viewWillAppear(animated)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.setupConstraints()
	}

	func didSelectURL(url: NSURL) {
		self.navigationController?.popViewControllerAnimated(false)
		self.tabManager.selectedTab?.inSearchMode = false
		self.delegate?.navigateToURL(url)
	}

	func didSelectQuery(query: String) {
		self.navigationController?.popViewControllerAnimated(false)
		self.tabManager.selectedTab?.inSearchMode = false
		self.delegate?.navigateToQuery(query)
	}

	func switchPanel(sender: UISegmentedControl) {
		self.hideCurrentPanelViewController()
		switch sender.selectedSegmentIndex {
		case 0:
			self.showPanelViewController(self.tabsViewController)
		case 1:
			self.showPanelViewController(self.historyViewController)
		case 2:
			self.showPanelViewController(self.favoritesViewController)
		default:
			break
		}
	}

	private func setupConstraints() {
		let switchControlHeight = 30
		let switchControlLeftOffset = 10
		let switchControlRightOffset = -10
		
		panelSwitchContainerView.snp_makeConstraints { make in
			make.left.right.equalTo(self.view)
			make.top.equalTo(snp_topLayoutGuideBottom)
			make.height.equalTo(45)
		}
		panelSwitchControl.snp_makeConstraints { make in
			make.top.equalTo(panelSwitchContainerView)
			make.left.equalTo(panelSwitchContainerView).offset(switchControlLeftOffset)
			make.right.equalTo(panelSwitchContainerView).offset(switchControlRightOffset)
			make.height.equalTo(switchControlHeight)
		}
		panelContainerView.snp_makeConstraints { make in
			make.top.equalTo(self.panelSwitchContainerView.snp_bottom)
			make.left.right.bottom.equalTo(self.view)
		}
	}

	private func showPanelViewController(viewController: UIViewController) {
		addChildViewController(viewController)
		self.panelContainerView.addSubview(viewController.view)
		viewController.view.snp_makeConstraints { make in
			make.top.left.right.bottom.equalTo(self.panelContainerView)
		}
		viewController.didMoveToParentViewController(self)
	}

	private func hideCurrentPanelViewController() {
		if let panel = childViewControllers.first {
			panel.willMoveToParentViewController(nil)
			panel.view.removeFromSuperview()
			panel.removeFromParentViewController()
		}
	}

	@objc private func goBack() {
		self.navigationController?.popViewControllerAnimated(false)
	}

	@objc private func openSettings() {
		let settingsTableViewController = AppSettingsTableViewController()
		settingsTableViewController.profile = profile
		settingsTableViewController.tabManager = tabManager
		settingsTableViewController.settingsDelegate = self
		
		let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
		controller.popoverDelegate = self
		controller.modalPresentationStyle = UIModalPresentationStyle.FormSheet
		presentViewController(controller, animated: true, completion: nil)
	}
}

extension DashboardViewController: SettingsDelegate {

	func settingsOpenURLInNewTab(url: NSURL) {
		let tab = self.tabManager.addTab(NSURLRequest(URL: url))
		self.tabManager.selectTab(tab)
		self.navigationController?.popViewControllerAnimated(false)
	}
}

extension DashboardViewController:PresentingModalViewControllerDelegate {

	func dismissPresentedModalViewController(modalViewController: UIViewController, animated: Bool) {
		self.dismissViewControllerAnimated(animated, completion: nil)
	}

}