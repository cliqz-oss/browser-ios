//
//  BlockedRequestsCache.swift
//  Client
//
//  Created by Mahmoud Adam on 9/13/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class BlockedRequestsCache: NSObject {
    
    static let sharedInstance = BlockedRequestsCache()
    fileprivate var blockedURLs = Set<URL>()

    fileprivate let dispatchQueue = DispatchQueue(label: "com.cliqz.antitracking.cache", attributes: []);
    
    func addBlockedRequest(_ request: URLRequest) {
        guard let url = request.url else {
            return
        }
        dispatchQueue.sync {
            self.blockedURLs.insert(url)
        }
    }
    
    func hasRequest(_ request: URLRequest) -> Bool {
        guard let url = request.url else {
            return false
        }
        
        if blockedURLs.contains(url) {
            return true
        }
        return false
    }
    
    func removeBlockedRequest(_ request: URLRequest) {
        guard let url = request.url else {
            return
        }
        
        dispatchQueue.sync {
            self.blockedURLs.remove(url)
        }
    }
    
    
}
