//
//  SearchHistoryViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 11/25/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import UIKit

class SearchHistoryViewController: LayerViewController {

    var showFavoritesOnly = false
    
    //MARK: - overiden methods
    override func didInit() {
        super.didInit()
    }
    
    override func prepareView() {
        super.prepareView()
        
        self.title = NSLocalizedString("Search history", comment: "Search history title")
        
        // View
        self.view.backgroundColor = UIColor.whiteColor()

        // Navigation bar
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 246.0/255.0, green: 90.0/255.0, blue: 42.0/255.0, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        self.navigationItem.leftBarButtonItem = createUIBarButton("future", action: Selector("dismiss"))
        self.navigationItem.rightBarButtonItem = createUIBarButton("star", action: Selector("showFavorites"))
        
        // Dummy Content
        dummyImageView?.image = UIImage(named: "history-1.png")
    }
    
    override func setupConstraints() {
        super.setupConstraints()
    }
    

    //MARK: - Custom Actions
    func showFavorites() {
        showFavoritesOnly = !showFavoritesOnly
        if showFavoritesOnly {
            self.navigationItem.rightBarButtonItem = createUIBarButton("star", action: Selector("showFavorites"))
            dummyImageView?.image = UIImage(named: "history-2.png")
        } else {
            self.navigationItem.rightBarButtonItem = createUIBarButton("star", action: Selector("showFavorites"))
            dummyImageView?.image = UIImage(named: "history-1.png")
        }
    }
}
