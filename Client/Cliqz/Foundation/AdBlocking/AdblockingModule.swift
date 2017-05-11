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
    fileprivate let adBlockABTestPrefName = "cliqz-adb-abtest"
    fileprivate let adBlockPrefName = "cliqz-adb"
    
    
    
    //MARK: - Singltone
    static let sharedInstance = AdblockingModule()
    
    override init() {
        super.init()
    }
    
    //MARK: - Public APIs
    func initModule() {
    }
    
    func setAdblockEnabled(_ value: Bool, timeout: Int = 0) {
        Engine.sharedInstance.setPref(self.adBlockPrefName, prefValue: value ? 1 : 0)
        Engine.sharedInstance.setPref(self.adBlockABTestPrefName, prefValue: value ? true : false)
    }
    
    func isAdblockEnabled() -> Bool {
        let result = Engine.sharedInstance.getPref(self.adBlockPrefName)
        if let r = result as? Bool {
            return r
        }
        return false
    }
    
    
    //if url is blacklisted I do not block ads.
    func isUrlBlackListed(_ url:String) -> Bool {
        let response = Engine.sharedInstance.getBridge().callAction("adblocker:isDomainInBlacklist", args: [url])
        if let result = response["result"] as? Bool {
            return result
        }
        return false
    }
    
    
    func toggleUrl(_ url: URL){
        if  let host = url.host {
            let urlString = url.absoluteString
			Engine.sharedInstance.getBridge().callAction("adblocker:toggleUrl", args: [urlString, host])
        }
    }
    
    
    func getAdBlockingStatistics(_ url: URL) -> [(String, Int)] {
        var adblockingStatistics = [(String, Int)]()
		let urlString = url.absoluteString
        if let tabBlockInfo = getAdBlockingInfo(urlString) {
            if let adDict = tabBlockInfo["advertisersList"] {
                if let dict = adDict as? Dictionary<String, Array<String>> {
                    dict.keys.forEach({company in
                        adblockingStatistics.append((company, dict[company]?.count ?? 0))
                    })
                }
            }
        }
        return adblockingStatistics.sorted { $0.1 == $1.1 ? $0.0.lowercased() < $1.0.lowercased() : $0.1 > $1.1 }
    }

    //MARK: - Private Helpers
    func getAdBlockingInfo(_ url: String) -> [AnyHashable: Any]! {
        let response = Engine.sharedInstance.getBridge().callAction("adblocker:getAdBlockInfo", args: [url])    
        if let result = response["result"] {
            return result as? Dictionary
        } else {
            return [:]
        }
    }
    
}
