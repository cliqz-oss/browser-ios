//
//  DashRecommendationsDataSource.swift
//  Client
//
//  Created by Tim Palade on 8/11/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class DashRecommendationsDataSource: ExpandableViewProtocol {
    
    func maxNumCells() -> Int {
        return 20
    }
    
    func minNumCells() -> Int {
        return 3
    }
    
    func title(indexPath: IndexPath) -> String {
        return "Test"
    }
    
    func url(indexPath: IndexPath) -> String {
        return "www.test.com"
    }
    
    func picture(indexPath: IndexPath) -> UIImage? {
        return nil
    }
    
    func cellPressed(indexPath: IndexPath) {
        //handle press
    }
}
