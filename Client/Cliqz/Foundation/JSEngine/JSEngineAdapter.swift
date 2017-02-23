//
//  JSEngineAdapter.swift
//  Client
//
//  Created by Mahmoud Adam on 1/24/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import jsengine


class JSEngineAdapter: NSObject {
    var jsEngine    : Engine?
    var adblocker   : Adblocker?
    var antiTracking: AntiTracking?
    
    
    //MARK: - Singltone & Init
    static let sharedInstance = JSEngineAdapter()
    
    
    //MARK: - Public APIs
    func startJSEngine() {
        self.jsEngine = Engine.sharedInstance
        
        if let jsEngine = self.jsEngine {
            
            let defaultPrefs = getDefaultPrefs()
            jsEngine.startup(defaultPrefs)
            
            self.antiTracking = AntiTracking(engine: jsEngine)
            self.adblocker = Adblocker(engine: jsEngine)
            self.adblocker?.setEnabled(SettingsPrefs.getAdBlockerPref())
        }
    }
    
    func generateUniqueUserAgent(baseUserAgent: String, tabId: Int) -> String {
        return WebRequest.generateUniqueUserAgent(baseUserAgent, tabId: tabId)
    }
    
    //MARK:- AntiTracking
    func getAntiTrackingCount(tabId: Int) -> Int {
        //TODO: call antiTracking.getUnsafeRequestsCounter(tabId)
        //TODO: we need to optimize calling getUnsafeRequestsCounter() and optimize its implementation, i.e. it should not get blockingInfo and aggregate the counter
        return 7
    }
    func getAntiTrackingStatistics(tabId: Int) -> [(String, Int)] {
        //TODO: call antiTracking.getTabBlockingInfo(tabId)
        return [("test1", 3), ("test2", 3), ("test3", 1), ("test4", 0)]
    }
    
    func isAntiTrakcingEnabledForURL(url: NSURL) -> Bool {
        guard let absoluteUrl = url.absoluteString else {
            return true
        }
        if let isWhitelisted = self.antiTracking?.isWhitelisted(absoluteUrl) {
            return !isWhitelisted
        }
        // default is always enabled
        return true
    }
    
    func toggleAntiTrackingForURL(url: NSURL) {
        //TODO: there should be toggle URL for AntiTracking like AdBlocking instead of calling JSEngine twice
        guard let absoluteUrl = url.absoluteString else {
            return
        }
        if isAntiTrakcingEnabledForURL(url) {
            self.antiTracking?.removeDomainFromWhitelist(absoluteUrl)
        } else {
            self.antiTracking?.addDomainToWhitelist(absoluteUrl)
        }
    }
    
    //MARK:- AdBlocker
    func configAdblocker(enable: Bool) {
        self.adblocker?.setEnabled(enable)
    }
    
    func getAdBlockerCount(url: NSURL) -> Int {
        // TODO: call AdBlocker.getAdsCounter(url)
        return 5
    }
    func getAdBlockerStatistics(url: NSURL) -> [(String, Int)] {
        // TODO: call AdBlocker.getAdBlockingInfo(url)
        return [("test1", 3), ("test2", 2), ("test3", 0)]
    }
    
    func isAdBlockerEnabledForURL(url: NSURL) -> Bool {
        guard let absoluteUrl = url.absoluteString else {
            return true
        }
        if let isBlacklisted = self.adblocker?.isBlacklisted(absoluteUrl) {
            return !isBlacklisted
        }
        // default is always enabled
        return true
    }
    
    func toggleAdblockerForURL(url: NSURL) {
        guard let absoluteUrl = url.absoluteString else {
            return
        }
        self.adblocker?.toggleUrl(absoluteUrl, domain: true)
    }
    
    
    //MARK: - Private methods
    
    private func getDefaultPrefs() -> [String: Bool] {
        let defaultPrefsAttrack = AntiTracking.getDefaultPrefs(true)
        let defaultPrefsAdblocker = Adblocker.getDefaultPrefs(false)
        var defaultPrefs = [String: Bool]()
        
        defaultPrefsAttrack.forEach { (k,v) in defaultPrefs[k] = v }
        defaultPrefsAdblocker.forEach { (k,v) in defaultPrefs[k] = v as? Bool }
        
        return defaultPrefs
    }
    
    private func getCompanyBadRequestsCount(trackers: [String], allTrackers: [String: AnyObject]) -> Int {
        var badRequestsCount = 0
        for tracker in trackers {
            if let trackerStatistics = allTrackers[tracker] as? [String: Int] {
                if let badRequests = trackerStatistics["bad_qs"] {
                    badRequestsCount += badRequests
                }
                if let adBlockRequests = trackerStatistics["adblock_block"] {
                    badRequestsCount += adBlockRequests
                }
            }
        }
        return badRequestsCount
    }
    
}
