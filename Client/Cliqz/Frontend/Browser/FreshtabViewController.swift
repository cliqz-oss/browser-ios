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
import SwiftyJSON

struct FreshtabViewUX {

	static let TopSitesMinHeight = 95.0
	static let TopSitesMaxHeight = 185.0
	static let TopSitesCellSize = CGSize(width: 76, height: 86)
	static let TopSitesCountOnRow = 4
	static let TopSitesOffset = 5.0
	
	static let forgetModeTextColor = UIColor(rgb: 0x999999)
	static let forgetModeOffset = 50.0

}

class FreshtabViewController: UIViewController, UIGestureRecognizerDelegate {
    
	var profile: Profile!
	var isForgetMode = false {
		didSet {
			self.updateView()
		}
	}
    fileprivate let configUrl = "http://newbeta.cliqz.com/api/v1/config"
    fileprivate let newsUrl = "https://newbeta.cliqz.com/api/v2/rich-header?"
	
	// TODO: Change topSitesCollection to optional
	fileprivate var topSitesCollection: UICollectionView?
	fileprivate var newsTableView: UITableView?

	fileprivate lazy var emptyTopSitesHint: UILabel = {
		let lbl = UILabel()
		lbl.text = NSLocalizedString("Empty TopSites hint", tableName: "Cliqz", comment: "Hint on Freshtab when there is no topsites")
		lbl.font = UIFont.systemFont(ofSize: 12)
		lbl.textColor = UIColor.lightGray
		lbl.textAlignment = .center
		return lbl
	}()
	fileprivate var normalModeView: UIView!
	fileprivate var forgetModeView: UIView!

	var isNewsExpanded = false
	var topSites = [[String: String]]()
    var topSitesIndexesToRemove = [Int]()
	var news = [[String: Any]]()
    var region = SettingsPrefs.getRegionPref()

	weak var delegate: SearchViewDelegate?
    
    var startTime : Double = Date.getCurrentMillis()
    var isLoadCompleted = false


