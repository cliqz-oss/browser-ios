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
        return  NSDate().timeIntervalSince1970 * 1000.0
    }
    
    class func getDay()-> Int {
        return  Int(NSDate().timeIntervalSince1970 / 86400)
    }
    
    class func milliSecondsSinceDate(anotherDate: NSDate?)-> Double? {
        var milliSeconds: Double?
        if anotherDate != nil {
            milliSeconds = NSDate().timeIntervalSinceDate(anotherDate!) * 1000
        }
        return milliSeconds
    }
    
    func daysSinceDate(anotherDate: NSDate)-> Int {
        return Int( self.timeIntervalSinceDate(anotherDate) / 86400 )
    }
}
