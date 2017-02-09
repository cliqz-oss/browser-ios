//
//  FreshtabViewController.swift
//  Client
//
//  Created by Sahakyan on 12/6/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import SnapKit
import Storage
import Shared
import Alamofire


class FreshtabViewController: UIViewController, UIGestureRecognizerDelegate {
    
	var profile: Profile!
	var isForgetMode = false {
		didSet {
			self.updateView()
		}
	}
    private let configUrl = "http://newbeta.cliqz.com/api/v1/config"
    private let newsUrl = "https://newbeta.cliqz.com/api/v2/rich-header?"
    
	private var topSitesCollection: UICollectionView!
	private var newsTableView: UITableView!

	private lazy var emptyTopSitesHint: UILabel = {
		let lbl = UILabel()
		lbl.text = NSLocalizedString("Empty TopSites hint", tableName: "Cliqz", comment: "Hint on Freshtab when there is no topsites")
		lbl.font = UIFont.systemFontOfSize(12)
		lbl.textColor = UIColor.lightGrayColor()
		lbl.textAlignment = .Center
		return lbl
	}()
	private var normalModeView: UIView!
	private var forgetModeView: UIView!

	var isNewsExpanded = false
	var topSites = [[String: String]]()
    var topSitesIndexesToRemove = [Int]()
	var news = [[String: AnyObject]]()
    var region = SettingsPrefs.getRegionPref()

	weak var delegate: SearchViewDelegate?

	private static let forgetModeTextColor = UIColor(rgb: 0x999999)

