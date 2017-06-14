//
//  CliqzSearch.swift
//  Client
//
//  Created by Mahmoud Adam on 10/26/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit

class CliqzSearch: NSObject {
	fileprivate lazy var cachedData = Dictionary<String, [String : Any]>()
	fileprivate var statisticsCollector = StatisticsCollector.sharedInstance
    
    fileprivate let searchURL = "http://newbeta.cliqz.com/api/v1/results"
    
	internal func startSearch(_ query: String, callback: @escaping ((query: String, data: [String: Any])) -> Void) {
		
		if let data = cachedData[query] {
//			let html = self.parseResponse(data, history: history)
			callback((query, data))
		} else {
            statisticsCollector.startEvent(query)
            DebugingLogger.log(">> Intiating the call the the Mixer with query: \(query)")

            ConnectionManager.sharedInstance.sendRequest(.get, url: searchURL, parameters: ["q" : query], responseType: .jsonResponse, queue: DispatchQueue.main,
                onSuccess: { json in
                    self.statisticsCollector.endEvent(query)
                    DebugingLogger.log("<< Received response for query: \(query)")
                    let jsonDict = json as! [String : Any]
                    self.cachedData[query] = jsonDict
//                    let html = self.parseResponse(jsonDict, history: history)
                    callback((query, jsonDict))
                    DebugingLogger.log("<< parsed response for query: \(query)")
                },
                onFailure: { (data, error) in
                    self.statisticsCollector.endEvent(query)
                    DebugingLogger.log("Request failed with error: \(error)")
                    if let data = data {
                        DebugingLogger.log("Response data: \(NSString(data: data, encoding: String.Encoding.utf8.rawValue)!)")
                    }
            })
		}
    }

	internal func clearCache() {
		self.cachedData.removeAll()
	}

	fileprivate func parseResponse (_ json: NSDictionary, history: Array<Dictionary<String, String>>) -> String {
	
        var html = "<html><head></head><body><font size='20'>"
		
		if let results = json["result"] as? [[String:AnyObject]] {
			for result in results {
				var url = ""
				if let u = result["url"] as? String {
					url = u
				}
				var snippet = [String:AnyObject]()
				if let s = result["snippet"] as? [String:AnyObject] {
					snippet = s
				}
				var title = ""
				if let t = snippet["title"] as? String {
					title = t
				}
				html += "<a href='\(url)'>\(title)</a></br></br>"
			}
		}
		for h in history {
			var url = ""
			if let u = h["url"] {
				url = u
			}
			var title = ""
			if let t = h["title"] {
				title = t
			}
			html += "<a href='\(url)' style='color: #FFA500;'>\(title)</a></br></br>"
		}

        html += "</font></body></html>"
        return html
    }
}
