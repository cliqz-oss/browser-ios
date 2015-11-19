//
//  ExtendedBrowserHistory.swift
//  Client
//
//  Created by Mahmoud Adam on 11/18/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation
import Shared

public protocol ExtendedBrowserHistory {
    
    func count() -> Int
    func getOldestVisitDate() -> NSDate? 
}
