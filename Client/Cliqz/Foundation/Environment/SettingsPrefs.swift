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
    static let LogTelemetryPrefKey = "showTelemetry"
    static let ShowTopSitesPrefKey = "showFreshTabTopSites"
    static let ShowNewsPrefKey = "showFreshTabNews"

	static let SearchBackendOptions = ["DE", "US", "FR"]

	var profile: Profile?

	open static var shared = SettingsPrefs()

	func getAdBlockerPref() -> Bool {
		let defaultValue = false
		if let blockAdsPref = self.getBoolPref(SettingsPrefs.AdBlockerPrefKey) {
			return blockAdsPref
		}
		return defaultValue
	}
	
	func getFairBlockingPref() -> Bool {
		let defaultValue = true
		if let FairBlockingPref = self.getBoolPref(SettingsPrefs.FairBlockingPrefKey) {
			return FairBlockingPref
		}
		return defaultValue
	}
	
	func updateAdBlockerPref(_ newValue: Bool) {
		self.updatePref(SettingsPrefs.AdBlockerPrefKey, value: newValue as AnyObject)
        AdblockingModule.sharedInstance.setAdblockEnabled(newValue)
	}

	func updateFairBlockingPref(_ newValue: Bool) {
		self.updatePref(SettingsPrefs.FairBlockingPrefKey, value: newValue as AnyObject)
	}

    func getBlockExplicitContentPref() -> Bool {
        let defaultValue = true
        if let blockExplicitContentPref = self.getBoolPref(SettingsPrefs.BlockExplicitContentPrefKey) {
            return blockExplicitContentPref
        }
        return defaultValue
    }
    
    func getHumanWebPref() -> Bool {
        let defaultValue = true
        if let humanWebPref = self.getBoolPref(SettingsPrefs.HumanWebPrefKey) {
            return humanWebPref
        }
        return defaultValue
    }
    
    func updateHumanWebPref(_ newValue: Bool) {
        self.updatePref(SettingsPrefs.HumanWebPrefKey, value: newValue as AnyObject)
    }
    
	func updateShowAntitrackingHintPref(_ newValue: Bool) {
		self.updatePref(SettingsPrefs.ShowAntitrackingHintKey, value: newValue as AnyObject)
	}

	func updateShowCliqzSearchHintPref(_ newValue: Bool) {
		self.updatePref(SettingsPrefs.ShowCliqzSearchHintKey, value: newValue as AnyObject)
	}
    
    func updateShowVideoDownloaderHintPref(_ newValue: Bool) {
        self.updatePref(SettingsPrefs.ShowVideoDownloaderHintKey, value: newValue as AnyObject)
    }

	func getShowCliqzSearchHintPref() -> Bool {
		let defaultValue = true
		if let showCliqSearchPref = self.getBoolPref(SettingsPrefs.ShowCliqzSearchHintKey) {
			return showCliqSearchPref
		}
		return defaultValue
	}

	func getShowAntitrackingHintPref() -> Bool {
		let defaultValue = true
		if let showAntitrackingHintPref = self.getBoolPref(SettingsPrefs.ShowAntitrackingHintKey) {
			return showAntitrackingHintPref
		}
		return defaultValue
    }
    
    func getShowVideoDownloaderHintPref() -> Bool {
        let defaultValue = true
        if let showVideoDownloaderPref = self.getBoolPref(SettingsPrefs.ShowVideoDownloaderHintKey) {
            return showVideoDownloaderPref
        }
        return defaultValue
    }

    
    func getBlockPopupsPref() -> Bool {
        let defaultValue = true
        if let blockPopupsPref = self.getBoolPref(SettingsPrefs.blockPopupsPrefKey) {
            return blockPopupsPref
        }
        return defaultValue
    }
    
    func updateBlockPopupsPref(_ newValue: Bool) {
        self.updatePref(SettingsPrefs.blockPopupsPrefKey, value: newValue as AnyObject)
    }

    func getRegionPref() -> String? {
        return self.getStringPref(SettingsPrefs.countryPrefKey)
    }

    func getDefaultRegion() -> String {
        let currentLocale = Locale.current
		let langToRegionMapping = ["de": "DE", "en": "US", "fr": "FR"]
        if let languageCode = currentLocale.languageCode,
			langToRegionMapping.keys.contains(languageCode),
			let val = langToRegionMapping[languageCode] {
            return val
        }
        return "US"
    }

    func updateRegionPref(_ newValue: String) {
        self.updatePref(SettingsPrefs.countryPrefKey, value: newValue as AnyObject)
    }

    func updateQuerySuggestionPref(_ newValue: Bool) {
        self.updatePref(SettingsPrefs.querySuggestionPrefKey, value: newValue as AnyObject)
    }

    func getQuerySuggestionPref() -> Bool {
        let defaultValue = true
        if let querySuggestionPref = self.getBoolPref(SettingsPrefs.querySuggestionPrefKey) {
            return querySuggestionPref
        }
        return defaultValue
    }
    
    func getLimitMobileDataUsagePref() -> Bool {
        let defaultValue = true
        if let LimitMobileDataUsagePref = SettingsPrefs.shared.getBoolPref(SettingsPrefs.LimitMobileDataUsagePrefKey) {
            return LimitMobileDataUsagePref
        }
        return defaultValue
    }
    
    func updateLimitMobileDataUsagePref(_ newValue: Bool) {
        self.updatePref(SettingsPrefs.LimitMobileDataUsagePrefKey, value: newValue as AnyObject)
    }
    
    func getAutoForgetTabPref() -> Bool {
        let defaultValue = true
        if let AutoForgetTabPref = self.getBoolPref(SettingsPrefs.AutoForgetTabPrefKey) {
            return AutoForgetTabPref
        }
        return defaultValue
    }
    
    func updateAutoForgetTabPref(_ newValue: Bool) {
        self.updatePref(SettingsPrefs.AutoForgetTabPrefKey, value: newValue as AnyObject)
        
        if newValue == true {
            BloomFilterManager.sharedInstance.turnOn()
        } else {
            BloomFilterManager.sharedInstance.turnOff()
        }
        
    }
    
    func getLogTelemetryPref() -> Bool {
        return self.getBoolPref(SettingsPrefs.LogTelemetryPrefKey) ?? false
    }
    
    func getShowTopSitesPref() -> Bool {
        return self.getBoolPref(SettingsPrefs.ShowTopSitesPrefKey) ?? true
    }
    
    func getShowNewsPref() -> Bool {
        return self.getBoolPref(SettingsPrefs.ShowNewsPrefKey) ?? true
    }
    
    // MARK: - Private helper metods
	fileprivate func getBoolPref(_ forKey: String) -> Bool? {
		
		if let p = self.profile {
			return p.prefs.boolForKey(forKey)
		}
		return nil
	}
	
	fileprivate func updatePref(_ forKey: String, value: AnyObject) {
		if let p = self.profile {
			p.prefs.setObject(value, forKey: forKey)
		}
	}
    
    fileprivate func getStringPref(_ forKey: String) -> String? {
		if let p = self.profile {
            return p.prefs.stringForKey(forKey)
        }
        return nil
    }
    
}