	init(profile: Profile) {
		super.init(nibName: nil, bundle: nil)
		self.profile = profile
        NotificationCenter.default.addObserver(self, selector: #selector(loadTopsites), name: NotificationPrivateDataClearedHistory, object: nil)
	}

    deinit {
        NotificationCenter.default.removeObserver(self)
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

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        startTime = Date.getCurrentMillis()
        isLoadCompleted = false
        
        region = SettingsPrefs.getRegionPref()
		updateView()
        topSitesCollection?.isHidden = true
        newsTableView?.isHidden = true
	}
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        logHideSignal()
    }

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		self.topSitesCollection?.collectionViewLayout.invalidateLayout()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.topSitesCollection?.collectionViewLayout.invalidateLayout()
	}

	override func updateViewConstraints() {
		super.updateViewConstraints()
		self.topSitesCollection?.snp_updateConstraints({ (make) in
			if self.topSites.count > FreshtabViewUX.TopSitesCountOnRow {
				make.height.equalTo(FreshtabViewUX.TopSitesMaxHeight)
			} else {
				make.height.equalTo(FreshtabViewUX.TopSitesMinHeight)
			}
		})
	}

	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		if gestureRecognizer is UITapGestureRecognizer {
			let location = touch.location(in: self.topSitesCollection)
			if let index = self.topSitesCollection?.indexPathForItem(at: location),
				let cell = self.topSitesCollection?.cellForItem(at: index) as? TopSiteViewCell {
				return cell.isDeleteMode
			}
			return true
		}
		return false
	}

    @objc fileprivate func cancelActions(_ sender: UITapGestureRecognizer) {
		if !isForgetMode {
			self.removeDeletedTopSites()
			
			// fire `didSelectRowAtIndexPath` when user click on a cell in news table
			let p = sender.location(in: self.newsTableView)
			if let selectedIndex = self.newsTableView?.indexPathForRow(at: p) {
				self.tableView(self.newsTableView!, didSelectRowAt: selectedIndex)
			}
		}
	}
    
    fileprivate func removeDeletedTopSites() {
		if let cells = self.topSitesCollection?.visibleCells as? [TopSiteViewCell] {
			for cell in cells {
				cell.isDeleteMode = false
			}
			
			self.topSitesIndexesToRemove.sort{a,b in a > b} //order in descending order to avoid index mismatches
			for index in self.topSitesIndexesToRemove {
				self.topSites.remove(at: index)
			}
			
            logTopsiteEditModeSignal()
			self.topSitesIndexesToRemove.removeAll()
			self.topSitesCollection?.reloadData()
			self.updateViewConstraints()
		}
    }

	fileprivate func constructForgetModeView() {
		if forgetModeView == nil {
			self.forgetModeView = UIView()
			self.forgetModeView.backgroundColor = UIConstants.PrivateModeBackgroundColor
			let blurEffect = UIVisualEffectView(effect: UIBlurEffect(style: .light))
			self.forgetModeView.addSubview(blurEffect)
			self.forgetModeView.snp_makeConstraints({ (make) in
				make.top.left.right.bottom.equalTo(self.forgetModeView)
			})
			self.view.backgroundColor = UIColor.clear
			self.view.addSubview(forgetModeView)
			self.forgetModeView.snp_makeConstraints({ (make) in
				make.top.left.bottom.right.equalTo(self.view)
			})
			let iconImg = UIImage(named: "forgetModeIcon")
			let forgetIcon = UIImageView(image: iconImg!.withRenderingMode(.alwaysTemplate))
			forgetIcon.tintColor = UIColor(white: 1, alpha: 0.57)
			self.forgetModeView.addSubview(forgetIcon)
			forgetIcon.snp_makeConstraints({ (make) in
				make.top.equalTo(self.forgetModeView).offset(FreshtabViewUX.forgetModeOffset)
				make.centerX.equalTo(self.forgetModeView)
			})

			let title = UILabel()
			title.text = NSLocalizedString("Forget Tab", tableName: "Cliqz", comment: "Title on Freshtab for forget mode")
			title.numberOfLines = 1
			title.textAlignment = .center
			title.font = UIFont.boldSystemFont(ofSize: 19)
			title.textColor = UIColor(white: 1, alpha: 0.57)
			self.forgetModeView.addSubview(title)
			title.snp_makeConstraints({ (make) in
				make.top.equalTo(forgetIcon.snp_bottom).offset(20)
				make.left.right.equalTo(self.forgetModeView)
				make.height.equalTo(20)
			})
			
			let description = UILabel()
			description.text = NSLocalizedString("Forget Tab Description", tableName: "Cliqz", comment: "Description on Freshtab for forget mode")
			self.forgetModeView.addSubview(description)
			description.numberOfLines = 0
			description.textAlignment = .center
			description.font = UIFont.systemFont(ofSize: 13)
			description.textColor = UIColor(white: 1, alpha: 0.57)
			description.textColor = FreshtabViewUX.forgetModeTextColor
			description.snp_makeConstraints({ (make) in
				make.top.equalTo(title.snp_bottom).offset(15)
				make.left.equalTo(self.forgetModeView).offset(FreshtabViewUX.forgetModeOffset)
				make.right.equalTo(self.forgetModeView).offset(-FreshtabViewUX.forgetModeOffset)
			})
		}
	}
	
	fileprivate func constructNormalModeView() {
		if self.normalModeView == nil {
			self.normalModeView = UIView()
			self.normalModeView.backgroundColor = UIConstants.AppBackgroundColor
			self.view.addSubview(self.normalModeView)
			self.normalModeView.snp_makeConstraints({ (make) in
				make.top.left.bottom.right.equalTo(self.view)
			})
		}
		if self.topSitesCollection == nil {
			self.topSitesCollection = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
			self.topSitesCollection?.delegate = self
			self.topSitesCollection?.dataSource = self
			self.topSitesCollection?.backgroundColor = UIConstants.AppBackgroundColor
			self.topSitesCollection?.register(TopSiteViewCell.self, forCellWithReuseIdentifier: "TopSite")
			self.topSitesCollection?.isScrollEnabled = false
			self.normalModeView.addSubview(self.topSitesCollection!)
			self.topSitesCollection?.snp_makeConstraints { (make) in
				make.top.equalTo(self.normalModeView)
				make.left.equalTo(self.normalModeView).offset(FreshtabViewUX.TopSitesOffset)
				make.right.equalTo(self.normalModeView).offset(-FreshtabViewUX.TopSitesOffset)
				make.height.equalTo(FreshtabViewUX.TopSitesMinHeight)
			}
            self.topSitesCollection?.accessibilityLabel = "topSites"
		}
		
		if self.newsTableView == nil {
			self.newsTableView = UITableView()
			self.newsTableView?.delegate = self
			self.newsTableView?.dataSource = self
			self.newsTableView?.backgroundColor = UIConstants.AppBackgroundColor
			self.normalModeView.addSubview(self.newsTableView!)
			self.newsTableView?.tableFooterView = UIView()
			self.newsTableView?.snp_makeConstraints { (make) in
				make.left.right.bottom.equalTo(self.view)
				make.top.equalTo(self.topSitesCollection!.snp_bottom).offset(5)
			}
			newsTableView?.register(NewsViewCell.self, forCellReuseIdentifier: "NewsCell")
			newsTableView?.separatorStyle = .none
            self.newsTableView?.accessibilityLabel = "topNews"
		}
	}

	fileprivate func updateView() {
		if isForgetMode {
			self.constructForgetModeView()
			self.forgetModeView.isHidden = false
			self.normalModeView?.isHidden = true
		} else {
			self.constructNormalModeView()
			self.normalModeView.isHidden = false
			self.forgetModeView?.isHidden = true
		}
		if !isForgetMode {
			self.loadNews()
			self.loadTopsites()
		}
	}

	@objc fileprivate func loadTopsites() {
		self.loadTopSitesWithLimit(15)
        //self.topSitesCollection?.reloadData()
	}
    
    fileprivate func loadRegion() {
        guard region == nil  else {
            return
        }
        
		Alamofire.request(configUrl, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.result.isSuccess {
				if let data = response.result.value as? [String: Any] {
					if let location = data["location"] as? String, let backends = data["backends"] as? [String], backends.contains(location) {
						
						self.region = location.uppercased()
						SettingsPrefs.updateRegionPref(self.region!)
						self.loadNews()
					}
				}
            }
        }
    }

	fileprivate func loadNews() {
		self.news.removeAll()
		let data = ["q": "",
		            "results": [[ "url": "rotated-top-news.cliqz.com",  "snippet":[String:String]()]]
		] as [String : Any]
        let userRegion = region != nil ? region : SettingsPrefs.getDefaultRegion()
		
        let uri  = "path=/v2/map&q=&lang=N/A&locale=\(Locale.current.identifier)&country=\(userRegion!)&adult=0&loc_pref=ask&count=5"

		Alamofire.request(newsUrl + uri, method: .put, parameters: data, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
			if response.result.isSuccess {
				if let data = response.result.value as? [String: Any],
					let result = data["results"] as? [[String: Any]] {
					if let snippet = result[0]["snippet"] as? [String: Any],
						let extra = snippet["extra"] as? [String: Any],
						let articles = extra["articles"] as? [[String: Any]]
						{
							self.news = articles
							self.newsTableView?.reloadData()
                            if !self.isLoadCompleted {
                                self.isLoadCompleted = true
                                self.logShowSignal()
                            }
					}
				}
			}
		}
	}

	fileprivate func loadTopSitesWithLimit(_ limit: Int) -> Success {
		return self.profile.history.getTopSitesWithLimit(limit).bindQueue(DispatchQueue.main) { result in
			//var results = [[String: String]]()
			if let r = result.successValue {
				self.topSites.removeAll()
				var filter = Set<String>()
				for site in r {
					if let url = URL(string: site!.url),
						let host = url.host {
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
				self.emptyTopSitesHint.snp_makeConstraints({ (make) in
					make.top.equalTo(self.normalModeView).offset(3)
					make.left.right.top.equalTo(self.normalModeView)
					make.height.equalTo(14)
				})
			} else {
				self.emptyTopSitesHint.removeFromSuperview()
			}
			self.updateViewConstraints()
            self.topSitesCollection?.reloadData()
            
			return succeed()
		}
	}
	
	@objc fileprivate func showMoreNews() {
		self.isNewsExpanded = true
		self.newsTableView?.reloadData()
	}
}

extension FreshtabViewController: UITableViewDataSource, UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if self.news.count >= 2 {
			return self.isNewsExpanded ? self.news.count : 2
		}
		return 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = self.newsTableView?.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath) as! NewsViewCell
		if indexPath.row < self.news.count {
			var n = self.news[indexPath.row]
			let title = NSMutableAttributedString()
			if let b = n["breaking"] as? NSNumber,
				let t = n["breaking_label"] as? String, b.boolValue == true {
				title.append(NSAttributedString(string: t.uppercased() + ": ", attributes: [NSForegroundColorAttributeName: UIColor(rgb: 0xE64C66)]))
			}
			if let t = n["short_title"] as? String {
				title.append(NSAttributedString(string: t))
			} else if let t = n["title"] as? String {
				title.append(NSAttributedString(string: t))
			}
			cell.titleLabel.attributedText = title
			if let domain = n["domain"] as? String {
				cell.URLLabel.text = domain
			} else if let title = n["title"] as? String {
				cell.URLLabel.text =  title
			}
            
            cell.tag = indexPath.row
            
			if let url = n["url"] as? String {
				LogoLoader.loadLogo(url, completionBlock: { (image, logoInfo, error) in
					if cell.tag == indexPath.row {
						if let img = image {
							cell.logoImageView.image = img
						}
//						else if let fakeView = fakeLogo {
//							cell.fakeLogoView = fakeView
//							cell.logoContainerView.addSubview(fakeView)
//							fakeView.snp_makeConstraints({ (make) in
//								make.top.left.right.bottom.equalTo(cell.logoContainerView)
//							})
//						}
					}
				})
			}
		}
		cell.selectionStyle = .none
		return cell
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 85
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row < self.news.count {
			let selectedNews = self.news[indexPath.row]
			let urlString = selectedNews["url"] as? String
			if let url = URL(string: urlString!) {
				delegate?.didSelectURL(url, searchQuery: nil)
			} else if let url = URL(string: urlString!.escapeURL()) {
				delegate?.didSelectURL(url, searchQuery: nil)
			}
            
            if let currentCell = tableView.cellForRow(at: indexPath) as? NewsViewCell, let isBreakingNews = selectedNews["breaking"] as? Bool {
                let target  = isBreakingNews ? "breakingnews" : "topnews"
                logNewsSignal(target, element: currentCell.clickedElement, index: indexPath.row)
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

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 0
	}

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
//		self.delegate?.dismissKeyboard()
	}
}

