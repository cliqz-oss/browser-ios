//
//  AdblockingModule.swift
//  Client
//
//  Created by Tim Palade on 2/24/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import JavaScriptCore
import Crashlytics

class AdblockingModule: NSObject {

    //MARK: Constants
    private let context: JSContext? = nil
    private let antiTrackingDirectory = "Extension/build/mobile/search/v8"
    private let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! as String
    private let fileManager = NSFileManager.defaultManager()
    private let dispatchQueue = dispatch_queue_create("com.cliqz.AntiTracking", DISPATCH_QUEUE_SERIAL)
    
    private let adBlockABTestPrefName = "cliqz-adb-abtest"
    private let adBlockPrefName = "cliqz-adb"
    
    private let telemetryWhiteList = ["attrack.FP", "attrack.tp_events"]
    private let urlsWhiteList = ["https://cdn.cliqz.com/anti-tracking/bloom_filter/",
                                 "https://cdn.cliqz.com/anti-tracking/whitelist/versioncheck.json",
                                 "https://cdn.cliqz.com/adblocking/mobile/allowed-lists.json"]
    
    let adBlockerLastUpdateDateKey = "AdBlockerLastUpdateDate"
    
    //MARK: - Singltone
    static let sharedInstance = AdblockingModule()
    
    override init() {
        super.init()
    }
    
    //MARK: - Public APIs
    func initModule() {
    }
    
    func setAdblockEnabled(value: Bool, timeout: Int = 0) {
        Engine.sharedInstance.setPref(self.adBlockPrefName, prefValue: value ? 1 : 0)
        Engine.sharedInstance.setPref(self.adBlockABTestPrefName, prefValue: value ? true : false)
    }
    
    func isAdblockEnabled() -> Bool {
        let result = Engine.sharedInstance.getPref(self.adBlockPrefName)
        if let value = result as? Int {
            return Bool(value)
        }
        return false
    }
    
    func isUrlBlackListed(url:String) -> Bool {
        let response = Engine.sharedInstance.jsbridge.callAction("isUrlBlacklisted", args: [url])
        if let result = response["result"] as? Int{
            return Bool(result)
        }
        return false
    }
    
    func toggleUrl(url: NSURL){
        
        if let urlString = url.absoluteString, host = url.host{
            let response = Engine.sharedInstance.jsbridge.callAction("toggleUrl", args: [urlString, host])
            if let res = response["result"]{
                print(res)
            }
        }
    }
    
    func getAdBlockingStatistics(url: NSURL) -> [(String, Int)] {
        var adblockingStatistics = [(String, Int)]()
        if let urlString = url.absoluteString, tabBlockInfo = getAdBlockingInfo(urlString) {
            tabBlockInfo.keys.forEach { company in
                adblockingStatistics.append((company as! String, tabBlockInfo[company] as! Int))
            }
        }
        return adblockingStatistics.sort { $0.1 == $1.1 ? $0.0.lowercaseString < $1.0.lowercaseString : $0.1 > $1.1 }
    }
    
    //MARK: - Private Helpers
    func getAdBlockingInfo(url: String) -> [NSObject : AnyObject]! {
        let response = Engine.sharedInstance.jsbridge.callAction("getAdBlockInfo", args: [url])
        print(response)
        if let result = response["result"] {
            return result as? Dictionary
        } else {
            return [:]
        }
    }
    
}
