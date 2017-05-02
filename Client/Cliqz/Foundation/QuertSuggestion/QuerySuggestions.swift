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
    static let ShowSuggestionsNotification = NSNotification.Name(rawValue: "ShowSuggestionsNotification")
    
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
    
}
