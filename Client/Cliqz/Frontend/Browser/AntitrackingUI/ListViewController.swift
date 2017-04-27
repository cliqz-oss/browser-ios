//
//  ViewController.swift
//  TestTableView
//
//  Created by Sahakyan on 11/16/16.
//  Copyright © 2016 Cliqz. All rights reserved.
//

import UIKit
import SnapKit

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	private let questionsTableView = UITableView()
	private var transparentBackgroundView = UIView()
	private var darkBackgroundView = UIView()
	private var titleView = UIView()
	private var contentView = UIView()

	private let cellIdentifier = "IceBreakingCell"
	private let backgroundColor = UIColor.lightGrayColor()

	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.backgroundColor = UIColor.clearColor()
		self.darkBackgroundView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
		self.view.addSubview(self.darkBackgroundView)
		self.contentView.backgroundColor = UIColor.clearColor()
		self.contentView.layer.cornerRadius = 5
		self.contentView.clipsToBounds = true
		self.view.addSubview(self.contentView)
		self.transparentBackgroundView.backgroundColor = self.backgroundColor.colorWithAlphaComponent(0.8)
		self.contentView.addSubview(self.transparentBackgroundView)
		
		self.titleView.backgroundColor = UIColor.whiteColor()
		let icon = UIImageView(image: UIImage(named: ""))
		icon.tag = 1
		self.titleView.addSubview(icon)
		let titleLabel = UILabel()
		titleLabel.tag = 2
		titleLabel.textColor = UIColor.darkGrayColor()
		titleLabel.text = "ICEBREAKING QUESTIONS"
		titleLabel.textAlignment = .Center
		titleLabel.font = UIFont.boldSystemFontOfSize(14)
		self.titleView.addSubview(titleLabel)
		let closeButton = UIButton()
		closeButton.setImage(UIImage(named: ""), forState: .Normal)
		closeButton.addTarget(self, action: #selector(closeIcebreaking), forControlEvents: .TouchUpInside)
		self.titleView.addSubview(closeButton)
		self.contentView.addSubview(self.titleView)

		questionsTableView.dataSource = self
		questionsTableView.delegate = self
		questionsTableView.registerClass(IceBreakingViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
		questionsTableView.separatorStyle = .None
		questionsTableView.backgroundColor = UIColor.clearColor()
		self.contentView.addSubview(questionsTableView)

		let tap = UITapGestureRecognizer(target: self, action: #selector(tapRecognizer))
		tap.cancelsTouchesInView = false
		self.view.addGestureRecognizer(tap)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.setupConstraints()
	}

	private func setupConstraints() {
		self.darkBackgroundView.snp_makeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.view)
		}

		self.contentView.snp_makeConstraints { (make) in
			make.top.equalTo(self.view).offset(120)
			make.left.equalTo(self.view).offset(10)
			make.right.equalTo(self.view).offset(-10)
			make.bottom.equalTo(self.view).offset(-70)
		}
		self.transparentBackgroundView.snp_makeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.contentView)
		}

		self.titleView.snp_makeConstraints { (make) in
			make.top.left.right.equalTo(self.contentView)
			make.height.equalTo(40)
		}
		self.questionsTableView.snp_makeConstraints { (make) in
			make.left.right.equalTo(self.contentView)
			make.top.equalTo(self.titleView.snp_bottom).offset(5)
			make.bottom.equalTo(self.contentView).offset(-5)
		}

		let titleLabel = self.titleView.viewWithTag(2)
		titleLabel?.snp_makeConstraints(closure: { (make) in
			make.center.equalTo(self.titleView)
			make.size.equalTo(self.titleView.snp_size)
		})
		let closeButton = self.titleView.viewWithTag(3)
		closeButton?.snp_makeConstraints(closure: { (make) in
			make.right.top.bottom.equalTo(self.titleView)
			make.width.equalTo(30)
		})
	}

	@objc private func closeIcebreaking() {
		self.dismissViewControllerAnimated(false, completion: nil)
	}
	
	@objc func tapRecognizer(sender: UITapGestureRecognizer) {
		self.closeIcebreaking()
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 20
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		let cell = self.questionsTableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! IceBreakingViewCell
		cell.questionLabel.text = "Aaaa"
		return cell
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 60
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

}


class IceBreakingViewCell: UITableViewCell {
	
	let borderView = UIView()
	let questionLabel = UILabel()
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.contentView.backgroundColor = UIColor.clearColor()
		self.backgroundColor = UIColor.clearColor()
		borderView.backgroundColor = UIColor.clearColor()
		borderView.layer.cornerRadius = 25
		borderView.layer.borderColor = UIColor.blueColor().CGColor
		borderView.layer.borderWidth = 1
		self.contentView.addSubview(borderView)
		questionLabel.textColor = UIColor.darkGrayColor()
		questionLabel.textAlignment = .Center
		self.contentView.addSubview(questionLabel)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		self.borderView.snp_makeConstraints { (make) in
			make.left.equalTo(self.contentView).offset(10)
			make.right.equalTo(self.contentView).offset(-10)
			make.top.equalTo(self.contentView).offset(3)
			make.bottom.equalTo(self.contentView).offset(-5)
		}
		self.questionLabel.snp_makeConstraints { (make) in
			make.left.equalTo(self.borderView.snp_left)
			make.right.equalTo(self.borderView.snp_right)
			make.top.bottom.equalTo(self.borderView)
		}
	}
}