	init(profile: Profile) {
		super.init(nibName: nil, bundle: nil)
		self.profile = profile
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loadTopsites), name: NotificationPrivateDataClearedHistory, object: nil)
	}
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.backgroundColor = UIConstants.AppBackgroundColor
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(cancelActions))
		tapGestureRecognizer.delegate = self
		self.view.addGestureRecognizer(tapGestureRecognizer)
        loadRegion()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
        region = SettingsPrefs.getRegionPref()
		updateView()
	}
	
	override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
		self.topSitesCollection.collectionViewLayout.invalidateLayout()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.topSitesCollection.collectionViewLayout.invalidateLayout()
	}

	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
		if gestureRecognizer is UITapGestureRecognizer {
			let location = touch.locationInView(self.topSitesCollection)
			if let index = self.topSitesCollection.indexPathForItemAtPoint(location),
				cell = self.topSitesCollection.cellForItemAtIndexPath(index) as? TopSiteViewCell {
				return cell.isDeleteMode
			}
			return true
		}
		return false
	}

    @objc private func cancelActions(sender: UITapGestureRecognizer) {
        
        self.removeDeletedTopSites()
        
        // fire `didSelectRowAtIndexPath` when user click on a cell in news table
        let p = sender.locationInView(self.newsTableView)
        if let selectedIndex = self.newsTableView.indexPathForRowAtPoint(p) {
            self.tableView(self.newsTableView, didSelectRowAtIndexPath: selectedIndex)
        }
        
	}
    
    private func removeDeletedTopSites(){
        
        let cells = self.topSitesCollection.visibleCells()
        for cell in cells as! [TopSiteViewCell] {
            cell.isDeleteMode = false
        }
        
        self.topSitesIndexesToRemove.sortInPlace{a,b in a > b} //order in descending order to avoid index mismatches
        for index in self.topSitesIndexesToRemove {
            self.topSites.removeAtIndex(index)
        }
        
        self.topSitesIndexesToRemove.removeAll()
        self.topSitesCollection.reloadData()
    }

	private func constructForgetModeView() {
		if forgetModeView == nil {
			forgetModeView = UIView()
			forgetModeView.backgroundColor = UIConstants.PrivateModeBackgroundColor
			self.view.addSubview(forgetModeView)
			self.forgetModeView.snp_makeConstraints(closure: { (make) in
				make.top.left.bottom.right.equalTo(self.view)
			})
			let title = UILabel()
			title.text = NSLocalizedString("Forget Tab", tableName: "Cliqz", comment: "Title on Freshtab for forget mode")
			title.numberOfLines = 1
			title.textAlignment = .Center
			title.font = UIFont.boldSystemFontOfSize(15)
			title.textColor = FreshtabViewController.forgetModeTextColor
			self.forgetModeView.addSubview(title)
			title.snp_makeConstraints(closure: { (make) in
				make.top.equalTo(self.forgetModeView).offset(20)
				make.left.right.equalTo(self.forgetModeView)
				make.height.equalTo(20)
			})
			
			let description = UILabel()
			description.text = NSLocalizedString("Forget Tab Description", tableName: "Cliqz", comment: "Description on Freshtab for forget mode")
			self.forgetModeView.addSubview(description)
			description.numberOfLines = 0
			description.textAlignment = .Center
			description.textColor = FreshtabViewController.forgetModeTextColor
			description.snp_makeConstraints(closure: { (make) in
				make.top.equalTo(title.snp_bottom).offset(20)
				make.left.equalTo(self.forgetModeView).offset(20)
				make.right.equalTo(self.forgetModeView).offset(-20)
			})
		}
	}
	
	private func constructNormalModeView() {
		if self.normalModeView == nil {
			self.normalModeView = UIView()
			self.normalModeView.backgroundColor = UIConstants.AppBackgroundColor
			self.view.addSubview(self.normalModeView)
			self.normalModeView.snp_makeConstraints(closure: { (make) in
				make.top.left.bottom.right.equalTo(self.view)
			})
		}
		if self.topSitesCollection == nil {
			self.topSitesCollection = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
			self.topSitesCollection.delegate = self
			self.topSitesCollection.dataSource = self
			self.topSitesCollection.backgroundColor = UIConstants.AppBackgroundColor
			self.topSitesCollection.registerClass(TopSiteViewCell.self, forCellWithReuseIdentifier: "TopSite")
			self.normalModeView.addSubview(self.topSitesCollection)
			self.topSitesCollection.snp_makeConstraints { (make) in
				make.top.equalTo(self.normalModeView)
				make.left.right.equalTo(self.normalModeView)
				make.height.equalTo(95)
			}
		}
		
		if self.newsTableView == nil {
			self.newsTableView = UITableView()
			self.newsTableView.delegate = self
			self.newsTableView.dataSource = self
			self.newsTableView.backgroundColor = UIConstants.AppBackgroundColor
			self.normalModeView.addSubview(self.newsTableView)
			self.newsTableView.tableFooterView = UIView()
			self.newsTableView.snp_makeConstraints { (make) in
				make.left.right.bottom.equalTo(self.view)
				make.top.equalTo(self.topSitesCollection.snp_bottom).offset(15)
			}
			newsTableView.registerClass(NewsViewCell.self, forCellReuseIdentifier: "NewsCell")
			newsTableView.separatorStyle = .None
		}
	}

	private func updateView() {
		if isForgetMode {
			self.constructForgetModeView()
			self.forgetModeView.hidden = false
			self.normalModeView?.hidden = true
		} else {
			self.constructNormalModeView()
			self.normalModeView.hidden = false
			self.forgetModeView?.hidden = true
		}
		if !isForgetMode {
			self.loadNews()
			self.loadTopsites()
		}
	}

	@objc private func loadTopsites() {
		self.loadTopSitesWithLimit(15)
        //self.topSitesCollection.reloadData()
	}
    
    private func loadRegion() {
        guard region == nil  else {
            return
        }
        
        Alamofire.request(.GET, configUrl, parameters: nil, encoding: .JSON, headers: nil).responseJSON { (response) in
            if response.result.isSuccess {
                if let location = response.result.value!["location"] as? String, backends = response.result.value!["backends"] as? [String]
                where backends.contains(location) {
                    
                    self.region = location.uppercaseString
                    SettingsPrefs.updateRegionPref(self.region!)
                    self.loadNews()
                }
            }
        }
    }
    
	private func loadNews() {
		self.news.removeAll()
		let data = ["q": "",
		            "results": [[ "url": "rotated-top-news.cliqz.com",  "snippet":[String:String]()]]
		]
        let userRegion = region != nil ? region : SettingsPrefs.getDefaultRegion()
		
        let uri  = "path=/v2/map&q=&lang=N/A&locale=\(NSLocale.currentLocale().localeIdentifier)&country=\(userRegion!)&adult=0&loc_pref=ask&count=5"
		
		Alamofire.request(.PUT, newsUrl + uri, parameters: data, encoding: .JSON, headers: nil).responseJSON { (response) in
			if response.result.isSuccess {
				if let result = response.result.value!["results"] as? [[String: AnyObject]] {
					if let snippet = result[0]["snippet"] as? [String: AnyObject],
						extra = snippet["extra"] as? [String: AnyObject],
						articles = extra["articles"] as? [[String: AnyObject]]
						{
							self.news = articles
							self.newsTableView?.reloadData()
						}
				}
			}
		}
	}

	private func loadTopSitesWithLimit(limit: Int) -> Success {
        print("[FreshTab] loadTopSitesWithLimit")
		return self.profile.history.getTopSitesWithLimit(limit).bindQueue(dispatch_get_main_queue()) { result in
			//var results = [[String: String]]()
			if let r = result.successValue {
				self.topSites.removeAll()
				var filter = Set<String>()
				for site in r {
					if let url = NSURL(string: site!.url),
						host = url.host {
						if !filter.contains(host) {
							var d = Dictionary<String, String>()
							d["url"] = site!.url
							d["title"] = site!.title
							filter.insert(host)
							self.topSites.append(d)
						}
					}
				}
			}
			if self.topSites.count == 0 {
				self.normalModeView.addSubview(self.emptyTopSitesHint)
				self.emptyTopSitesHint.snp_makeConstraints(closure: { (make) in
					make.top.equalTo(self.normalModeView).offset(3)
					make.left.right.top.equalTo(self.normalModeView)
					make.height.equalTo(14)
				})
			} else {
				self.emptyTopSitesHint.removeFromSuperview()
			}
            self.topSitesCollection.reloadData()
            
			return succeed()
		}
	}
	
	@objc private func showMoreNews() {
		self.isNewsExpanded = true
		self.newsTableView.reloadData()
	}
}

