//
//  ConversationalHistoryAPI.swift
//  Client
//
//  Created by Sahakyan on 12/8/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
//import UIKit
import Storage
import Shared
import Alamofire

// DEPRECATED: Now the history is handled natively.


//func md5_(string: String) -> String {
//	var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
//	if let data = string.data(using: String.Encoding.utf8) {
//		CC_MD5(data.bytes, CC_LONG(data.length), &digest)
//	}
//	
//	var digestHex = ""
//	for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
//		digestHex += String(format: "%02x", digest[index])
//	}
//	
//	return digestHex
//}

class ConversationalHistoryAPI {
	
//	static let host = "https://hs.cliqz.com/"
//	static let uniqueID: String = {
//		if let ID = UIDevice().identifierForVendor {
//			return md5_(ID.UUIDString)
//		}
//		return "000"
//	}()

	class func pushHistoryItem(visit: SiteVisit) {
        HistoryBridge.addHistoryItem(history: self.generateParamsForHistoryItem(url: visit.site.url, title: visit.site.title, visitedDate: visit.date))
	}
	
	class func getHistory(callback: @escaping (NSDictionary) -> Void) {
        Engine.sharedInstance.getHistory().getHistory { history in
            DispatchQueue.main.async() {
                callback(history)
            }
        }
	}

	class func pushAllHistory(history: Cursor<Site>?, completionHandler:@escaping (NSError?) -> Void) {
		if let sites = history {
			var historyResults = [[String: AnyObject]]()
			for site in sites {
				historyResults.append(self.generateParamsForHistoryItem(url: (site?.url)!, title: (site?.title)!, visitedDate: (site?.latestVisit!.date)!))
			}
            Engine.sharedInstance.getHistory().bulkAddHistory(history: historyResults, completionHandler: completionHandler)
		}
	}

	class func pushURLAndQuery(url: String, query: String) {
	}

	class func pushMetadata(metadata: [String: AnyObject], url: String) {
	}
    
    class func homePressed() {
        Engine.sharedInstance.getBridge().publishEvent("browser:home-pressed", args: [])
    }

	private class func generateParamsForHistoryItem(url: String, title: String, visitedDate: MicrosecondTimestamp) -> [String: AnyObject] {
		return ["url": url as AnyObject,
		        "title": title as AnyObject,
			    "lastVisitDate": NSNumber(value:visitedDate) as AnyObject]
	}

}
