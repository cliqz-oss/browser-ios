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
    fileprivate static let querySuggestionsApiUrl = "http://suggest.test.cliqz.com:7000/suggest"
    fileprivate static let dispatchQueue = DispatchQueue(label: "com.cliqz.QuerySuggestion", attributes: [])

    
    //MARK:- public APIs
    class func querySuggestionEnabledForCurrentRegion() -> Bool {
        guard let querySuggestionEnabledByABTest = LocalDataStore.objectForKey(LocalDataStore.enableQuerySuggestionKey) as? Bool else {
            // query suggestion is disabled by default except it is specified in ABTests
            return false
        }
        var region: String
        if let userRegion = SettingsPrefs.getRegionPref() {
            region = userRegion
        } else {
            region = SettingsPrefs.getDefaultRegion()
        }
        
        return querySuggestionEnabledByABTest && region == "DE"
    }
    
    class func isEnabled() -> Bool {
        guard let querySuggestionEnabledByABTest = LocalDataStore.objectForKey(LocalDataStore.enableQuerySuggestionKey) as? Bool else {
            // query suggestion is disabled by default except it is specified in ABTests
            return false
        }
        return querySuggestionEnabledByABTest && QuerySuggestions.querySuggestionEnabledForCurrentRegion() && SettingsPrefs.getQuerySuggestionPref()
    }
    
    class func getSuggestions(_ query: String, completionHandler: @escaping (Any) -> ()){
        ConnectionManager.sharedInstance
            .sendRequest(.post,
                         url: QuerySuggestions.querySuggestionsApiUrl,
                         parameters: ["query": query],
                         responseType: .jsonResponse,
                         queue: QuerySuggestions.dispatchQueue,
                         onSuccess: completionHandler,
                         onFailure: {(data, error) in
                            debugPrint("Couldn't get suggestions for query: \(query) because of the following error: \(error)")
            })
    }
    
}
