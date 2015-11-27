//
//  RecommendationsViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 11/25/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import UIKit

class RecommendationsViewController: LayerViewController {
    
    //MARK: - overiden methods
    override func didInit() {
        super.didInit()
    }
    override func prepareView() {
        super.prepareView()
        
        self.title = NSLocalizedString("Recommendations", comment: "Recommendations title")
        
        // View
        self.view.backgroundColor = UIColor.whiteColor()
        
        // Navigation bar
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 68.0/255.0, green: 166.0/255.0, blue: 48.0/255.0, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        self.navigationItem.rightBarButtonItem = createUIBarButton("past", action: Selector("dismiss"))
        // Dummy Content
        dummyImageView?.image = UIImage(named: "recommendations.png")
    }
    
    override func setupConstraints() {
        super.setupConstraints()
    }
    
    //MARK: - Custom Actions
    
}
