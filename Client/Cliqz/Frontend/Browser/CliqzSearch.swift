//
//  CliqzSearch.swift
//  Client
//
//  Created by Mahmoud Adam on 10/26/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit

class CliqzSearch: NSObject {
	private lazy var cachedData = Dictionary<String, [String : AnyObject]>()
	private var statisticsCollector = StatisticsCollector.sharedInstance
    
    private let searchURL = "http://newbeta.cliqz.com/api/v1/results"
    
	internal func startSearch(query: String, callback: ((query: String, data: NSDictionary)) -> Void) {
		
		if let data = cachedData[query] {
//			let html = self.parseResponse(data, history: history)
			callback((query, data))
		} else {
            statisticsCollector.startEvent(query)
            DebugingLogger.log(">> Intiating the call the the Mixer with query: \(query)")

            ConnectionManager.sharedInstance.sendRequest(.GET, url: searchURL, parameters: ["q" : query], responseType: .JSONResponse, queue: dispatch_get_main_queue(),
                onSuccess: { json in
                    self.statisticsCollector.endEvent(query)
                    DebugingLogger.log("<< Received response for query: \(query)")
                    let jsonDict = json as! [String : AnyObject]
                    self.cachedData[query] = jsonDict
//                    let html = self.parseResponse(jsonDict, history: history)
                    callback((query, jsonDict))
                    DebugingLogger.log("<< parsed response for query: \(query)")
                },
                onFailure: { (data, error) in
                    self.statisticsCollector.endEvent(query)
                    DebugingLogger.log("Request failed with error: \(error)")
                    if let data = data {
                        DebugingLogger.log("Response data: \(NSString(data: data, encoding: NSUTF8StringEncoding)!)")
                    }
            })
		}
    }

	internal func clearCache() {
		self.cachedData.removeAll()
	}

	private func parseResponse (json: NSDictionary, history: Array<Dictionary<String, String>>) -> String {
	
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
