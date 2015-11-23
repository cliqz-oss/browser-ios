//
//  SearchContentGenerator.swift
//  Client
//
//  Created by Sahakyan on 11/10/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import Foundation

class SearchContentGenerator {

	class func generateContent(data: NSDictionary, history: Array<Dictionary<String, String>>) -> String {
		var html = "<html><head></head><body><font size='20'>"
		
		if let results = data["result"] as? [[String:AnyObject]] {
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