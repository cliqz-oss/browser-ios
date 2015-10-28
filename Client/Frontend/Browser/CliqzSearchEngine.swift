//
//  CliqzSearchEngine.swift
//  Client
//
//  Created by Mahmoud Adam on 10/26/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit
import Alamofire

class CliqzSearchEngine: NSObject {
	private lazy var cachedData = Dictionary<String, [String : AnyObject]>()
	private var statisticsCollector = StatisticsCollector.sharedInstance
    
    private let searchURL = "http://newbeta.cliqz.com/api/v1/results"
    
	internal func startSearch(query: String, callback: ((query: String, data: String)) -> Void) {
		
		if let data = cachedData[query] {
			let html = self.parseResponse(data)
			callback((query, html))
		} else {
            statisticsCollector.startEvent(query)
            DebugLogger.log(">> Intiating the call the the Mixer with query: \(query)")
			Alamofire.request(.GET, searchURL, parameters: ["q": query])
				.responseJSON {
					request, response, result in
					switch result {
						
					case .Success(let json):
						let jsonDict = json as! [String : AnyObject]
						self.cachedData[query] = jsonDict
						let html = self.parseResponse(jsonDict)
						callback((query, html))
                        self.statisticsCollector.endEvent(query)
                        DebugLogger.log("<< parsed response for query: \(query)")
						
					case .Failure(let data, let error):
						DebugLogger.log("Request failed with error: \(error)")

						if let data = data {
							DebugLogger.log("Response data: \(NSString(data: data, encoding: NSUTF8StringEncoding)!)")
						}
					}
			}
		}
    }

	internal func clearCache() {
		self.cachedData.removeAll()
	}
	
    private func parseResponse (json: [String : AnyObject]) -> String {
        
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
				html += "<a href='\(url)' >\(title)</a></br></br>"
			}
		}

        html += "</font></body></html>"
        return html
    }
}
