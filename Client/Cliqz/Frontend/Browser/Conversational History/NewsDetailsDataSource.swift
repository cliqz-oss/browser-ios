//
//  CliqzNewsDetailsDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class CliqzNewsDetailsDataSource: DomainDetailsProtocol {
    
    var img: UIImage?
    var articles:[[String:AnyObject]]
    
    init(image:UIImage?, articles: [[String:AnyObject]]) {
        self.img = image
        self.articles = articles
    }
    
    func image() -> UIImage? {
        return self.img
    }
    
    func urlLabelText(indexPath: IndexPath) -> String {
        return articleValue(forKey: "url", at: indexPath) ?? ""
    }
    
    func titleLabelText(indexPath: IndexPath) -> String {
        return articleValue(forKey: "title", at: indexPath) ?? ""
    }
    
    func sectionTitle(section: Int) -> String {
        return "Today"
    }
    
    func timeLabelText(indexPath: IndexPath) -> String {
        return ""
    }
    
    func baseUrl() -> String {
        return "https://www.cliqz.com"
    }
    
    func numberOfSections() -> Int {
        return 1
    }
    
    func numberOfCells(section: Int) -> Int {
        return articles.count
    }
    
    func isNews() -> Bool {
        return true
    }
    
    func isQuery(indexPath: IndexPath) -> Bool {
        return false
    }
    
    func articleValue(forKey key: String, at indexPath:IndexPath) -> String? {
        if indexWithinBounds(indexPath: indexPath){
            let art = article(at: indexPath)
            return art[key] as? String
        }
        return ""
    }
    
    func article(at indexPath:IndexPath) -> [String:AnyObject] {
        return articles[indexPath.row]
    }
    
    func indexWithinBounds(indexPath:IndexPath) -> Bool {
        if indexPath.row < articles.count{
            return true
        }
        return false
    }
    
}
