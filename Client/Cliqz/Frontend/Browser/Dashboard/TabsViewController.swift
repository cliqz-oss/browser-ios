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

	private let tabCellIdentifier = "TabCell"

	static let bottomToolbarHeight = 45
    
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
		tabsView.registerClass(TabViewCell.self, forCellReuseIdentifier: self.tabCellIdentifier)
		tabsView.separatorStyle = .None
		tabsView.backgroundColor = UIConstants.AppBackgroundColor
		tabsView.allowsSelection = true
		view.addSubview(tabsView)
		
		addTabButton = UIButton(type: .Custom)
		addTabButton.setTitle("+", forState: .Normal)
		addTabButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
		addTabButton.titleLabel?.font = UIFont.systemFontOfSize(30)
		addTabButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
		addTabButton.backgroundColor =  UIColor.whiteColor()
		self.view.addSubview(addTabButton)
		addTabButton.addTarget(self, action: #selector(addNewTab), forControlEvents: .TouchUpInside)

        let longPressGestureAddTabButton = UILongPressGestureRecognizer(target: self, action: #selector(TabsViewController.SELdidLongPressAddTab(_:)))
        addTabButton.addGestureRecognizer(longPressGestureAddTabButton)

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
		self.openNewTab()
        
        let customData: [String : AnyObject] = ["count" : tabs.count]
        TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "click", "new_tab", customData))
	}
    
    @objc func SELdidLongPressAddTab(recognizer: UILongPressGestureRecognizer) {
        if #available(iOS 9, *) {
            let newTabHandler = { (action: UIAlertAction) in
                TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "click", "new_tab", nil))
                self.openNewTab()
                return
            }
            
            let newForgetModeTabHandler = { (action: UIAlertAction) in
                TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "click", "new_forget_tab", nil))
                
                self.openNewTab(true)
                return
            }
            
            let cancelHandler = { (action: UIAlertAction) in
                // do no thing
                TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "click", "cancel", nil))
            }
            
            let actionSheetController = UIAlertController.createNewTabActionSheetController(addTabButton, newTabHandler: newTabHandler, newForgetModeTabHandler: newForgetModeTabHandler, cancelHandler:  cancelHandler)
            
            self.presentViewController(actionSheetController, animated: true, completion: nil)
            
            let customData: [String : AnyObject] = ["count" : tabs.count]
            TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "longpress", "new_tab", customData))
        }
    }

	private func openNewTab(isPrivate: Bool = false) {
		if isPrivate {
			if #available(iOS 9, *) {
				self.tabManager.addTabAndSelect(nil, configuration: nil, isPrivate: true)
			}
		} else {
			self.tabManager.addTabAndSelect()
		}
		self.navigationController?.popViewControllerAnimated(false)
	}

	private func setupConstraints() {
		tabsView.snp_makeConstraints { make in
			make.left.bottom.right.equalTo(self.view)
			make.top.equalTo(self.view).offset(10)
		}
		addTabButton.snp_makeConstraints { make in
			make.centerX.equalTo(self.view)
			make.bottom.equalTo(self.view)
			make.left.right.equalTo(self.view)
			make.height.equalTo(TabsViewController.bottomToolbarHeight)
		}
	}
}

extension TabsViewController: UITableViewDataSource, UITableViewDelegate {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.tabManager.tabs.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = self.tabsView.dequeueReusableCellWithIdentifier(tabCellIdentifier, forIndexPath: indexPath) as! TabViewCell
		let tab = self.tabs[indexPath.row]
		if tab.title != nil && tab.displayURL != nil {
			cell.titleLabel.text = tab.title
			cell.URLLabel.text = tab.displayURL?.host
		} else {
			cell.URLLabel.text = NSLocalizedString("New Tab", tableName: "Cliqz", comment: "New tab title")
			cell.titleLabel.text = NSLocalizedString("Topsites", tableName: "Cliqz", comment: "Title on the tab view, when no URL is open on the tab")
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
        
        if let currentCell = tableView.cellForRowAtIndexPath(indexPath) as? TabViewCell {
            logTabClickSignal(currentCell, indexPath: indexPath, count: tabs.count, isForget: tab.isPrivate)
        }
        

	}
    func logTabClickSignal(currentCell : TabViewCell, indexPath: NSIndexPath, count: Int, isForget: Bool) {
        var customData: [String : AnyObject] = ["index" : indexPath.row, "count" : count , "is_forget" : isForget]
        
        if let clickedElement = currentCell.clickedElement {
            customData["element"] = clickedElement
        }
        
        TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "click", "tab", customData))
    }
}

extension TabsViewController: SwipeAnimatorDelegate {
	func swipeAnimator(animator: SwipeAnimator, viewWillExitContainerBounds: UIView) {
		let tabCell = animator.container as! TabViewCell
		if let indexPath = self.tabsView.indexPathForCell(tabCell) {
			let tab = self.tabManager.tabs[indexPath.row]
			tabManager.removeTab(tab)
            
            logSwipeSignal(tab, indexPath: indexPath, viewWillExitContainerBounds: viewWillExitContainerBounds)
            
		}
	}
    func logSwipeSignal(tab: Tab, indexPath: NSIndexPath, viewWillExitContainerBounds: UIView) {
        
        var action = ""
        if viewWillExitContainerBounds.frame.origin.x < 0 {
            action = "swipe_left"
        } else {
            action = "swipe_right"
        }
        
        let customData: [String : AnyObject] = ["index" : indexPath.row, "count" : tabs.count, "is_forget" : tab.isPrivate]
        TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", action, "tab", customData))
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
		tabManager.selectTab(tab)
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

