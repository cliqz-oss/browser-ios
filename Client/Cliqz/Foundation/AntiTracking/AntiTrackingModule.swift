//
//  AntiTrackingModule.swift
//  Client
//
//  Created by Mahmoud Adam on 8/12/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import JavaScriptCore
import Crashlytics

class AntiTrackingModule: NSObject {
    
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
    
    // MARK: - Local variables
    var privateMode = false
    var timerCounter = 0
    var timers = [Int: NSTimer]()
    
    //MARK: - Singltone
    static let sharedInstance = AntiTrackingModule()
    
    override init() {
        super.init()
    }
    
    //MARK: - Public APIs
    func initModule() {
    }

	func getTrackersCount(webViewId: Int) -> Int {
		if let webView = WebViewToUAMapper.idToWebView(webViewId) {
			return webView.unsafeRequests
		}
		return 0
	}

    func getAntiTrackingStatistics(webViewId: Int) -> [(String, Int)] {
        var antiTrackingStatistics = [(String, Int)]()
        if let tabBlockInfo = getTabBlockingInfo(webViewId) {
            tabBlockInfo.keys.forEach { company in
                antiTrackingStatistics.append((company as! String, tabBlockInfo[company] as! Int))
            }
		}
        return antiTrackingStatistics.sort { $0.1 == $1.1 ? $0.0.lowercaseString < $1.0.lowercaseString : $0.1 > $1.1 }
    }
    
    func isDomainWhiteListed(hostname: String) -> Bool{
        let response = Engine.sharedInstance.getBridge().callAction("antitracking:isSourceWhitelisted", args: [hostname])
        if let result = response["result"] as? Bool{
            return result
        }
        return false
    }
    
    func toggleAntiTrackingForURL(url: NSURL){
        
        guard let host = url.host else{return}
        
        if self.isDomainWhiteListed(host){
            self.removeFromWhitelist(host)
        }
        else{
            self.addToWhiteList(host)
        }
    }
    
    
    //MARK: - Private Helpers
    private func getTabBlockingInfo(webViewId: Int) -> [NSObject : AnyObject]! {
        let response = Engine.sharedInstance.getBridge().callAction("antitracking:getTrackerListForTab", args: [webViewId])
        if let result = response["result"] {
            return result as? Dictionary
        } else {
            return [:]
        }
    }
    
    private func addToWhiteList(domain: String){
        Engine.sharedInstance.getBridge().publishEvent("antitracking:whitelist:add", args: [domain])
    }
    
    private func removeFromWhitelist(domain: String){
        Engine.sharedInstance.getBridge().publishEvent("antitracking:whitelist:remove", args: [domain])
    }

}

