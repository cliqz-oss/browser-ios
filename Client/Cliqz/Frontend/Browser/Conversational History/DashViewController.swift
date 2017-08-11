//
//  DashViewController.swift
//  Client
//
//  Created by Tim Palade on 8/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class DashViewController: UIViewController {
    
    let reminders       = ExpandableView(customDataSource: DashRemindersDataSource())
    let recommendations = ExpandableView(customDataSource: DashRecommendationsDataSource())
    
    let scrollView = UIScrollView()
    
    //Styling
    
    let remindersTopInset: CGFloat = 20.0
    let recommendationsTopInset: CGFloat = 30.0
    let bottomPaddingScroll: CGFloat = 30.0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpComponent()
        setStyles()
        setConstraints()
    }
    
    func setUpComponent() {
        
        self.scrollView.addSubview(reminders)
        self.scrollView.addSubview(recommendations)
        self.view.addSubview(scrollView)
        reminders.customDelegate = self
        recommendations.customDelegate = self
        
        reminders.headerTitleText = "Reminders"
        recommendations.headerTitleText = "Recommendations"
        
        scrollView.contentSize.height = reminders.initialHeight() + recommendations.initialHeight() + remindersTopInset + recommendationsTopInset + bottomPaddingScroll
        
    }
    
    func setStyles() {
        self.view.backgroundColor = .clear
        self.scrollView.backgroundColor = .clear
    }
    
    func setConstraints() {
        scrollView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
        }
        
        reminders.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(remindersTopInset)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().dividedBy(1.1)
            make.height.equalTo(reminders.initialHeight())
        }
        
        recommendations.snp.makeConstraints { (make) in
            make.top.equalTo(reminders.snp.bottom).offset(recommendationsTopInset)
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

extension DashViewController: ExpandableViewDelegate {
    func heightChanged(newHeight: CGFloat, oldHeight: CGFloat) {
        self.scrollView.contentSize.height -= oldHeight
        self.scrollView.contentSize.height += newHeight
    }
}

