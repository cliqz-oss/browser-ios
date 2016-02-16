//
//  AdBlocker.swift
//  Client
//
//  Created by Mahmoud Adam on 2/16/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class AdBlocker {
    var adsServerList: NSSet?
    
    
    init() {
        let dispatchQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
        dispatch_async(dispatchQueue) {
            if let bundlePath = NSBundle.mainBundle().pathForResource("AdServers", ofType: "plist") {
                let adsServerArray = NSArray(contentsOfFile:bundlePath)
                self.adsServerList = NSSet(array: adsServerArray as! [AnyObject])
            }
        }
    }
    
    func isAdServer(url: NSURL) -> Bool {
        let absoluteURL = url.absoluteString
        // discard local host url, i.e. home, trampoline,...
        if absoluteURL.hasPrefix("http://localhost") {
            return false
        }
        if absoluteURL == "about:blank" {
            return false
        }
        if let host = url.host,
            let adsServers = adsServerList {
            if adsServers.containsObject(host) {
                return true
            }
        }
        return false
    }
}
