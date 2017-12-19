//
//  ReadNewsManager.swift
//  Client
//
//  Created by Tim Palade on 5/16/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

final class NewsNotificationManager {
    
    //algorithms here could be more efficient, but I am dealing with small sizes, so it should not be a problem
    
    static  let shared = NewsNotificationManager()
    private let internalDict: PersistentDict<String,[String]>
    private var differenceArticles: [String] = [] //difference array
    
    init() {
        self.internalDict = PersistentDict(id: "ID_NEWS_NOTIFICATIONS")
        self.differenceArticles = self.internalDict.value(key: "differenceArticles") ?? []
    }
    
    func setLatestArticles(new_articles: [String]) {
        if let old_articles = self.internalDict.value(key: "articles") {
            differenceArticles += new_articles.difference(array: old_articles)
        }
        else {
            differenceArticles += new_articles
        }
        
        //make sure all differenceArticles are part of the new_articles
        //otherwise it may contain an article that is no longer in the news, so it would show a misleading notification
        differenceArticles = differenceArticles.filter({ (article) -> Bool in
            return new_articles.contains(article)
        })
        
        self.internalDict.setValue(value: new_articles, forKey: "articles")
        self.internalDict.setValue(value: differenceArticles, forKey: "differenceArticles")
    }
    
    func newArticlesCount(host: String) -> Int {
        return differenceArticles.filter({ (article) -> Bool in
            if let article_host = URL(string: article)?.normalizedHost() {
                return article_host == host
            }
            return false
        }).count
    }
    
    func domainPressed(host: String) {
        differenceArticles = differenceArticles.filter({ (article) -> Bool in
            if let article_host = URL(string: article)?.normalizedHost() {
                return article_host != host
            }
            return false
        })
        
        self.internalDict.setValue(value: differenceArticles, forKey: "differenceArticles")
    }
    
}


extension Array where Element: Equatable {
    func difference(array: Array<Element>) -> Array<Element> {
        return self.filter({ (element) -> Bool in
            return !array.contains(element)
        })
    }
}
