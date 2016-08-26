//
//  TabsViewController.swift
//  Client
//
//  Created by Sahakyan on 8/12/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class TabsViewController: UIViewController {
	
	private var tabsView: UITableView!
	private var addTabButton: UIButton!

	let tabManager: TabManager!
	var tabs: [Tab]!

	private let TabCellIdentifier = "TabCell"

	init(tabManager: TabManager) {
		self.tabManager = tabManager
		self.tabs = tabManager.tabs
		super.init(nibName: nil, bundle: nil)
		self.tabManager.addDelegate(self)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		self.tabManager.removeDelegate(self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		tabsView = UITableView()
		tabsView.dataSource = self
		tabsView.delegate = self
		tabsView.registerClass(TabViewCell.self, forCellReuseIdentifier: self.TabCellIdentifier)
		tabsView.separatorStyle = .None
		tabsView.backgroundColor = UIConstants.AppBackgroundColor
		tabsView.allowsSelection = true
		view.addSubview(tabsView)
		
		addTabButton = UIButton(type: .Custom)
		addTabButton.setBackgroundImage(UIImage(named: "addTab"), forState: .Normal)
		addTabButton.backgroundColor = UIColor.clearColor()
		self.view.addSubview(addTabButton)
		addTabButton.addTarget(self, action: #selector(addNewTab), forControlEvents: .TouchUpInside)

		self.view.backgroundColor = UIConstants.AppBackgroundColor
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.setupConstraints()
	}

	@objc private func addNewTab(sender: UIButton) {
		self.tabManager.addTabAndSelect()
		self.navigationController?.popViewControllerAnimated(false)
	}

	private func setupConstraints() {
		tabsView.snp_makeConstraints { make in
			make.left.bottom.right.equalTo(self.view)
			make.top.equalTo(self.view).offset(10)
		}
		addTabButton.snp_makeConstraints { make in
			make.right.equalTo(self.view).offset(-10)
			make.bottom.equalTo(self.view).offset(-10)
			make.size.equalTo(CGSizeMake(30, 30))
		}
	}
}

extension TabsViewController: UITableViewDataSource, UITableViewDelegate {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.tabManager.tabs.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = self.tabsView.dequeueReusableCellWithIdentifier(TabCellIdentifier, forIndexPath: indexPath) as! TabViewCell
		let tab = self.tabs[indexPath.row]
		if tab.title != nil && tab.displayURL != nil {
			cell.titleLabel.text = tab.title
			cell.URLLabel.text = tab.displayURL?.host
		} else {
			cell.titleLabel.text = NSLocalizedString("New Tab", tableName: "Cliqz", comment: "New tab title")
			cell.URLLabel.text = NSLocalizedString("Topsites", tableName: "Cliqz", comment: "Title on the tab view, when no URL is open on the tab")
		}
		cell.selectionStyle = .None
		cell.isPrivateTabCell = tab.isPrivate
		cell.animator.delegate = self
		if let icon = tab.displayFavicon {
			cell.logoImageView.sd_setImageWithURL(NSURL(string: icon.url)!)
		} else {
			cell.logoImageView.image = nil
		}
		return cell
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 80
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let tab = self.tabManager.tabs[indexPath.row] //tabsToDisplay[index]
		self.tabManager.selectTab(tab)
		self.navigationController?.popViewControllerAnimated(false)
	}
}

extension TabsViewController: SwipeAnimatorDelegate {
	func swipeAnimator(animator: SwipeAnimator, viewWillExitContainerBounds: UIView) {
		let tabCell = animator.container as! TabViewCell
		if let indexPath = self.tabsView.indexPathForCell(tabCell) {
			let tab = self.tabManager.tabs[indexPath.row]
			tabManager.removeTab(tab)
		}
	}
}

extension TabsViewController: TabManagerDelegate {
	func tabManager(tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
	}
	
	func tabManager(tabManager: TabManager, didCreateTab tab: Tab) {
	}
	
	func tabManager(tabManager: TabManager, didAddTab tab: Tab) {
		guard let index = tabManager.tabs.indexOf(tab) else { return }
		self.tabs.insert(tab, atIndex: index)
		self.tabsView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .None)
	}

	func tabManager(tabManager: TabManager, didRemoveTab tab: Tab) {
		if let i = self.tabs.indexOf(tab) {
			self.tabsView.deleteRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: .Left)
			self.tabs.removeAtIndex(i)
		}
	}

	func tabManagerDidAddTabs(tabManager: TabManager) {
	}

	func tabManagerDidRestoreTabs(tabManager: TabManager) {
	}

	func tabManagerDidRemoveAllTabs(tabManager: TabManager, toast:ButtonToast?) {
	}
}

