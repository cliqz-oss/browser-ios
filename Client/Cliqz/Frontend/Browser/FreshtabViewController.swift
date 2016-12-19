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

class TopSiteCollectionViewLayout: UICollectionViewFlowLayout {
	override init() {
		super.init()
		minimumInteritemSpacing = 10
		sectionInset = UIEdgeInsetsMake(10, 20, 0, 20)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func cellSizeForCollectionView(collectionView: UICollectionView) -> CGSize {
		return CGSize(width: 50, height: 50)
	}
}

class FreshtabViewController: UIViewController {

	var topSitesCollection: UICollectionView!
	var newsTableView: UITableView!

	var topSites = [[String: String]]()
	var news = [[String: AnyObject]]()
	var profile: Profile!
	
	weak var delegate: SearchViewDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.addSubview(self.topSitesCollection)
		self.topSitesCollection.snp_makeConstraints { (make) in
			make.top.equalTo(self.view).offset(30)
			make.left.right.equalTo(self.view)
			make.height.equalTo(70)
		}
		self.view.addSubview(self.newsTableView)
		self.newsTableView.tableFooterView = UIView()
		self.newsTableView.snp_makeConstraints { (make) in
			make.left.right.bottom.equalTo(self.view)
			make.top.equalTo(self.topSitesCollection.snp_bottom).offset(30)
		}
		self.topSitesCollection.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "TopSite")
		newsTableView.registerClass(NewsViewCell.self, forCellReuseIdentifier: "NewsCell")
		newsTableView.separatorStyle = .None
		loadNews()
		loadTopsites()
	}

	init(profile: Profile) {
		super.init(nibName: nil, bundle: nil)
		self.profile = profile
		self.topSitesCollection = UICollectionView(frame: CGRectZero, collectionViewLayout: TopSiteCollectionViewLayout())
		self.topSitesCollection.delegate = self
		self.topSitesCollection.dataSource = self
		self.topSitesCollection.backgroundColor = UIColor(rgb: 0xE8E8E8)
		self.newsTableView = UITableView()
		self.newsTableView.delegate = self
		self.newsTableView.dataSource = self
		self.newsTableView.scrollEnabled = false
		self.newsTableView.backgroundColor = UIColor(rgb: 0xE8E8E8)
		self.view.backgroundColor = UIColor(rgb: 0xE8E8E8)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func loadTopsites() {
		self.topSites.removeAll()
		self.reloadTopSitesWithLimit(15)
//		reloadTopSitesWithLimit(15, callback: callback) >>> {
//			return self.profile.history.updateTopSitesCacheIfInvalidated() >>== { result in
//				return result ? self.reloadTopSitesWithLimit(frecencyLimit, callback: callback) : succeed()
//			}
//		}
	}
	
	private func escape(string: String) -> String {
		let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
		let subDelimitersToEncode = "!$&'()*+,;="
		
		let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
		allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode + subDelimitersToEncode)
		
		var escaped = ""
		
		if #available(iOS 8.3, OSX 10.10, *) {
			escaped = string.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? string
		} else {
			let batchSize = 50
			var index = string.startIndex
			
			while index != string.endIndex {
				let startIndex = index
				let endIndex = index.advancedBy(batchSize, limit: string.endIndex)
				let range = startIndex..<endIndex
				
				let substring = string.substringWithRange(range)
				
				escaped += substring.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? substring
				
				index = endIndex
			}
		}
		return escaped
	}
	
	func loadNews() {
		self.news.removeAll()
		let data = ["q": "",
		            "results": [[ "url": "rotated-top-news.cliqz.com",  "snippet":[String:String]()]]
		]
		let url = "https://newbeta.cliqz.com/api/v2/rich-header?"
		let uri  = "path=/v2/map&q=&lang=de,en&locale=en-US&force_country=true&adult=0&loc_pref=ask&count=5"
		
		Alamofire.request(.PUT, url + uri, parameters: data, encoding: .JSON, headers: nil).responseJSON { (response) in
			if let result = response.result.value!["results"] as? [[String: AnyObject]] {
				if let snippet = result[0]["snippet"] as? [String: AnyObject],
					extra = snippet["extra"] as? [String: AnyObject],
					articles = extra["articles"] as? [[String: AnyObject]]
					{
						self.news = articles
						self.newsTableView.reloadData()
						print("ddd --- \(articles)")
					}
				print("RRRR -- \(response.result.value)")
			}
		}
	}

	private func reloadTopSitesWithLimit(limit: Int) -> Success {
		return self.profile.history.getTopSitesWithLimit(limit).bindQueue(dispatch_get_main_queue()) { result in
			//var results = [[String: String]]()
			if let r = result.successValue {
				for site in r {
					var d = Dictionary<String, String>()
					d["url"] = site!.url
					d["title"] = site!.title
					self.topSites.append(d)
				}
			}
			self.topSitesCollection.reloadData()
			return succeed()
		}
	}

	private func logoURL(forHostURL: String) -> NSURL? {
		if let url = NSURL(string: forHostURL) {
			let host = url.host
			let comps = host?.componentsSeparatedByString(".")
			var first = ""
			var second = ""
			if comps?.count >= 2 {
				if comps?[0] == "www" {
					first = (comps?[1])!
				} else {
					first = (comps?[0])!
				}
			}
			if comps?[0] == "www" {
				if comps?.count > 3 {
					second = "\((comps?[2])!)."
				}
			} else {
				if comps?.count > 2 {
					second = "\((comps?[1])!)."
				}
			}
			let x = "http://cdn.cliqz.com/brands-database/database/1481192095135/pngs/\(first)/\(second)$_72x72.png"
			return NSURL(string: x)
		}
		return nil
	}
}