extension FreshtabViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
	
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.topSites.count > FreshtabViewUX.TopSitesCountOnRow ? 2 * FreshtabViewUX.TopSitesCountOnRow : FreshtabViewUX.TopSitesCountOnRow
	}
	
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopSite", for: indexPath) as! TopSiteViewCell
		cell.tag = -1
		cell.delegate = self
		if indexPath.row < self.topSites.count {
			cell.tag = indexPath.row
			let s = self.topSites[indexPath.row]
			if let url = s["url"] {
				LogoLoader.loadLogo(url, completionBlock: { (image, logoInfo, error) in
					if cell.tag == indexPath.row {
						if let img = image {
							cell.logoImageView.image = img
						}
//						else if let fakeView = fakeLogo {
//							cell.fakeLogoView = fakeView
//							cell.logoContainerView.addSubview(fakeView)
//							fakeView.snp_makeConstraints({ (make) in
//								make.top.left.right.bottom.equalTo(cell.logoContainerView)
//							})
//						}
					}
				})
//				let hostComponents = getHostComponents(forURL: url)
//				cell.logoHostLabel.text = hostComponents[0].capitalized
			}
		}
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(deleteTopSites(_:)))
		cell.addGestureRecognizer(longPressGestureRecognizer)
        cell.tag = indexPath.row
		return cell
	}

	@objc private func deleteTopSites(_ gestureReconizer: UILongPressGestureRecognizer)  {
		let cells = self.topSitesCollection?.visibleCells
		for cell in cells as! [TopSiteViewCell] {
			cell.isDeleteMode = true
		}
        
        if let index = gestureReconizer.view?.tag {
            logTopsiteSignal(action: "longpress", index: index)
        }
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if indexPath.row < self.topSites.count && !self.topSitesIndexesToRemove.contains(indexPath.row) {
			let s = self.topSites[indexPath.row]
			if let urlString = s["url"] {
				if let url = URL(string: urlString) {
					delegate?.didSelectURL(url, searchQuery: nil)
				} else if let url = URL(string: urlString.escapeURL()) {
					delegate?.didSelectURL(url, searchQuery: nil)
				}
                
                logTopsiteSignal(action: "click", index: indexPath.row)
			}
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return FreshtabViewUX.TopSitesCellSize
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 3.0
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsetsMake(10, sideInset(collectionView), 0, sideInset(collectionView))
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return cellSpacing(collectionView)
	}
    
    func sideInset(_ collectionView: UICollectionView) -> CGFloat {
        //Constraint = cellSpacing should never be negative
        let v = collectionView.frame.size.width - CGFloat(FreshtabViewUX.TopSitesCountOnRow) * FreshtabViewUX.TopSitesCellSize.width
        
        if v > 0 {
            let inset = v / 5.0
            return floor(inset)
        }
        
        return 0.0
    }
    
    func cellSpacing(_ collectionView: UICollectionView) -> CGFloat{
        let inset = sideInset(collectionView)
        if inset > 1.0 {
            return inset - 1
        }
        return 0.0
    }
    
}

