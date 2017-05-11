//
//  CliqzNewsDetailsDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class CliqzNewsDetailsDataSource: HistoryDetailsProtocol{
    
    var img: UIImage?
    var articles:[[String:AnyObject]]
    
    init(image:UIImage?, articles: [[String:AnyObject]]) {
        self.img = image
        self.articles = articles
    }
    
    func image() -> UIImage? {
        return self.img
    }
    
    func urlLabelText(indexPath: NSIndexPath) -> String {
        return articleValue(forKey: "url", at: indexPath) ?? ""
    }
    
    func titleLabelText(indexPath: NSIndexPath) -> String {
        return articleValue(forKey: "title", at: indexPath) ?? ""
    }
    
    func timeLabelText(indexPath: NSIndexPath) -> String {
        return ""
    }
    
    func baseUrl() -> String {
        return "https://www.cliqz.com"
    }
    
    func numberOfCells() -> Int {
        return articles.count
    }
    
    func isNews() -> Bool {
        return true
    }
    
    func articleValue(forKey key: String, at indexPath:NSIndexPath) -> String? {
        if indexWithinBounds(indexPath){
            let art = article(at: indexPath)
            return art[key] as? String
        }
        return ""
    }
    
    func article(at indexPath:NSIndexPath) -> [String:AnyObject] {
        return articles[indexPath.row]
    }
    
    func indexWithinBounds(indexPath:NSIndexPath) -> Bool {
        if indexPath.row < articles.count{
            return true
        }
        return false
    }
    
}
