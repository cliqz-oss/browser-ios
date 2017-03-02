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
    private var blockedURLs = Set<NSURL>()

    private let dispatchQueue = dispatch_queue_create("com.cliqz.antitracking.cache", DISPATCH_QUEUE_SERIAL);
    
    func addBlockedRequest(request: NSURLRequest) {
        guard let url = request.URL else {
            return
        }
        dispatch_sync(dispatchQueue) {
            self.blockedURLs.insert(url)
        }
    }
    
    func hasRequest(request: NSURLRequest) -> Bool {
        guard let url = request.URL else {
            return false
        }
        
        if blockedURLs.contains(url) {
            return true
        }
        return false
    }
    
    func removeBlockedRequest(request: NSURLRequest) {
        guard let url = request.URL else {
            return
        }
        
        dispatch_sync(dispatchQueue) {
            self.blockedURLs.remove(url)
        }
    }
    
    
}
