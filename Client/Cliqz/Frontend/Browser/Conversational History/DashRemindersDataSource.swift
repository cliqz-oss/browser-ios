//
//  DashRemindersDataSource.swift
//  Client
//
//  Created by Tim Palade on 8/11/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class DashRemindersDataSource: ExpandableViewProtocol {
    

    
    static let identifier = "DashRemindersDataSource"
    
    func maxNumCells() -> Int {
        return 0
    }
    
    func minNumCells() -> Int {
        return 0
    }
    
    func title(indexPath: IndexPath) -> String {
        return "Test"
    }
    
    func url(indexPath: IndexPath) -> String {
        return "www.test.com"
    }
    
    func picture(indexPath: IndexPath, completionBlock: @escaping (UIImage?) -> Void) {
        completionBlock(nil)
    }
    
    func cellPressed(indexPath: IndexPath) {
        //handle press
    }
}
