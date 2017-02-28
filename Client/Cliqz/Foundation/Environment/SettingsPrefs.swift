//
//  SettingsPrefs.swift
//  Client
//
//  Created by Sahakyan on 9/1/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class SettingsPrefs {

	static let AdBlockerPrefKey = "blockAds"
	static let FairBlockingPrefKey = "fairBlocking"
	static let BlockExplicitContentPrefKey = "blockContent"
    static let HumanWebPrefKey = "humanweb.toggle"
	static let ShowAntitrackingHintKey = "showAntitrackingHint"
	static let ShowCliqzSearchHintKey = "showCliqzSearchHint"
    static let blockPopupsPrefKey = "blockPopups"
    static let countryPrefKey = "UserCountry"
    static let querySuggestionPrefKey = "QuerySuggestion"

	class func getAdBlockerPref() -> Bool {
		let defaultValue = false
		if let blockAdsPref = SettingsPrefs.getBoolPref(AdBlockerPrefKey) {
			return blockAdsPref
		}
		return defaultValue
	}
	
	class func getFairBlockingPref() -> Bool {
		let defaultValue = true
		if let FairBlockingPref = SettingsPrefs.getBoolPref(FairBlockingPrefKey) {
			return FairBlockingPref
		}
		return defaultValue
	}
	
	class func updateAdBlockerPref(newValue: Bool) {
		SettingsPrefs.updatePref(AdBlockerPrefKey, value: newValue)
        AdblockingModule.sharedInstance.setAdblockEnabled(newValue)
	}

	class func updateFairBlockingPref(newValue: Bool) {
		SettingsPrefs.updatePref(FairBlockingPrefKey, value: newValue)
	}

    class func getBlockExplicitContentPref() -> Bool {
        let defaultValue = true
        if let blockExplicitContentPref = SettingsPrefs.getBoolPref(BlockExplicitContentPrefKey) {
            return blockExplicitContentPref
        }
        return defaultValue
    }
    
    class func getHumanWebPref() -> Bool {
        let defaultValue = true
        if let humanWebPref = SettingsPrefs.getBoolPref(HumanWebPrefKey) {
            return humanWebPref
        }
        return defaultValue
    }
    
    class func updateHumanWebPref(newValue: Bool) {
        SettingsPrefs.updatePref(HumanWebPrefKey, value: newValue)
    }
    
	class func updateShowAntitrackingHintPref(newValue: Bool) {
		SettingsPrefs.updatePref(ShowAntitrackingHintKey, value: newValue)
	}

	class func updateShowCliqzSearchHintPref(newValue: Bool) {
		SettingsPrefs.updatePref(ShowCliqzSearchHintKey, value: newValue)
	}

	class func getShowCliqzSearchHintPref() -> Bool {
		let defaultValue = true
		if let showCliqSearchPref = SettingsPrefs.getBoolPref(ShowCliqzSearchHintKey) {
			return showCliqSearchPref
		}
		return defaultValue
	}

	class func getShowAntitrackingHintPref() -> Bool {
		let defaultValue = true
		if let showAntitrackingHintPref = SettingsPrefs.getBoolPref(ShowAntitrackingHintKey) {
			return showAntitrackingHintPref
		}
		return defaultValue
	}

    
    class func getBlockPopupsPref() -> Bool {
        let defaultValue = true
        if let blockPopupsPref = SettingsPrefs.getBoolPref(blockPopupsPrefKey) {
            return blockPopupsPref
        }
        return defaultValue
    }
    
    class func updateBlockPopupsPref(newValue: Bool) {
        SettingsPrefs.updatePref(blockPopupsPrefKey, value: newValue)
    }
    
    class func getRegionPref() -> String? {
        return SettingsPrefs.getStringPref(countryPrefKey)
    }
    
    class func getDefaultRegion() -> String {
        let availableCountries = ["DE", "US", "UK", "FR"]
        let currentLocale = NSLocale.currentLocale()
        if let countryCode = currentLocale.objectForKey(NSLocaleCountryCode) as? String where availableCountries.contains(countryCode) {
            return countryCode
        }
        return "DE"
    }
    
    class func updateRegionPref(newValue: String) {
        SettingsPrefs.updatePref(countryPrefKey, value: newValue)
    }
    
    class func updateQuerySuggestionPref(newValue: Bool) {
        SettingsPrefs.updatePref(querySuggestionPrefKey, value: newValue)
    }
    
    class func getQuerySuggestionPref() -> Bool {
        let defaultValue = true
        if let querySuggestionPref = SettingsPrefs.getBoolPref(querySuggestionPrefKey) {
            return querySuggestionPref
        }
        return defaultValue
    }
    
    // MARK: - Private helper metods
	class private func getBoolPref(forKey: String) -> Bool? {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		if let profile = appDelegate.profile {
			return profile.prefs.boolForKey(forKey)
		}
		return nil
	}
	
	class private func updatePref(forKey: String, value: AnyObject) {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		if let profile = appDelegate.profile {
			profile.prefs.setObject(value, forKey: forKey)
		}
	}
    
    class private func getStringPref(forKey: String) -> String? {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let profile = appDelegate.profile {
            return profile.prefs.stringForKey(forKey)
        }
        return nil
    }
    
    
}
