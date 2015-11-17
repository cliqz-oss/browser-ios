//
//  NSDateExtension.swift
//  Client
//
//  Created by Mahmoud Adam on 11/9/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

extension NSDate {
    class func getCurrentMillis()-> Double {
        return  NSDate().timeIntervalSince1970 * 1000.0 //TODO: check
    }
    
    class func getDay()-> Int {
        return  Int(NSDate().timeIntervalSince1970 / 86400)
    }
}
