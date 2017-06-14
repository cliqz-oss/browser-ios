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
import Shared

class AntiTrackingModule: NSObject {
    
    //MARK: Constants
	fileprivate let context: JSContext? = nil
    fileprivate let antiTrackingDirectory = "Extension/build/mobile/search/v8"
    fileprivate let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
    fileprivate let fileManager = FileManager.default
    fileprivate let dispatchQueue = DispatchQueue(label: "com.cliqz.AntiTracking", attributes: [])
    
    fileprivate let adBlockABTestPrefName = "cliqz-adb-abtest"
    fileprivate let adBlockPrefName = "cliqz-adb"
    
    fileprivate let telemetryWhiteList = ["attrack.FP", "attrack.tp_events"]
    fileprivate let urlsWhiteList = ["https://cdn.cliqz.com/anti-tracking/bloom_filter/",
                                 "https://cdn.cliqz.com/anti-tracking/whitelist/versioncheck.json",
                                 "https://cdn.cliqz.com/adblocking/mobile/allowed-lists.json"]
    
    let adBlockerLastUpdateDateKey = "AdBlockerLastUpdateDate"
    
    // MARK: - Local variables
    var privateMode = false
    var timerCounter = 0
    var timers = [Int: Timer]()
    
    //MARK: - Singltone
    static let sharedInstance = AntiTrackingModule()
    
    override init() {
        super.init()
    }
    
    //MARK: - Public APIs
    func initModule() {
    }

	func getTrackersCount(_ webViewId: Int) -> Int {
		if let webView = WebViewToUAMapper.idToWebView(webViewId) {
			return webView.unsafeRequests
		}
		return 0
	}

    func getAntiTrackingStatistics(_ webViewId: Int) -> [(String, Int)] {
        var antiTrackingStatistics = [(String, Int)]()
        if let tabBlockInfo = getTabBlockingInfo(webViewId) {
            tabBlockInfo.keys.forEach { company in
                antiTrackingStatistics.append((company as! String, tabBlockInfo[company] as! Int))
            }
		}
        return antiTrackingStatistics.sorted { $0.1 == $1.1 ? $0.0.lowercased() < $1.0.lowercased() : $0.1 > $1.1 }
    }
    
    func isDomainWhiteListed(_ hostname: String) -> Bool{
        let response = Engine.sharedInstance.getBridge().callAction("antitracking:isSourceWhitelisted", args: [hostname])
        if let result = response["result"] as? Bool{
            return result
        }
        return false
    }
    
    func toggleAntiTrackingForURL(_ url: URL){
        
        guard let host = url.host else{return}
        var whitelisted = false
        
        if self.isDomainWhiteListed(host){
            self.removeFromWhitelist(host)
        }
        else{
            self.addToWhiteList(host)
            whitelisted = true
        }
        
        //Doc: If the observer checks if the website is whitelisted after this, it might get the wrong value, since the correct value may not be set yet. 
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationRefreshAntiTrackingButton), object: nil, userInfo: ["whitelisted":whitelisted])
    }
    
    
    //MARK: - Private Helpers
    fileprivate func getTabBlockingInfo(_ webViewId: Int) -> [AnyHashable: Any]! {
        let response = Engine.sharedInstance.getBridge().callAction("antitracking:getTrackerListForTab", args: [webViewId as AnyObject])
        if let result = response["result"] {
            return result as? Dictionary
        } else {
            return [:]
        }
    }
    
    fileprivate func addToWhiteList(_ domain: String){
        Engine.sharedInstance.getBridge().publishEvent("antitracking:whitelist:add", args: [domain])
    }
    
    fileprivate func removeFromWhitelist(_ domain: String){
        Engine.sharedInstance.getBridge().publishEvent("antitracking:whitelist:remove", args: [domain])
    }

}

