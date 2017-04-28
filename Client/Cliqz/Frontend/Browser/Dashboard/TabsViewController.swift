//
//  TabsViewController.swift
//  Client
//
//  Created by Sahakyan on 8/12/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class Knobs{
    static let cellSpacing = 180
    static let tiltAngle = M_PI / 6.0
    static let cellHeightMultiplier = CGFloat(0.9)
    static let landscapeSize = CGSize(width: 200, height: 130)
}

class TabsViewController: UIViewController {
	
	//private var tabsView: UITableView!
    var collectionView: UICollectionView!
	private var addTabButton: UIButton!

	let tabManager: TabManager!

	private let tabCellIdentifier = "TabCell"

	static let bottomToolbarHeight = 45
    
    var backgroundColorCache: [String:UIColor] = Dictionary()
    
    init(tabManager: TabManager) {
		self.tabManager = tabManager
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
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: PortraitFlowLayout())
        collectionView.registerClass(TabViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.view.addSubview(collectionView)
        
        if UIScreen.mainScreen().bounds.size.width > UIScreen.mainScreen().bounds.size.height {
            self.collectionView.collectionViewLayout = LandscapeFlowLayout()
        }
        else{
            self.collectionView.collectionViewLayout = PortraitFlowLayout()
        }
		
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
		self.collectionView.reloadData()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.setupConstraints()
	}
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        self.collectionView.alpha = 0.0
        
        coordinator.animateAlongsideTransition({ (coordinatorContext) in
            
            var layout: UICollectionViewFlowLayout
            
            if size.width > size.height{
                layout = LandscapeFlowLayout()
            }
            else{
                layout = PortraitFlowLayout()
            }
            
            self.collectionView.performBatchUpdates({
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.reloadData()
            }) { (finished) in
                self.collectionView.setCollectionViewLayout(layout, animated: true)
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
            
        }) { (coordinatorContext) in
            UIView.animateWithDuration(0.3, animations: {
                self.collectionView.alpha = 1.0
            })
        }
        
    }

	@objc private func addNewTab(sender: UIButton) {
		self.openNewTab()
        
        let customData: [String : AnyObject] = ["tab_count" : self.tabManager.tabs.count]
        TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "click", "new_tab", customData))
	}
    
    @objc func SELdidLongPressAddTab(recognizer: UILongPressGestureRecognizer) {
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
        
        let actionSheetController = UIAlertController.createNewTabActionSheetController(addTabButton, newTabHandler: newTabHandler, newForgetModeTabHandler: newForgetModeTabHandler, cancelHandler: cancelHandler)
        
        self.presentViewController(actionSheetController, animated: true, completion: nil)
        
        let customData: [String : AnyObject] = ["count" : self.tabManager.tabs.count]
        TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "longpress", "new_tab", customData))
    }

	private func openNewTab(isPrivate: Bool = false) {
		if isPrivate {
            self.tabManager.addTabAndSelect(nil, configuration: nil, isPrivate: true)
		} else {
			self.tabManager.addTabAndSelect()
		}
		self.navigationController?.popViewControllerAnimated(false)
	}

	private func setupConstraints() {
        
        collectionView.snp_makeConstraints { (make) in
            make.top.left.right.equalTo(self.view)
            make.bottom.equalTo(addTabButton.snp_top)
        }
		addTabButton.snp_makeConstraints { make in
			make.centerX.equalTo(self.view)
			make.bottom.equalTo(self.view)
			make.left.right.equalTo(self.view)
			make.height.equalTo(TabsViewController.bottomToolbarHeight)
		}
	}
}

extension TabsViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tabManager.tabs.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! TabViewCell
        
        cell.tag = indexPath.row
        
        let tab = self.tabManager.tabs[indexPath.row]
        cell.delegate = self
        
        let freshtab = tab.displayURL?.absoluteString?.contains("cliqz/goto.html") ?? false
        
        if tab.displayURL != nil && !freshtab{
            cell.descriptionLabel.text = tab.displayTitle
            cell.domainLabel.text = tab.displayURL?.absoluteString
        } else {
            cell.domainLabel.text = NSLocalizedString("New Tab", tableName: "Cliqz", comment: "New tab title")
            cell.descriptionLabel.text = NSLocalizedString("Topsites", tableName: "Cliqz", comment: "Title on the tab view, when no URL is open on the tab")
        }
        
        cell.domainLabel.accessibilityLabel = cell.domainLabel.text

        if tab.isPrivate{
            cell.makeCellPrivate()
        }
        else{
            cell.makeCellUnprivate()
        }
        
        //tab.displayFavicon?.url
        
        cell.logoImageView.image = nil
        
        
        if let url = tab.displayURL?.absoluteString {
            LogoLoader.loadLogo(url, completionBlock: { (image, error) in
                if let img = image{
                    if cell.tag == indexPath.row{
                        if cell.logoImageView.image == nil {
                            cell.logoImageView.image = img
                        }
                        cell.setBigLogo(img)
                    }
                }
            })
        }
        
        
        cell.accessibilityLabel = tab.displayURL?.absoluteString
        return cell

    }
}


extension TabsViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let tab = self.tabManager.tabs[indexPath.row]
        self.tabManager.selectTab(tab)
        self.navigationController?.popViewControllerAnimated(false)
        
        if let currentCell = collectionView.cellForItemAtIndexPath(indexPath) as? TabViewCell {
            logTabClickSignal(currentCell, indexPath: indexPath, count: self.tabManager.tabs.count, isForget: tab.isPrivate)
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

extension TabsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var cellSize = UIScreen.mainScreen().bounds.size
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            cellSize.width /= 1.22
        }
        else{
            cellSize.width /= 1.6
        }
        
        if ((collectionViewLayout as? LandscapeFlowLayout) != nil) {
            return Knobs.landscapeSize
        }
        
        if indexPath.item == collectionView.numberOfItemsInSection(0) - 1 {
            return CGSize(width: cellSize.width, height: cellSize.width * CGFloat(Knobs.cellHeightMultiplier))
        }
        
        return CGSize(width: cellSize.width, height: CGFloat(Knobs.cellSpacing))
    }
}

extension TabsViewController: TabViewCellDelegate {
    func removeTab(cell: TabViewCell, swipe: SwipeType) {
        
        guard let indexPath = self.collectionView.indexPathForCell(cell) else {return}
        
        let tab = self.tabManager.tabs[indexPath.row]
        
        var customData: [String : AnyObject] = ["count" : self.tabManager.tabs.count, "is_forget" : tab.isPrivate, "element" : "close"]
        if let tabIndex = self.tabManager.getIndex(tab) {
            customData["index"] = tabIndex
        }
        
        var action = ""
        
        if swipe == .None {
            action = "click"
        }
        else if swipe == .Right {
            action = "swipe_right"
        }
        else if swipe == .Left {
            action = "swipe_left"
        }
        
        self.tabManager.removeTab(tab)
        
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
        self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])//insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .None)
    }
    
    func tabManager(tabManager: TabManager, didRemoveTab tab: Tab, removeIndex: Int) {
        self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forRow: removeIndex, inSection: 0)])//deleteRowsAtIndexPaths([NSIndexPath(forRow: removeIndex, inSection: 0)], withRowAnimation: .Left)
    }
    
    func tabManagerDidAddTabs(tabManager: TabManager) {
    }
    
    func tabManagerDidRestoreTabs(tabManager: TabManager) {
    }
    
    func tabManagerDidRemoveAllTabs(tabManager: TabManager, toast:ButtonToast?) {
    }
}
