//
//  ReadNewsManager.swift
//  Client
//
//  Created by Tim Palade on 5/16/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

//This takes care of remembering which news are read.

final class NewsNotificationManager {
    
    //articles change every day. So only articles that are youger than 1 day should stay in my manager
    //I will write to disk the current articles when the application is closed.
    
    //user defaults key
    
    static  let shared = NewsNotificationManager()
    private let readArticlesDict: PersistentDict<String,Date>
    
    init() {
        self.readArticlesDict = PersistentDict(id: "ID_READ_NEWS")
        self.readArticlesDict.filter { (date) -> Bool in
            return date.isYoungerThanOneDay()
        }
    }
    
    func isRead(articleLink:String) -> Bool {
        return readArticlesDict.keys.contains(articleLink)
    }
    
    func markAsRead(articleLink:String?) {
        guard let art_link = articleLink else { return }
        readArticlesDict.setValue(value: Date(timeIntervalSinceNow: 0), forKey: art_link)
    }
    
}
