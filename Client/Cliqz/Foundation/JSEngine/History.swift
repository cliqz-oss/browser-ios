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
    
    public func getHistory(callback : (NSDictionary) -> Void) {
        Engine.sharedInstance.getBridge().callAction("getHistory", args: [], callback: { response in
            if let result = response["result"] as? NSDictionary {
                print(result)
                callback(result)
            } else {
                callback(NSDictionary())
            }
        })
    }
    
    public func addHistoryItem(history: [String: AnyObject]) {
        Engine.sharedInstance.getBridge().publishEvent("history:add", args: [history])
    }
    
    public func bulkAddHistory(history: [[String: AnyObject]], completionHandler:(NSError?) -> Void) {
        Engine.sharedInstance.getBridge().callAction("bulkAddHistory", args: [history], callback: { result in
            completionHandler(nil)
        })
    }
    
}
