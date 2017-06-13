//
//  History.swift
//  Client
//
//  Created by Sam Macbeth on 27/02/2017.
//  Copyright © 2017 Mozilla. All rights reserved.
//
import Foundation
import React


@objc(HistoryBridge)
public class HistoryBridge : NSObject {
    
    public override init() {
        super.init()
    }
    
    @objc(syncHistory:resolve:reject:)
    func syncHistory(fromIndex : NSInteger, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        
    }
    
    @objc(pushHistory:)
    func pushHistory(historyItems : NSDictionary) {
        
    }
    
    public func getHistory(callback : @escaping (NSDictionary) -> Void) {
        Engine.sharedInstance.getBridge().callAction("getHistory", args: [], callback: { response in
            if let result = response["result"] as? NSDictionary {
                print(result)
                callback(result)
            } else {
                callback(NSDictionary())
            }
        })
    }
    
    public class func addHistoryItem(history: [String: AnyObject]) {
        Engine.sharedInstance.getBridge().publishEvent("content:location-change", args: [history])
    }
    
    public class func readLater(urlInfo: [String: AnyObject]) {
        //url , title, timestamp
        Engine.sharedInstance.getBridge().publishEvent("browser:read-later", args: [urlInfo])
    }
    
    public class func keepOpen(url: [String: AnyObject]) {
        // tabID
        Engine.sharedInstance.getBridge().publishEvent("browser:keep-open", args: [])
    }
    
    public func bulkAddHistory(history: [[String: AnyObject]], completionHandler:@escaping (NSError?) -> Void) {
        Engine.sharedInstance.getBridge().callAction("bulkAddHistory", args: [history as AnyObject], callback: { result in
            completionHandler(nil)
        })
    }
    
}
