//
//  CliqzHistoryDetailsDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class CliqzHistoryDetailsDataSource: HistoryDetailsProtocol{
    
    var img: UIImage?
    var visits:NSArray
    var base_Url: String
    
    init(image:UIImage?, visits: NSArray, baseUrl:String) {
        self.img = image
        self.visits = visits.sortedArrayUsingComparator({ (a,b) -> NSComparisonResult in
            if let dict_a = a as? NSDictionary, dict_b = b as? NSDictionary, time_a = dict_a["lastVisitedAt"] as? NSNumber, time_b = dict_b["lastVisitedAt"] as? NSNumber{
                return time_a.doubleValue > time_b.doubleValue ? .OrderedAscending : .OrderedDescending
            }
            return .OrderedSame
        })
        self.base_Url = baseUrl
    }
    
    func image() -> UIImage? {
        return self.img
    }
    
    func urlLabelText(indexPath: NSIndexPath) -> String {
        return visitValue(forKey: "url", at: indexPath) ?? ""
    }
    
    func titleLabelText(indexPath: NSIndexPath) -> String {
        return visitValue(forKey: "title", at: indexPath) ?? ""
    }
    
    func timeLabelText(indexPath: NSIndexPath) -> String {
        return visitValue(forKey: "lastVisitedAt", at: indexPath) ?? ""
    }
    
    func numberOfCells() -> Int {
        return visits.count
    }
    
    func baseUrl() -> String {
        return self.base_Url
    }
    
    func isNews() -> Bool {
        return false
    }
    
    func visitValue(forKey key: String, at indexPath:NSIndexPath) -> String? {
        if indexWithinBounds(indexPath){
            if let vis = visit(at: indexPath){
                if let timeinterval = vis[key] as? NSNumber{
                    return NSDate(timeIntervalSince1970: timeinterval.doubleValue / 1000).toRelativeTimeString()
                }
                return (vis[key] as? String) ?? ""
            }
        }
        return ""
    }
    
    func visit(at indexPath:NSIndexPath) -> NSDictionary? {
        return visits[indexPath.row] as? NSDictionary
    }
    
    func indexWithinBounds(indexPath:NSIndexPath) -> Bool {
        if indexPath.row < visits.count{
            return true
        }
        return false
    }
    
}
