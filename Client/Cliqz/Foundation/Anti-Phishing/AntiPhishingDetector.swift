//
//  AntiPhishingDetector.swift
//  Client
//
//  Created by Mahmoud Adam on 8/18/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import Shared

class AntiPhishingDetector: NSObject {
    
    //MARK: - Singltone
    static let antiPhisingAPIURL = "http://antiphishing.cliqz.com/api/bwlist?md5="
    static var detectedPhishingURLs = [NSURL]()
    
    //MARK: - public APIs
    class func isPhishingURL(url: NSURL, completion:(Bool) -> Void) {
        guard url.host != "localhost" else {
            completion(false)
            return
        }
		let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
		dispatch_async(queue) { 
			AntiPhishingDetector.scanURL(url, queue: queue, completion: completion)
		}
	}

    class func isDetectedPhishingURL(url: NSURL) -> Bool {
        return detectedPhishingURLs.contains(url)
    }
    
	private class func scanURL(url: NSURL, queue: dispatch_queue_t, completion:(Bool) -> Void) {
		if let host = url.host {
			let md5Hash = md5(host)
			
			let middelIndex = md5Hash.startIndex.advancedBy(16)
			
			let md5Prefix = md5Hash.substringToIndex(middelIndex)
			let md5Suffix = md5Hash.substringFromIndex(middelIndex)
			
			let antiPhishingURL = antiPhisingAPIURL + md5Prefix
			
			ConnectionManager.sharedInstance.sendRequest(.GET, url: antiPhishingURL, parameters: nil, responseType: .JSONResponse, queue: queue, onSuccess: { (result) in
				
				if let blacklist = result["blacklist"] as? [AnyObject] {
					for suffixTuples in blacklist {
						let suffixTuplesArray = suffixTuples as! [AnyObject]
						if let suffix = suffixTuplesArray.first as? String
							where md5Suffix == suffix {
							dispatch_async(dispatch_get_main_queue(), { 
								completion(true)
                                detectedPhishingURLs.append(url)
                                NSNotificationCenter.defaultCenter().postNotificationName(NotificationRefreshAntiTrackingButton, object: nil, userInfo: nil)
							})
						}
					}
                    completion(false)
				}
				}, onFailure: { (data, error) in
					debugPrint(error)
					dispatch_async(dispatch_get_main_queue(), {
						completion(false)
					})
			})
		}
	}
}
