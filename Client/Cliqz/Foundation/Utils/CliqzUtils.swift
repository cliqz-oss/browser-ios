//
//  CliqzUtils.swift
//  Client
//
//  Created by Sahakyan on 8/4/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import WebKit

func ensureMainThread(closure:()->()) {
	if NSThread.isMainThread() {
		closure()
	} else {
		dispatch_sync(dispatch_get_main_queue(), closure)
	}
}

struct DangerousReturnWKNavigation {
	static let emptyNav = WKNavigation()
}

func md5(string: String) -> String {
    var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
    if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
        CC_MD5(data.bytes, CC_LONG(data.length), &digest)
    }
    
    var digestHex = ""
    for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
        digestHex += String(format: "%02x", digest[index])
    }
    
    return digestHex
}

func postAsyncToMain(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

func getApp() -> AppDelegate {
    return UIApplication.sharedApplication().delegate as! AppDelegate
}

func getCurrentWebView() -> CliqzWebView? {
    return getApp().browserViewController.tabManager.selectedTab?.webView
}

func getHostComponents(forURL url: String) -> [String] {
    var local_url = url
	var result = [String]()
	var domainIndex = Int.max
	let excludablePrefixes: Set<String> = ["www", "m", "mobile"]
    if local_url == "cliqz.com" {
        local_url = "https://www.cliqz.com"
    }
	if let url = NSURL(string: local_url),
		host = url.host {
		let comps = host.componentsSeparatedByString(".")
		domainIndex = comps.count - 1
		if let lastComp = comps.last,
			firstLevel = LogoLoader.topDomains[lastComp] where firstLevel == "cc" && comps.count > 2 {
			if let _ = LogoLoader.topDomains[comps[comps.count - 2]] {
				domainIndex = comps.count - 2
			}
		}
		let firstIndex = domainIndex - 1
		var secondIndex = -1
		if firstIndex > 0 {
			secondIndex = firstIndex - 1
		}
		if secondIndex >= 0 && excludablePrefixes.contains(comps[secondIndex]) {
			secondIndex = -1
		}
		if firstIndex > -1 {
			result.append(comps[firstIndex])
		}
		if secondIndex > -1 && secondIndex < domainIndex {
			result.append(comps[secondIndex])
		}
	}
	return result
}

func isCliqzGoToURL(url: NSURL?) -> Bool {
    if let url = url, absoluteString = url.absoluteString where url.isLocal {
        return absoluteString.contains("cliqz/goto.html?")
    }
    return false
}
