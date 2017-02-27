//
//  QuerySuggestions.swift
//  Client
//
//  Created by Mahmoud Adam on 2/27/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class QuerySuggestions: NSObject {
    //MARK:- Constants
    private static let querySuggestionsApiUrl = "http://suggest.test.cliqz.com:7000/suggest"
    private static let dispatchQueue = dispatch_queue_create("com.cliqz.QuerySuggestion", DISPATCH_QUEUE_SERIAL)

    
    //MARK:- public APIs
    class func querySuggestionSettingEnabled() -> Bool {
        var region: String
        if let userRegion = SettingsPrefs.getRegionPref() {
            region = userRegion
        } else {
            region = SettingsPrefs.getDefaultRegion()
        }
        
        return region == "DE"
    }
    
    class func isEnabled() -> Bool {
        
        return QuerySuggestions.querySuggestionSettingEnabled() && SettingsPrefs.getQuerySuggestionPref() == true
    }
    
    class func getSuggestions(query: String, completionHandler: AnyObject -> ()){
        ConnectionManager.sharedInstance
            .sendRequest(.POST,
                         url: QuerySuggestions.querySuggestionsApiUrl,
                         parameters: ["query": query],
                         responseType: .JSONResponse,
                         queue: QuerySuggestions.dispatchQueue,
                         onSuccess: completionHandler,
                         onFailure: {(data, error) in
                            print("Couldn't get suggestions for query: \(query) because of the following error: \(error)")
            })
    }
    
}
