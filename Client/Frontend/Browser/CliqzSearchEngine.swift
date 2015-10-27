//
//  CliqzSearchEngine.swift
//  Client
//
//  Created by Mahmoud Adam on 10/26/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit
import Alamofire

protocol CliqzSearchEngineDelegate : class {
    func displaySearchResults(htmlResult: String)
}

class CliqzSearchEngine: NSObject {
    weak var delegate: CliqzSearchEngineDelegate?
    let searchURL = "http://newbeta.cliqz.com/api/v1/results"
    
    func startSearch(query: String) {
        
        DebugLogger.log(">> Intiating the call the the Mixer with query: \(query)")
        Alamofire.request(.GET, searchURL, parameters: ["q": query])
            .responseJSON { request, response, result in
                switch result {
                case .Success(let json):
                    let html = self.parseResponse(json as! NSDictionary)
                    self.delegate?.displaySearchResults(html)
                    
                case .Failure(let data, let error):
                    DebugLogger.log("Request failed with error: \(error)")
                    
                    if let data = data {
                        DebugLogger.log("Response data: \(NSString(data: data, encoding: NSUTF8StringEncoding)!)")
                    }
                }
        }
    }
    func parseResponse (json: NSDictionary) -> String {
        let query = json["q"]
        DebugLogger.log("<< parsing response for query: \(query!)")
        
        var html = "<html><head></head><body>"
        
        let results = json["result"] as? NSArray
        for result in results! {
            let url = result["url"] as? String
            let snippet = result["snippet"] as? NSDictionary
            let title = snippet!["title"]
            html += "<a href='\(url!)'>\(title!)</a></br></br>"
        }
        
        html += "</body></html>"
        return html
    }
}
