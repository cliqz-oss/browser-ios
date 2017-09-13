//
//  DashViewController.swift
//  Client
//
//  Created by Tim Palade on 8/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class DashViewController: UIViewController {
    
    var reminders: ExpandableView
    var recommendations: ExpandableView
    
    let scrollView = UIScrollView()
    
    //Styling
    
    let remindersTopInset: CGFloat = 20.0
    let recommendationsTopInset: CGFloat = 30.0
    let bottomPaddingScroll: CGFloat = 30.0
    
    init() {
        
        let remindersDS = DashRemindersDataSource()
        let recommendationsDS = DashRecommendationsDataSource()
        
        reminders = ExpandableView(customDataSource: remindersDS)
        recommendations = ExpandableView(customDataSource: recommendationsDS)
        super.init(nibName: nil, bundle: nil)
        
        remindersDS.delegate = self
        recommendationsDS.delegate = self
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
        
        self.scrollView.addSubview(reminders)
        self.scrollView.addSubview(recommendations)
        self.view.addSubview(scrollView)
        
        setUpComponent()
        setStyles()
        setConstraints()
    }
    
    //what can change after the data changes in the datasource:
    //1. contentSize
    //2. visiblility for expandable views
    //3. min max num elements
    //4. contents of both expandable views (point 3 belongs to that)
    
    func updateRecommendations() {
        UIView.animate(withDuration: 0.2) {
            self.recommendations.reloadData()
            self.updateUI()
            self.view.layoutIfNeeded()
        }
    }
    
    func updateReminders() {
        UIView.animate(withDuration: 0.2) { 
            self.reminders.reloadData()
            self.updateUI()
            self.view.layoutIfNeeded()
        }
    }
    
    func updateUI() {
        setUpComponent()
        setStyles()
        setConstraints()
    }
    
    func setUpComponent() {
        
        reminders.customDelegate = self
        recommendations.customDelegate = self
        
        reminders.headerTitleText = "Reminders"
        recommendations.headerTitleText = "Recommendations"
        
        var reminders_initial_height = reminders.initialHeight()
        var recommendations_initial_height = recommendations.initialHeight()
        
        if recommendations.customDataSource?.maxNumCells() == 0 {
            recommendations.isHidden = true
            recommendations_initial_height = 0
        }
        else {
            recommendations.isHidden = false
        }
        
        if reminders.customDataSource?.maxNumCells() == 0 {
            reminders.isHidden = true
            reminders_initial_height = 0
        }
        else {
            reminders.isHidden = false
        }
        
        scrollView.contentSize.height = reminders_initial_height + recommendations_initial_height + remindersTopInset + recommendationsTopInset + bottomPaddingScroll
    }
    
    func setStyles() {
        self.view.backgroundColor = .clear
        self.scrollView.backgroundColor = .clear
    }
    
    func setConstraints() {
        
        scrollView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
        }
        
        reminders.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().inset(remindersTopInset)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().dividedBy(1.1)
            make.height.equalTo(reminders.initialHeight())
        }
        
        recommendations.snp.remakeConstraints { (make) in
            if reminders.isHidden == false {
                make.top.equalTo(reminders.snp.bottom).offset(recommendationsTopInset)
            }
            else {
                make.top.equalToSuperview().offset(remindersTopInset)
            }
            
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().dividedBy(1.1)
            make.height.equalTo(recommendations.initialHeight())
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension DashViewController: HasDataSource {
    func dataSourceWasUpdated(identifier: String) {
        if identifier == DashRecommendationsDataSource.identifier {
            updateRecommendations()
        }
        else if identifier == DashRemindersDataSource.identifier {
            updateReminders()
        }
    }
}

extension DashViewController: ExpandableViewDelegate {
    func heightChanged(newHeight: CGFloat, oldHeight: CGFloat) {
        self.scrollView.contentSize.height -= oldHeight
        self.scrollView.contentSize.height += newHeight
    }
}

