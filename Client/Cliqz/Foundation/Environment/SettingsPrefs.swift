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