extension FreshtabViewController: TopSiteCellDelegate {

	func topSiteHided(_ index: Int) {
		let s = self.topSites[index]
		if let url = s["url"] {
			self.profile.history.hideTopSite(url)
		}
        
        self.topSitesIndexesToRemove.append(index)
        logDeleteTopsiteSignal(index)
        
        if self.topSites.count == self.topSitesIndexesToRemove.count {
            self.removeDeletedTopSites()
        }
	}
}

// extension for telemetry signals
extension FreshtabViewController {
    fileprivate func logTopsiteSignal(action: String, index: Int) {
     
        let customData: [String: Any] = ["topsite_count": topSites.count, "index": index]
        self.logFreshTabSignal(action, target: "topsite", customData: customData)
    }
    
    fileprivate func logDeleteTopsiteSignal(_ index: Int) {
        let customData: [String: Any] = ["index": index]
        self.logFreshTabSignal("click", target: "delete_topsite", customData: customData)
    }
    
    fileprivate func logTopsiteEditModeSignal() {
        let customData: [String: Any] = ["topsite_count": topSites.count, "delete_count": topSitesIndexesToRemove.count, "view": "topsite_edit_mode"]
        self.logFreshTabSignal("click", target: nil, customData: customData)
    }
    
    fileprivate func logNewsSignal(_ target: String, element: String, index: Int) {
        
        let customData: [String: Any] = ["element": element, "index": index]
        self.logFreshTabSignal("click", target: target, customData: customData)
    }
    
    fileprivate func logShowSignal() {
        let loadDuration = Int(Date.getCurrentMillis() - startTime)
        var customData: [String: Any] = ["topsite_count": topSites.count, "load_duration": loadDuration]
        if isLoadCompleted {
            customData["is_complete"] = true
            let breakingNews = news.filter() {
                if let breaking = ($0 as NSDictionary)["breaking"] as? Bool {
                    return breaking
                } else {
                    return false
                }
            }
            customData["topnews_count"] = news.count - breakingNews.count
            customData["breakingnews_count"] = breakingNews.count
        } else {
            customData["is_complete"] = false
            customData["topnews_count"] = 0
            customData["breakingnews_count"] = 0
        }
        logFreshTabSignal("show", target: nil, customData: customData)

    }
    
    fileprivate func logHideSignal() {
        if !isLoadCompleted {
            logShowSignal()
        }
        let showDuration = Int(Date.getCurrentMillis() - startTime)
        logFreshTabSignal("hide", target: nil, customData: ["show_duration": showDuration])
    }

    private func logFreshTabSignal(_ action: String, target: String?, customData: [String: Any]?) {
        TelemetryLogger.sharedInstance.logEvent(.FreshTab(action, target, customData))
    }
    
}
