//
//  DashViewController.swift
//  Client
//
//  Created by Tim Palade on 8/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class DashViewController: UIViewController {
    
    var reminders: ExpandableView? = nil
    var recommendations: ExpandableView? = nil
    
    let scrollView = UIScrollView()
    
    //Styling
    
    let remindersTopInset: CGFloat = 20.0
    let recommendationsTopInset: CGFloat = 30.0
    let bottomPaddingScroll: CGFloat = 30.0
    
    init() {
        super.init(nibName: nil, bundle: nil)
        reminders = ExpandableView(customDataSource: DashRemindersDataSource())
        recommendations = ExpandableView(customDataSource: DashRecommendationsDataSource(delegate: self))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpComponent()
        setStyles()
        setConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        update()
    }
    
    func update() {
        var reminders_initial_height = reminders!.initialHeight()
        var recommendations_initial_height = recommendations!.initialHeight()
        
        if recommendations!.customDataSource?.maxNumCells() == 0 {
            recommendations!.isHidden = true
            recommendations_initial_height = 0
        }
        else {
            recommendations!.isHidden = false
        }
        
        if reminders!.customDataSource?.maxNumCells() == 0 {
            reminders!.isHidden = true
            reminders_initial_height = 0
        }
        else {
            reminders!.isHidden = false
        }
        
        scrollView.contentSize.height = reminders_initial_height + recommendations_initial_height + remindersTopInset + recommendationsTopInset + bottomPaddingScroll
    }
    
    func setUpComponent() {
        
        self.scrollView.addSubview(reminders!)
        self.scrollView.addSubview(recommendations!)
        self.view.addSubview(scrollView)
        reminders!.customDelegate = self
        recommendations!.customDelegate = self
        
        reminders!.headerTitleText = "Reminders"
        recommendations!.headerTitleText = "Recommendations"
    }
    
    func setStyles() {
        self.view.backgroundColor = .clear
        self.scrollView.backgroundColor = .clear
    }
    
    func setConstraints() {
        
        scrollView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
        }
        
        reminders!.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().inset(remindersTopInset)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().dividedBy(1.1)
            make.height.equalTo(reminders!.initialHeight())
        }
        
        recommendations!.snp.remakeConstraints { (make) in
            make.top.equalTo(reminders!.snp.bottom).offset(recommendationsTopInset)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().dividedBy(1.1)
            make.height.equalTo(recommendations!.initialHeight())
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension DashViewController: HasDataSource {
    func dataSourceWasUpdated() {
        reminders!.reloadData()
        recommendations!.reloadData()
        update()
        setConstraints()
    }
}

extension DashViewController: ExpandableViewDelegate {
    func heightChanged(newHeight: CGFloat, oldHeight: CGFloat) {
        self.scrollView.contentSize.height -= oldHeight
        self.scrollView.contentSize.height += newHeight
    }
}