extension FreshtabViewController: UITableViewDataSource, UITableViewDelegate {
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if self.news.count >= 2 {
			return self.isNewsExpanded ? self.news.count : 2
		}
		return 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = self.newsTableView.dequeueReusableCellWithIdentifier("NewsCell", forIndexPath: indexPath) as! NewsViewCell
		if indexPath.row < self.news.count {
			var n = self.news[indexPath.row]
			let title = NSMutableAttributedString()
			if let b = n["breaking"] as? NSNumber,
				t = n["breaking_label"] as? String where b.boolValue == true {
				title.appendAttributedString(NSAttributedString(string: t.uppercaseString + ": ", attributes: [NSForegroundColorAttributeName: UIColor(rgb: 0xE64C66)]))
			}
			if let t = n["short_title"] as? String {
				title.appendAttributedString(NSAttributedString(string: t))
			} else if let t = n["title"] as? String {
				title.appendAttributedString(NSAttributedString(string: t))
			}
			cell.titleLabel.attributedText = title
			if let domain = n["domain"] as? String {
				cell.URLLabel.text = domain
			} else if let title = n["title"] as? String {
				cell.URLLabel.text =  title
			}
            
            cell.tag = indexPath.row
            
			if let url = n["url"] as? String {
                LogoLoader.loadLogoImageOrFakeLogo(url){(image: UIImage?, fakeLogo:UIView?, error: NSError?) in
                    if cell.tag == indexPath.row{
                        if let img = image {
                            cell.logoImageView.image = img
                        }
                        else if let fakeView = fakeLogo{
                            cell.fakeLogoView = fakeView
                            cell.logoContainerView.addSubview(fakeView)
                            fakeView.snp_makeConstraints(closure: { (make) in
                                make.top.left.right.bottom.equalTo(cell.logoContainerView)
                            })
                        }
                    }
                }
			}
		}
		cell.selectionStyle = .None
		return cell
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 85
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.row < self.news.count {
			let n = self.news[indexPath.row]
			let urlString = n["url"] as? String
			if let url = NSURL(string: urlString!) {
				delegate?.didSelectURL(url, searchQuery: nil)
			} else if let url = NSURL(string: urlString!.escapeURL()) {
				delegate?.didSelectURL(url, searchQuery: nil)
			}
		}
	}

	/*
	func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		if self.isNewsExpanded || self.news.count == 0 {
			return nil
		}
		let v = UIView()
		let btn = UIButton()
		btn.setTitle(NSLocalizedString("MoreNews", tableName: "Cliqz", comment: "Title to expand news stream"), forState: .Normal)
		v.addSubview(btn)
		btn.snp_makeConstraints { (make) in
			make.right.top.equalTo(v)
			make.height.equalTo(20)
			make.width.equalTo(150)
		}
		btn.addTarget(self, action: #selector(showMoreNews), forControlEvents: .TouchUpInside)
		btn.setTitleColor(UIColor.blueColor(), forState: .Normal)
		return v
	}
*/

	func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 0
	}

	func scrollViewDidScroll(scrollView: UIScrollView) {
		self.delegate?.dismissKeyboard()
	}
}