extension FreshtabViewController: UITableViewDataSource, UITableViewDelegate {
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if self.news.count >= 2 {
			return 2
		}
		return 0
	}
	
//	
//	return {
//	breaking: r.breaking,
//	title: r.title,
//	description: r.description,
//	short_title: r.short_title || r.title,
//	displayUrl: details.domain || r.title,
//	url: r.url,
//	text: logo.text,
//	backgroundColor: logo.backgroundColor,
//	buttonsClass: logo.buttonsClass,
//	style: logo.style,
//	type,
//	};
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = self.newsTableView.dequeueReusableCellWithIdentifier("NewsCell", forIndexPath: indexPath) as! NewsViewCell
		if indexPath.row < self.news.count {
			let n = self.news[indexPath.row]
			if let title = n["short_title"] as? String {
				cell.titleLabel.text = title
			} else if let title = n["title"] as? String {
				cell.titleLabel.text = title
			}
			if let domain = n["domain"] as? String {
				cell.URLLabel.text = domain
			} else if let title = n["title"] as? String {
				cell.URLLabel.text =  title
			}
			if let url = n["url"] as? String,
				logoURL = self.logoURL(url) {
				cell.logoImageView.sd_setImageWithURL(logoURL)
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
}

extension FreshtabViewController: UICollectionViewDataSource, UICollectionViewDelegate {

	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 5
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TopSite", forIndexPath: indexPath)
		cell.backgroundColor = UIColor.lightGrayColor()
		if indexPath.row < self.topSites.count {
			let s = self.topSites[indexPath.row]
			if let url = s["url"] {
//				let host = url.host
//				let comps = host?.componentsSeparatedByString(".")
//				var first = ""
//				var second = ""
//				if comps?.count >= 2 {
//					if comps?[0] == "www" {
//						first = (comps?[1])!
//					} else {
//						first = (comps?[0])!
//					}
//				}
//				if comps?[0] == "www" {
//					if comps?.count > 3 {
//						second = "\((comps?[2])!)."
//					}
//				} else {
//					if comps?.count > 2 {
//						second = "\((comps?[1])!)."
//					}
//				}
//
//				let x = "http://cdn.cliqz.com/brands-database/database/1481192095135/pngs/\(first)/\(second)$_72x72.png"
				if let imageURL = logoURL(url) {
					let iv = UIImageView()
					iv.sd_setImageWithURL(imageURL, completed: {(img, err, cacheType, url) in
						if err != nil {
							let v = UIView()
							v.backgroundColor = UIColor.blackColor()
							let l = UILabel()
							l.textColor = UIColor.whiteColor()
							l.text = "AI"//first.substringToIndex(first.startIndex.advancedBy(2)).uppercaseString
							v.addSubview(l)
							l.snp_makeConstraints(closure: { (make) in
								make.center.equalTo(v)
							})
							cell.contentView.addSubview(v)
							v.snp_makeConstraints(closure: { (make) in
								make.left.right.top.bottom.equalTo(cell.contentView)
							})
						}
					})
					cell.contentView.addSubview(iv)
					iv.snp_makeConstraints(closure: { (make) in
						make.left.right.top.bottom.equalTo(cell.contentView)
					})
				}
			}
		}
		return cell
	}

	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		if indexPath.row < self.topSites.count {
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
}


class NewsViewCell: UITableViewCell {
	
	let titleLabel = UILabel()
	let URLLabel = UILabel()
	let logoImageView = UIImageView()
	let cardView = UIView()
	var clickedElement: String?
	
	var isPrivateTabCell: Bool = false {
		didSet {
			cardView.backgroundColor = UIColor.whiteColor()
			titleLabel.textColor = self.textColor()
			setNeedsDisplay()
		}
	}
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.contentView.backgroundColor = UIConstants.AppBackgroundColor
		cardView.backgroundColor = UIColor.whiteColor()
		cardView.layer.cornerRadius = 4
		contentView.addSubview(cardView)
		cardView.addSubview(titleLabel)
		titleLabel.font = UIFont.systemFontOfSize(16, weight: UIFontWeightMedium)
		titleLabel.textColor = self.textColor()
		titleLabel.backgroundColor = UIColor.clearColor()
		cardView.addSubview(URLLabel)
		URLLabel.font = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
		URLLabel.textColor = UIColor(rgb: 0x77ABE6)
		URLLabel.backgroundColor = UIColor.clearColor()
		titleLabel.numberOfLines = 2
		cardView.addSubview(logoImageView)
		self.isPrivateTabCell = false
		
		// tab gesture recognizer
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapPressed(_:)))
		tapGestureRecognizer.cancelsTouchesInView = false
		tapGestureRecognizer.delegate = self
		self.addGestureRecognizer(tapGestureRecognizer)
		
	}
	
	func tapPressed(gestureRecognizer: UIGestureRecognizer) {
		let touchLocation = gestureRecognizer.locationInView(self.cardView)
		
		if CGRectContainsPoint(titleLabel.frame, touchLocation) {
			clickedElement = "title"
		} else if CGRectContainsPoint(URLLabel.frame, touchLocation) {
			clickedElement = "url"
		} else if CGRectContainsPoint(logoImageView.frame, touchLocation) {
			clickedElement = "logo"
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		let cardViewLeftOffset = 25
		let cardViewRightOffset = -25
		let cardViewTopOffset = 5
		let cardViewBottomOffset = -5
		self.cardView.snp_remakeConstraints { (make) in
			make.left.equalTo(self.contentView).offset(cardViewLeftOffset)
			make.right.equalTo(self.contentView).offset(cardViewRightOffset)
			make.top.equalTo(self.contentView).offset(cardViewTopOffset)
			make.bottom.equalTo(self.contentView).offset(cardViewBottomOffset)
		}
		
		let contentLeftOffset = 15
		let logoSize = CGSizeMake(28, 28)
		self.logoImageView.snp_remakeConstraints { (make) in
			make.top.equalTo(self.cardView)
			make.left.equalTo(self.cardView).offset(contentLeftOffset)
//			if let _ = self.logoImageView.image {
				make.size.equalTo(logoSize)
//			} else {
//				make.size.equalTo(CGSizeMake(0, 0))
//			}
		}
		let URLLeftOffset = 15
		let URLHeight = 24
		self.URLLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.cardView).offset(7)
//			if let _ = self.logoImageView.image {
				make.left.equalTo(self.logoImageView.snp_right).offset(URLLeftOffset)
//			} else {
//				make.left.equalTo(self.cardView).offset(URLLeftOffset)
//			}
			make.height.equalTo(URLHeight)
			make.right.equalTo(self.cardView)
		}
		self.titleLabel.snp_remakeConstraints { (make) in
			if let _ = self.logoImageView.image {
				make.top.equalTo(self.logoImageView.snp_bottom)
			} else {
				make.top.equalTo(self.URLLabel.snp_bottom)
			}
			make.left.equalTo(self.cardView).offset(contentLeftOffset)
			make.height.equalTo(40)
			make.right.equalTo(self.cardView)
		}
	}
	
	override func prepareForReuse() {
		self.cardView.transform = CGAffineTransformIdentity
		self.cardView.alpha = 1
	}
	
	private func textColor() -> UIColor {
		return isPrivateTabCell ? UIConstants.PrivateModeTextColor : UIConstants.NormalModeTextColor
	}
	
}
