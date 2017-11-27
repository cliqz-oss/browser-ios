//
//  HistoryModule.swift
//  Client
//
//  Created by Mahmoud Adam on 10/19/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import Storage
import Shared


class HistoryEntry {
    let id: Int
    let title: String
    let date: Date?
    
    init(id: Int, title: String, date: Date? = nil) {
        self.id = id
        self.title = title
        self.date = date
    }
    
    func useRightCell() -> Bool {
        return false
    }
}

class HistoryUrlEntry : HistoryEntry {
    let url: URL
    init(id: Int, title: String, url: URL, date: Date? = nil) {
        self.url = url
        super.init(id: id, title: title, date: date)
    }
}

class HistoryQueryEntry : HistoryEntry {
    
    override func useRightCell() -> Bool {
        return true
    }
}


class HistoryModule: NSObject {
    class func getHistory(profile: Profile, completion: @escaping (_ result:[HistoryEntry], _ error:NSError?) -> Void) {
        //limit is static for now.
        //later there will be a mechanism in place to handle a variable limit and offset.
        //It will keep a window of results that updates as the user scrolls.
        let backgroundQueue = DispatchQueue.global(qos: .background)
        profile.history.getHistoryVisits(0, limit: 500).uponQueue(backgroundQueue) { (result) in
            let historyEntries = processHistoryResults(result: result)
            completion(historyEntries, nil) //TODO: there should be a better error handling mechanism here
        }
    }
    
    private class func processHistoryResults(result: Maybe<Cursor<Site>>) -> [HistoryEntry] {
        var historyResults: [HistoryEntry] = []
        
        if let sites = result.successValue {
            for site in sites {
                if let domain = site,
                    let id = domain.id, let url = URL(string: domain.url) {
                    
                    let title = domain.title
                    var date:Date?  = nil
                    if let latestDate = domain.latestVisit?.date {
                        date = Date(timeIntervalSince1970: Double(latestDate) / 1000000.0) // second = microsecond * 10^-6
                    }
                    
                    if url.scheme == QueryScheme {
                        let result = HistoryQueryEntry(id: id, title: title.unescape(), date: date)
                        historyResults.append(result)
                    } else {
                        let result = HistoryUrlEntry(id: id, title: title, url: url, date: date)
                        historyResults.append(result)
                    }
                }
            }
        }
        return historyResults
    }
    
    class func getFavorites(profile: Profile, completion: @escaping (_ result:[HistoryEntry], _ error:NSError?) -> Void) {
        //limit is static for now.
        //later there will be a mechanism in place to handle a variable limit and offset.
        //It will keep a window of results that updates as the user scrolls.
        let backgroundQueue = DispatchQueue.global(qos: .background)
        profile.bookmarks.getBookmarks().uponQueue(backgroundQueue) { (result) in
            let HistoryEntries = processFavoritesResults(result: result)
            completion(HistoryEntries, nil) //TODO: there should be a better error handling mechanism here
        }
    }
    
    private class func processFavoritesResults(result: Maybe<Cursor<BookmarkNode>>) -> [HistoryEntry] {
        var favoritesResults: [HistoryEntry] = []
        
        if let bookmarks = result.successValue {
            for bookmark in bookmarks {
                switch (bookmark) {
                case let item as CliqzBookmarkItem:
                    if let id = item.id, let url = URL(string: item.url) {
                        let date = Date(timeIntervalSince1970: Double(item.bookmarkedDate) / 1000.0) // second = millisecond * 10^-3
                        let result = HistoryUrlEntry(id: id, title: item.title, url: url, date: date)
                        favoritesResults.append(result)
                    }
                default:
                    debugPrint("Not a bookmark item")
                }
            }
        }
        
        return favoritesResults
    }
    
    class func removeHistoryEntries(profile: Profile, ids: [Int]) {
        profile.history.removeHistory(ids)
    }
    
    class func removeFavoritesEntry(profile: Profile, url: URL, callback: @escaping () -> ()) {
        profile.bookmarks.modelFactory >>== {
            $0.removeByURL(url.absoluteString)
                .uponQueue(DispatchQueue.main) { res in
                    callback()
            }
        }
    }
    
}
