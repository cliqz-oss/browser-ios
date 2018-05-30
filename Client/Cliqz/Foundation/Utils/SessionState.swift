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
	static let timeoutDuration: Double = 1800
	static var isTimeout: Bool = false
	class func sessionPaused() {
        LocalDataStore.setObject(NSDate(), forKey: lastVisitedKey)
	}

	class func sessionResumed() {
		if let date = LocalDataStore.objectForKey(lastVisitedKey) as? NSDate {
			isTimeout = NSDate().timeIntervalSinceDate(date) > timeoutDuration
		}
	}

	class func isSessionExpired() -> Bool {
		return isTimeout
	}
}