extension FreshtabViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func cellSize() -> CGSize {
        return CGSizeMake(76,76)
    }

	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 4
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("[FreshTab] cellForItemAtIndexPath -> row: \(indexPath.row)")
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TopSite", forIndexPath: indexPath) as! TopSiteViewCell
		cell.tag = -1
		cell.delegate = self
		if indexPath.row < self.topSites.count {
			cell.tag = indexPath.row
			let s = self.topSites[indexPath.row]
			if let url = s["url"] {
                LogoLoader.loadLogoImageOrFakeLogo(url){(image: UIImage?, fakeLogo:UIView?, error: NSError?) in
                    if cell.tag == indexPath.row{
                        if let img = image {
                            cell.logoImageView.image = img
                        }
                        else if let fakeView = fakeLogo{
                            cell.fakeLogoView = fakeView
                            cell.logoContainerView.addSubview(fakeView)
                            fakeView.snp_makeConstraints(closure: { (make) in
                                make.top.left.right.bottom.equalTo(cell.logoContainerView)
                            })
                        }
                    }
                }
			}
		}
		let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(deleteTopSites))
		cell.addGestureRecognizer(longPressGestureRecognizer)
		return cell
	}

	@objc private func deleteTopSites() {
		let cells = self.topSitesCollection.visibleCells()
		for cell in cells as! [TopSiteViewCell] {
			cell.isDeleteMode = true
		}
	}

	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		if indexPath.row < self.topSites.count && !self.topSitesIndexesToRemove.contains(indexPath.row){
			let s = self.topSites[indexPath.row]
			if let urlString = s["url"] {
				if let url = NSURL(string: urlString) {
					delegate?.didSelectURL(url, searchQuery: nil)
				} else if let url = NSURL(string: urlString.escapeURL()) {
					delegate?.didSelectURL(url, searchQuery: nil)
				}
			}
		}
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		return cellSize()
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let inset_edge = inset()
		return UIEdgeInsetsMake(10, inset_edge + 6, 0, inset_edge + 6)
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
		return inset() - 16
	}
    
    private func inset() -> CGFloat{
        let width = self.view.frame.size.width
        return ((width - 4 * cellSize().width)/5.0)
    }
    

}

extension FreshtabViewController: TopSiteCellDelegate {

	func topSiteHided(index: Int) {
		let s = self.topSites[index]
		if let url = s["url"] {
			self.profile.history.hideTopSite(url)
		}
        
        self.topSitesIndexesToRemove.append(index)
        
        if self.topSites.count == self.topSitesIndexesToRemove.count {
            self.removeDeletedTopSites()
        }
	}
}


