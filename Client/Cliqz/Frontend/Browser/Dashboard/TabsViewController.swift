//
//  TabsViewController.swift
//  Client
//
//  Created by Sahakyan on 8/12/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import WebImage

class Knobs {
    class func minCellSpacing() -> Double {
        return Double((UIScreen.main.bounds.size.height - 200) / 4.0)
    }
    class func maxCellSpacing() -> Double {
        return Double((UIScreen.main.bounds.size.height - 200) / 1.8)
    }
    class func maxTiltAngle() -> Double {
        return UIDevice.current.userInterfaceIdiom == .phone ? Double.pi / 5.0 : Double.pi / 6.0
    }
    class func minTiltAngle() -> Double {
        return UIDevice.current.userInterfaceIdiom == .phone ? Double.pi / 10.0 : Double.pi / 20.0
    }
    class func minOffset() -> Double {
        return -4.0
    }
    class func maxOffset() -> Double {
        return 57.0
    }
    class func minScale() -> Double {
        return 0.9
    }
    class func maxScale() -> Double {
        return 1.0
    }
    class func cellHeight() -> CGFloat {
        return UIScreen.main.bounds.size.height - 200
    }
    class func cellWidth() -> CGFloat {
        let ratio = UIDevice.current.userInterfaceIdiom == .phone ? 1.26 : 1.4
        return UIScreen.main.bounds.size.width / CGFloat(ratio)
    }
    class func landscapeSize() -> CGSize {
        return CGSize(width: 200, height: 130)
    }
    class func tiltAngle(count: Int) -> Double {
        return increasing(max: Knobs.maxTiltAngle(), min: Knobs.minTiltAngle(), factor: 0.85)(count)
    }
    class func interCellSpace(count: Int) -> CGFloat {
        return CGFloat(decreasing(max: Knobs.maxCellSpacing(), min: Knobs.minCellSpacing(), factor: 0.85)(count))
    }
    class func increasing(max: Double, min: Double, factor: Double) -> (Int) -> Double {
        return { count in
            if count < 1 {return min}
            return max - (1/pow(Double(count), factor)) * (max - min)
        }
    }
    class func decreasing(max: Double, min: Double, factor: Double) -> (Int) -> Double {
        return { count in
            if count < 1 {return max}
            return min + 1/pow(Double(count), factor) * (max - min)
        }
    }
}

class TabsViewController: UIViewController {
	
    fileprivate let emptyTabDefaultLogoUrl = "https://cliqz.com"
    
    var collectionView: UICollectionView!
	private var addTabButton: UIButton!

	let tabManager: TabManager!

	fileprivate let tabCellIdentifier = "TabCell"

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
        collectionView.register(TabViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.view.addSubview(collectionView)
		
		addTabButton = UIButton(type: .custom)
		addTabButton.setTitle("+", for: UIControlState())
		addTabButton.setTitleColor(UIColor.black, for: UIControlState())
		addTabButton.titleLabel?.font = UIFont.systemFont(ofSize: 30)
		addTabButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
		addTabButton.backgroundColor =  UIColor.white
		self.view.addSubview(addTabButton)
		addTabButton.addTarget(self, action: #selector(addNewTab), for: .touchUpInside)

        let longPressGestureAddTabButton = UILongPressGestureRecognizer(target: self, action: #selector(TabsViewController.SELdidLongPressAddTab(_:)))
        addTabButton.addGestureRecognizer(longPressGestureAddTabButton)

		self.view.backgroundColor = UIConstants.AppBackgroundColor
     
	}
    
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        
        if UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height {
            self.collectionView.collectionViewLayout = LandscapeFlowLayout()
        }
        else{
            self.collectionView.collectionViewLayout = PortraitFlowLayout()
        }
        
		self.collectionView.reloadData()
        if self.collectionView.contentSize.height > self.collectionView.frame.size.height{
            self.collectionView.contentOffset = CGPoint(x: 0, y: self.collectionView.contentSize.height - self.collectionView.frame.size.height)
        }
	}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.setupConstraints()
	}
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
	
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        self.collectionView.alpha = 0.0
        
