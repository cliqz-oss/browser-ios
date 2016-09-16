//
//  AntiTrackingRequestsCache.swift
//  Client
//
//  Created by Mahmoud Adam on 9/13/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
//TODO: [BlockAllRequests] rename to BlockedRequestsCache
class AntiTrackingRequestsCache: NSObject {
    
    static let sharedInstance = AntiTrackingRequestsCache()
    //TODO: [BlockAllRequests] remove
    private var antiTrackingRequests = [NSURL : NSMutableURLRequest]()
    private var blockedURLs = Set<NSURL>()

    private let dispatchQueue = dispatch_queue_create("com.cliqz.antitracking.cache", DISPATCH_QUEUE_SERIAL);

    //TODO: [BlockAllRequests] remove modifiedRequest parameter
    func addTrackingEntry(request: NSURLRequest, modifiedRequest: NSMutableURLRequest) {
        guard let url = request.URL else {
            return
        }
        
        dispatch_sync(dispatchQueue) {
            self.antiTrackingRequests[url] = modifiedRequest
        }
    }
    
    
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
        
        if blockedURLs.contains(url) || antiTrackingRequests[url] != nil {
            return true
        }
        return false
    }
    //TODO: [BlockAllRequests] rename to removeBlockedRequest 
    func getModifiedRequest(request: NSURLRequest) -> NSMutableURLRequest? {
        guard let url = request.URL else {
            return nil
        }
        
        let modifiedRequest = antiTrackingRequests[url]
        dispatch_sync(dispatchQueue) {
            self.antiTrackingRequests.removeValueForKey(url)
            self.blockedURLs.remove(url)
        }
        return modifiedRequest
    }
    
    
}
