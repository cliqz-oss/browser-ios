//
//  AntitrackingViewController.swift
//  Client
//
//  Created by Sahakyan on 8/29/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class AntitrackingViewController: UIViewController {

	private var blurryBackgroundView: UIVisualEffectView!
	private let titleLabel = UILabel()
	private let titleIcon = UIImageView()
	private let trackersCountLabel = UILabel()
	private let subtitleLabel = UILabel()

	private let trackersTableView = UITableView()

	private let helpButton = UIButton(type: .Custom)

	private let antitrackingGreen = UIColor(rgb: 0x2CBA84)

	private let trackedWebViewID: Int!
	private let trackersList: [(String, Int)]!

	private let trackerCellIdentifier = "TabCell"

	init(webViewID: Int) {
		trackedWebViewID = webViewID
		trackersList = AntiTrackingModule.sharedInstance.getAntiTrackingStatistics(trackedWebViewID)
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		let blurEffect = UIBlurEffect(style: .Light)
		self.blurryBackgroundView = UIVisualEffectView(effect: blurEffect)
		self.view.insertSubview(blurryBackgroundView, atIndex: 0)

		titleLabel.textColor = antitrackingGreen
		titleLabel.font = UIFont.systemFontOfSize(22)
		titleLabel.textAlignment = .Center
		self.view.addSubview(titleLabel)
		titleLabel.text = NSLocalizedString("Data is protected", tableName: "Cliqz", comment: "Antitracking UI top title")

		let img = UIImage(named: "shieldIcon")
		titleIcon.image = img!.imageWithRenderingMode(.AlwaysTemplate)
		titleIcon.tintColor = antitrackingGreen
		self.view.addSubview(titleIcon)

		trackersCountLabel.textColor = UIColor.blackColor()
		trackersCountLabel.font = UIFont.systemFontOfSize(30)
		self.view.addSubview(trackersCountLabel)
		trackersCountLabel.textAlignment = .Center

		subtitleLabel.textColor = antitrackingGreen
		subtitleLabel.font = UIFont.boldSystemFontOfSize(16)
		subtitleLabel.textAlignment = .Center
		self.view.addSubview(subtitleLabel)
		subtitleLabel.text = NSLocalizedString("Private data points", tableName: "Cliqz", comment: "Persönliche Daten wurden entfernt")
		
		trackersTableView.registerClass(TrackerViewCell.self, forCellReuseIdentifier: self.trackerCellIdentifier)
		trackersTableView.delegate = self
		trackersTableView.dataSource = self
		trackersTableView.backgroundColor = UIColor.clearColor()
		trackersTableView.tableFooterView = UIView()
		trackersTableView.separatorStyle = .None
		trackersTableView.clipsToBounds = true
		self.view.addSubview(trackersTableView)

		let tap = UITapGestureRecognizer(target: self, action: #selector(tapRecognizer))
		self.view.addGestureRecognizer(tap)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.setupConstraints()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.trackersCountLabel.text = "\(AntiTrackingModule.sharedInstance.getTrackersCount(self.trackedWebViewID))"
	}

	@objc func tapRecognizer(sender: UITapGestureRecognizer) {
		let p = sender.locationInView(self.view)
		if p.y <= 44 {
			UIView.animateWithDuration(0.5, animations: {
				var p = self.view.center
				p.y -= self.view.frame.size.height
				self.view.center = p
				}) { (finished) in
					if finished {
						self.view.removeFromSuperview()
						self.removeFromParentViewController()
					}
				}
		}
	}

	private func setupConstraints() {
		blurryBackgroundView.snp_makeConstraints { (make) in
			make.left.right.bottom.equalTo(self.view)
			make.top.equalTo(self.view).offset(44)
		}
		titleLabel.snp_makeConstraints { make in
			make.left.right.equalTo(self.view)
			make.top.equalTo(self.view).offset(88)
			make.height.equalTo(24)
		}
		titleIcon.snp_makeConstraints { make in
			make.centerX.equalTo(self.view)
			make.top.equalTo(titleLabel.snp_bottom).offset(20)
		}
		trackersCountLabel.snp_makeConstraints { make in
			make.left.right.equalTo(self.view)
			make.top.equalTo(titleIcon.snp_bottom).offset(7)
			make.height.equalTo(30)
		}
		subtitleLabel.snp_makeConstraints { make in
			make.left.right.equalTo(self.view)
			make.top.equalTo(trackersCountLabel.snp_bottom).offset(7)
			make.height.equalTo(20)
		}
		trackersTableView.snp_makeConstraints { (make) in
			make.left.equalTo(self.view).offset(25)
			make.right.equalTo(self.view).offset(-25)
			make.top.equalTo(subtitleLabel.snp_bottom).offset(10)
			make.bottom.equalTo(self.view)
		}
	}
}

extension AntitrackingViewController: UITableViewDataSource, UITableViewDelegate {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.trackersList.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = self.trackersTableView.dequeueReusableCellWithIdentifier(trackerCellIdentifier, forIndexPath: indexPath) as! TrackerViewCell
		let item = self.trackersList[indexPath.row]
		cell.nameLabel.text = item.0
		cell.countLabel.text = "\(item.1)"
		cell.selectionStyle = .None
		cell.backgroundColor = UIColor.clearColor()
		return cell
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 30
	}

	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 30
	}
	
	func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 15
	}

	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let header = UIView()
		header.backgroundColor = UIColor.clearColor()
		let underline = UIView()
		underline.backgroundColor = UIColor.blackColor()
		header.addSubview(underline)

		let nameTitle = UILabel()
		nameTitle.text = NSLocalizedString("Companies title", tableName: "Cliqz", comment: "Antitracking UI title for companies column")

		nameTitle.font = UIFont.systemFontOfSize(12)
		nameTitle.textColor = UIColor.blackColor()
		nameTitle.textAlignment = .Left
		header.addSubview(nameTitle)

		let countTitle = UILabel()
		countTitle.text = NSLocalizedString("Trackers count title", tableName: "Cliqz", comment: "Antitracking UI title for tracked count column")
		countTitle.font = UIFont.systemFontOfSize(12)
		countTitle.textColor = UIColor.blackColor()
		countTitle.textAlignment = .Right
		header.addSubview(countTitle)

		nameTitle.snp_makeConstraints { (make) in
			make.left.top.equalTo(header)
			make.height.equalTo(20)
			make.right.equalTo(countTitle.snp_left)
		}
		underline.snp_makeConstraints { (make) in
			make.left.right.equalTo(header)
			make.height.equalTo(1)
			make.top.equalTo(nameTitle.snp_bottom)
		}
		countTitle.snp_makeConstraints { (make) in
			make.right.top.equalTo(header)
			make.height.equalTo(20)
			make.width.equalTo(100)
		}

		return header
	}

	func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let footer = UIView()
		footer.backgroundColor = UIColor.clearColor()
		let underline = UIView()
		underline.backgroundColor = UIColor.blackColor()
		footer.addSubview(underline)
		underline.snp_makeConstraints { (make) in
			make.left.right.bottom.equalTo(footer)
			make.height.equalTo(1)
		}
		return footer
	}

}