        coordinator.animate(alongsideTransition: { (coordinatorContext) in
            
            var layout: UICollectionViewFlowLayout
            
            if size.width > size.height{
                layout = LandscapeFlowLayout()
            }
            else{
                layout = PortraitFlowLayout()
            }
            
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.setCollectionViewLayout(layout, animated: true)
            
        }) { (coordinatorContext) in
            UIView.animate(withDuration: 0.3, animations: {
                self.collectionView.alpha = 1.0
            })
        }
        
    }

	@objc private func addNewTab(sender: UIButton) {
		self.openNewTab()
        
        let customData: [String : AnyObject] = ["tab_count" : self.tabManager.tabs.count as AnyObject]
        TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "click", "new_tab", customData))
	}
	
    @objc func SELdidLongPressAddTab(_ recognizer: UILongPressGestureRecognizer) {
        let newTabHandler = { (action: UIAlertAction) in
            TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "click", "new_tab", nil))
            self.openNewTab()
            return
        }
        
        let newForgetModeTabHandler = { (action: UIAlertAction) in
            TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "click", "new_forget_tab", nil))
            
            self.openNewTab(isPrivate: true)
            return
        }
        
        let cancelHandler = { (action: UIAlertAction) in
            // do no thing
            TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "click", "cancel", nil))
        }
        
        let actionSheetController = UIAlertController.createNewTabActionSheetController(addTabButton, newTabHandler: newTabHandler, newForgetModeTabHandler: newForgetModeTabHandler, cancelHandler: cancelHandler)
        
        self.present(actionSheetController, animated: true, completion: nil)
        
        let customData: [String : Any] = ["count" : self.tabManager.tabs.count]
        TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "longpress", "new_tab", customData))
    }

	private func openNewTab(isPrivate: Bool = false) {
		if isPrivate {
            _ = self.tabManager.addTabAndSelect(nil, configuration: nil, isPrivate: true)
		} else {
			_ = self.tabManager.addTabAndSelect()
		}
		self.navigationController?.popViewController(animated: false)
	}

	fileprivate func setupConstraints() {
		collectionView.snp.makeConstraints { make in
			make.left.right.equalTo(self.view)
			make.top.equalTo(self.view)
			make.bottom.equalTo(addTabButton.snp.top)
		}
		addTabButton.snp.makeConstraints { make in
			make.centerX.equalTo(self.view)
			make.bottom.equalTo(self.view)
			make.left.right.equalTo(self.view)
			make.height.equalTo(TabsViewController.bottomToolbarHeight)
		}
	}
}

extension TabsViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tabManager.tabs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! TabViewCell
        
        cell.tag = indexPath.row
        
        let tab = self.tabManager.tabs[indexPath.row]
        cell.delegate = self
        
        let freshtab = tab.displayURL?.absoluteString.contains("cliqz/goto.html") ?? false
        
        if tab.displayURL != nil && !freshtab {
            cell.descriptionLabel.text = tab.displayTitle
            cell.domainLabel.text = tab.displayURL?.baseDomain()
        } else {
            
            cell.domainLabel.text = NSLocalizedString("Cliqz Tab" , tableName: "Cliqz", comment: "New tab title")
            
            if tab.isPrivate {
                cell.descriptionLabel.text = NSLocalizedString("You are browsing in Forget Mode", tableName: "Cliqz", comment: "Private Tab description")
            }
            else {
                cell.descriptionLabel.text = NSLocalizedString("Topsites", tableName: "Cliqz", comment: "Title on the tab view, when no URL is open on the tab")
            }
            
        }

        cell.domainLabel.accessibilityLabel = cell.domainLabel.text

        if tab.isPrivate {
            cell.makeCellPrivate()
        }
        else {
            cell.makeCellUnprivate()
        }

        if let favIconString = tab.displayFavicon?.url, let favIconUrl = URL(string:favIconString) {

            let options = [SDWebImageOptions.lowPriority]

            SDWebImageManager.shared().downloadImage(with: favIconUrl, options: SDWebImageOptions(options), progress: nil, completed: { (image , error , cacheType, success , given_url) in
                guard cell.tag == indexPath.row else { return }
                if success {
                    cell.setSmallUpperLogo(image)
                } else {
                    cell.setSmallUpperLogo(UIImage(named: "favIconDefault"))
                }
            })
        } else {
            cell.setSmallUpperLogo(UIImage(named: "favIconDefault"))
        }

        if let url = tab.displayURL?.absoluteString {
            
            LogoLoader.loadLogo(url, completionBlock: { (image, error) in
                guard cell.tag == indexPath.row else { return }
                
                if image != nil {
                    cell.setBigLogo(image: image, cliqzLogo: false)
                }
                else {
                    let fakeLogo = LogoLoader.generateFakeLogo(url: url, fontSize: 44)
                    cell.setBigLogoView(fakeLogo)
                }
            })
        }
        else{
            cell.setBigLogo(image: UIImage(named: "cliqzTabLogo"), cliqzLogo: true)
        }

        cell.accessibilityLabel = tab.displayURL?.absoluteString
        return cell
    }
}


