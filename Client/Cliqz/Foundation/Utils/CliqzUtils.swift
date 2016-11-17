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
