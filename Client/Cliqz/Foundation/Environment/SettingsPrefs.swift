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
    static let ShowVideoDownloaderHintKey = "ShowVideoDownloaderHint"
    static let blockPopupsPrefKey = "blockPopups"
    static let countryPrefKey = "UserCountry"
    static let querySuggestionPrefKey = "QuerySuggestion"
    static let LimitMobileDataUsagePrefKey = "LimitMobileDataUsage"
    static let AutoForgetTabPrefKey = "AutoForgetTab"

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
	
	class func updateAdBlockerPref(_ newValue: Bool) {
		SettingsPrefs.updatePref(AdBlockerPrefKey, value: newValue as AnyObject)
        AdblockingModule.sharedInstance.setAdblockEnabled(newValue)
	}

	class func updateFairBlockingPref(_ newValue: Bool) {
		SettingsPrefs.updatePref(FairBlockingPrefKey, value: newValue as AnyObject)
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
    
    class func updateHumanWebPref(_ newValue: Bool) {
        SettingsPrefs.updatePref(HumanWebPrefKey, value: newValue as AnyObject)
    }
    
	class func updateShowAntitrackingHintPref(_ newValue: Bool) {
		SettingsPrefs.updatePref(ShowAntitrackingHintKey, value: newValue as AnyObject)
	}

	class func updateShowCliqzSearchHintPref(_ newValue: Bool) {
		SettingsPrefs.updatePref(ShowCliqzSearchHintKey, value: newValue as AnyObject)
	}
    
    class func updateShowVideoDownloaderHintPref(_ newValue: Bool) {
        SettingsPrefs.updatePref(ShowVideoDownloaderHintKey, value: newValue as AnyObject)
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
    
    class func getShowVideoDownloaderHintPref() -> Bool {
        let defaultValue = true
        if let showVideoDownloaderPref = SettingsPrefs.getBoolPref(ShowVideoDownloaderHintKey) {
            return showVideoDownloaderPref
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
    
    class func updateBlockPopupsPref(_ newValue: Bool) {
        SettingsPrefs.updatePref(blockPopupsPrefKey, value: newValue as AnyObject)
    }
    
    class func getRegionPref() -> String? {
        return SettingsPrefs.getStringPref(countryPrefKey)
    }
    
    class func getDefaultRegion() -> String {
        let availableCountries = ["DE", "US", "UK", "FR"]
        let currentLocale = Locale.current
        if let countryCode = currentLocale.regionCode, availableCountries.contains(countryCode) {
            return countryCode
        }
        return "DE"
    }
    
    class func updateRegionPref(_ newValue: String) {
        SettingsPrefs.updatePref(countryPrefKey, value: newValue as AnyObject)
    }
    
    class func updateQuerySuggestionPref(_ newValue: Bool) {
        SettingsPrefs.updatePref(querySuggestionPrefKey, value: newValue as AnyObject)
    }
    
    class func getQuerySuggestionPref() -> Bool {
        let defaultValue = true
        if let querySuggestionPref = SettingsPrefs.getBoolPref(querySuggestionPrefKey) {
            return querySuggestionPref
        }
        return defaultValue
    }
    
    class func getLimitMobileDataUsagePref() -> Bool {
        let defaultValue = true
        if let LimitMobileDataUsagePref = SettingsPrefs.getBoolPref(LimitMobileDataUsagePrefKey) {
            return LimitMobileDataUsagePref
        }
        return defaultValue
    }
    
    class func updateLimitMobileDataUsagePref(_ newValue: Bool) {
        SettingsPrefs.updatePref(LimitMobileDataUsagePrefKey, value: newValue as AnyObject)
    }
    
    class func getAutoForgetTabPref() -> Bool {
        let defaultValue = true
        if let AutoForgetTabPref = SettingsPrefs.getBoolPref(AutoForgetTabPrefKey) {
            return AutoForgetTabPref
        }
        return defaultValue
    }
    
    class func updateAutoForgetTabPref(_ newValue: Bool) {
        
        SettingsPrefs.updatePref(AutoForgetTabPrefKey, value: newValue as AnyObject)
        
        if newValue == true {
            BloomFilterManager.sharedInstance.turnOn()
        } else {
            BloomFilterManager.sharedInstance.turnOff()
        }
        
    }
    
    // MARK: - Private helper metods
	class fileprivate func getBoolPref(_ forKey: String) -> Bool? {
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		if let profile = appDelegate.profile {
			return profile.prefs.boolForKey(forKey)
		}
		return nil
	}
	
	class fileprivate func updatePref(_ forKey: String, value: AnyObject) {
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		if let profile = appDelegate.profile {
			profile.prefs.setObject(value, forKey: forKey)
		}
	}
    
    class fileprivate func getStringPref(_ forKey: String) -> String? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let profile = appDelegate.profile {
            return profile.prefs.stringForKey(forKey)
        }
        return nil
    }
    
    
}
