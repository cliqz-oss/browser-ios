//
//  NSDateExtension.swift
//  Client
//
//  Created by Mahmoud Adam on 11/9/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

extension Date {
    static func getCurrentMillis()-> Double {
        return  Date().timeIntervalSince1970 * 1000.0
    }
    
    static func getDay()-> Int {
        return  Int(Date().timeIntervalSince1970 / 86400)
    }
    
    static func milliSecondsSinceDate(_ anotherDate: Date?)-> Double? {
        var milliSeconds: Double?
        if anotherDate != nil {
            milliSeconds = round(Date().timeIntervalSince(anotherDate!) * 1000)
        }
        return milliSeconds
    }
    
    func daysSinceDate(_ anotherDate: Date)-> Int {
        return Int( self.timeIntervalSince(anotherDate) / 86400 )
    }
}
