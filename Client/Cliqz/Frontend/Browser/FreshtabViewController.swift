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
			make.top.equalTo(self.topSitesCollection.snp_bottom)
		}
		self.topSitesCollection.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "TopSite")
	}

	init() {
		super.init(nibName: nil, bundle: nil)
		self.topSitesCollection = UICollectionView(frame: CGRectZero, collectionViewLayout: TopSiteCollectionViewLayout())
		self.topSitesCollection.delegate = self
		self.topSitesCollection.dataSource = self
		self.newsTableView = UITableView()
		self.newsTableView.delegate = self
		self.newsTableView.dataSource = self
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func loadTopsites() {
		self.reloadTopSitesWithLimit(15)
//		reloadTopSitesWithLimit(15, callback: callback) >>> {
//			return self.profile.history.updateTopSitesCacheIfInvalidated() >>== { result in
//				return result ? self.reloadTopSitesWithLimit(frecencyLimit, callback: callback) : succeed()
//			}
//		}
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
}

extension FreshtabViewController: UITableViewDataSource, UITableViewDelegate {
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 2
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return UITableViewCell()
	}

}

extension FreshtabViewController: UICollectionViewDataSource, UICollectionViewDelegate {

	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 5
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TopSite", forIndexPath: indexPath)
		cell.backgroundColor = UIColor.lightGrayColor()
		return cell
	}

}
