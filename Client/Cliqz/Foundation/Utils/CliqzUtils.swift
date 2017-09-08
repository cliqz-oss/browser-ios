//
//  CliqzUtils.swift
//  Client
//
//  Created by Sahakyan on 8/4/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import WebKit

func ensureMainThread(_ closure:()->()) {
	if Thread.isMainThread {
		closure()
	} else {
		DispatchQueue.main.sync(execute: closure)
	}
}

struct DangerousReturnWKNavigation {
	static let emptyNav = WKNavigation()
}

func md5(_ string: String) -> String {
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    if let data = string.data(using: String.Encoding.utf8) {
        CC_MD5((data as NSData).bytes, CC_LONG(data.count), &digest)
    }
    
    var digestHex = ""
    for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
        digestHex += String(format: "%02x", digest[index])
    }
    
    return digestHex
}

func postAsyncToMain(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func getApp() -> AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
}

func getCurrentWebView() -> CliqzWebView? {
    return getApp().browserViewController.tabManager.selectedTab?.webView
}

func isCliqzGoToURL(url: URL?) -> Bool {
    if let url = url, url.isLocal {
		let absoluteString = url.absoluteString
        return absoluteString.contains("cliqz/goto.html?")
    }
    return false
}
