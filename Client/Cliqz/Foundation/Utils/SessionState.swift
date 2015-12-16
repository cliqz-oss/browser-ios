//
//  SessionState.swift
//  Client
//
//  Created by Sahakyan on 12/16/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import Foundation

class SessionState {

	static let lastVisitedKey = "lastVisitedDate"
	static let timeoutDuration: Double = 900
	static var isTimeout: Bool = false

	class func sessionPaused() {
		let userDefaulst = NSUserDefaults.standardUserDefaults()
		userDefaulst.setValue(NSDate(), forKey: lastVisitedKey)
		userDefaulst.synchronize()
	}

	class func sessionResumed() {
		let userDefaulst = NSUserDefaults.standardUserDefaults()
		if let date = userDefaulst.valueForKey(lastVisitedKey) as? NSDate {
			isTimeout = NSDate().timeIntervalSinceDate(date) > timeoutDuration
		}
	}

	class func isSessionExpired() -> Bool {
		return isTimeout
	}
}