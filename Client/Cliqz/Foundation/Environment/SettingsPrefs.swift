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
		SettingsPrefs.updateBoolPref(AdBlockerPrefKey, value: newValue)
	}

	class func updateFairBlockingPref(newValue: Bool) {
		SettingsPrefs.updateBoolPref(FairBlockingPrefKey, value: newValue)
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
        SettingsPrefs.updateBoolPref(HumanWebPrefKey, value: newValue)
    }
    
	class func updateShowAntitrackingHintPref(newValue: Bool) {
		SettingsPrefs.updateBoolPref(ShowAntitrackingHintKey, value: newValue)
	}

	class func updateShowCliqzSearchHintPref(newValue: Bool) {
		SettingsPrefs.updateBoolPref(ShowCliqzSearchHintKey, value: newValue)
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

    // MARK: - Private helper metods
	class private func getBoolPref(forKey: String) -> Bool? {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		if let profile = appDelegate.profile {
			return profile.prefs.boolForKey(forKey)
		}
		return nil
	}
	
	class private func updateBoolPref(forKey: String, value: Bool) {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		if let profile = appDelegate.profile {
			profile.prefs.setObject(value, forKey: forKey)
		}
	}
}