extension TabsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tab = self.tabManager.tabs[indexPath.row]
        self.tabManager.selectTab(tab)
        self.navigationController?.popViewController(animated: false)
        
        if let currentCell = collectionView.cellForItem(at: indexPath) as? TabViewCell {
            logTabClickSignal(currentCell: currentCell, indexPath: indexPath, count: self.tabManager.tabs.count, isForget: tab.isPrivate)
        }
    }
    
    func logTabClickSignal(currentCell : TabViewCell, indexPath: IndexPath, count: Int, isForget: Bool) {
        var customData: [String : Any] = ["index" : indexPath.row, "count" : count , "is_forget" : isForget]
        
        if let clickedElement = currentCell.clickedElement {
            customData["element"] = clickedElement
        }
        
        TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", "click", "tab", customData))
    }

}

extension TabsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = UIScreen.main.bounds.size
        
        if ((collectionViewLayout as? LandscapeFlowLayout) != nil) {
            return Knobs.landscapeSize()
        }
        
        let count = collectionView.numberOfItems(inSection: 0)
        
        if indexPath.item == collectionView.numberOfItems(inSection: 0) - 1 {
            return CGSize(width: cellSize.width, height: Knobs.cellHeight())
        }
        
        return CGSize(width: cellSize.width, height: Knobs.interCellSpace(count: count))
    }
}

extension TabsViewController: TabViewCellDelegate {
    func removeTab(cell: TabViewCell, swipe: SwipeType) {
        
        guard let indexPath = self.collectionView.indexPath(for: cell) else {return}
        
        let tab = self.tabManager.tabs[indexPath.row]
        
        var customData: [String : Any] = ["count" : self.tabManager.tabs.count, "is_forget" : tab.isPrivate, "element" : "close"]
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
        if self.tabManager.tabs.count == 1 {
            self.tabManager.removeTab(tab)
            self.navigationController?.popViewController(animated: false)
        } else {
            self.tabManager.removeTab(tab)
        }
        
        TelemetryLogger.sharedInstance.logEvent(.DashBoard("open_tabs", action, "tab", customData))
    }
}

extension TabsViewController: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
    }
    
    func tabManager(_ tabManager: TabManager, didCreateTab tab: Tab) {
    }
    
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
        guard let index = tabManager.tabs.index(of: tab) else { return }
        self.collectionView.insertItems(at: [IndexPath(row: index, section: 0)])
    }
    
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, removeIndex: Int) {
        if self.collectionView.numberOfItems(inSection: 0) <= 2{
            UIView.animate(withDuration: 0.1, animations: {
                self.collectionView.contentOffset = CGPoint(x: 0.0,y: 0.0)
            })
        }
        self.collectionView.deleteItems(at: [IndexPath(row: removeIndex, section: 0)])
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func tabManagerDidAddTabs(_ tabManager: TabManager) {
    }
    
    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
    }
    
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast:ButtonToast?) {
    }
}
