//
//  GeneralUtils.swift
//  Client
//
//  Created by Tim Palade on 8/23/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class GeneralUtils {
    
    class func groupBy<A, B:Hashable>(array:[A], hashF:(A) -> B) -> Dictionary<B, [A]>{
        var dict: Dictionary<B, [A]> = [:]
        
        for elem in array {
            let key = hashF(elem)
            if var array = dict[key] {
                array.append(elem)
                dict[key] = array
            }
            else {
                dict[key] = [elem]
            }
        }
        
        return dict
    }
    
    class func convert(seconds: Int) -> String {
        
        let days = seconds / (24 * 60 * 60)
        if days != 0 {
            let hours = (seconds % (24 * 60 * 60)) / 60
            return String(days) + " days" + " " + String(hours) + " hours"
        }
        
        let hours = seconds / (60 * 60)
        if hours != 0 {
            let minutes = (seconds % (60 * 60)) / 60
            return String(hours) + " hours" + " " + String(minutes) + " minutes"
        }
        
        let minutes = seconds / 60
        if minutes != 0 {
            return String(minutes) + " minutes"
        }
        
        return String(seconds) + " seconds"
    }
}

extension Date {
    static public func ==(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedSame
    }
    
    static public func <(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
    
    static public func >(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedDescending
    }
    
}

extension UIImage {
    static func fromColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
