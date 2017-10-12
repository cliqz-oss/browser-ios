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
    
    class func removeElementsAfter<A>(index: Int, array: [A]) -> [A] {
        var arrayCopy = array
        arrayCopy.removeLast(array.count - index - 1)
        return arrayCopy
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
    
    public struct DayMonthYear: Equatable {
        let day: Int
        let month: Int
        let year: Int
        
        static public func ==(lhs: DayMonthYear, rhs: DayMonthYear) -> Bool {
            return lhs.day == rhs.day && lhs.month == rhs.month && lhs.year == rhs.year
        }
    }
    
    static public func ==(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedSame
    }
    
    static public func <(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
    
    static public func >(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedDescending
    }
    
    public func isYoungerThanOneDay() -> Bool {
        let currentDate = NSDate(timeIntervalSinceNow: 0)
        let difference_seconds = currentDate.timeIntervalSince(self)
        let oneDay_seconds     = Double(24 * 360)
        if difference_seconds > 0 && difference_seconds < oneDay_seconds {
            return true
        }
        return false
    }
    
    public func dayMonthYear() -> DayMonthYear {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        let components = dateFormatter.string(from: self).components(separatedBy: "-")
        
        if components.count != 3 {
            //something went terribly wrong
            NSException.init(name: NSExceptionName(rawValue: "ERROR: Date might be corrupted"), reason: "There should be exactly 3 components.", userInfo: nil).raise()
        }
        
        //this conversion should never fail
        let day = Int(components[0])
        let month = Int(components[1])
        let year = Int(components[2])
        
        return DayMonthYear(day: day!, month: month!, year: year!)
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
