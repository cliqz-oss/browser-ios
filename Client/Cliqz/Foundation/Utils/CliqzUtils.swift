//
//  CliqzUtils.swift
//  Client
//
//  Created by Sahakyan on 8/4/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import WebKit

func ensureMainThread(closure:()->()) {
	if NSThread.isMainThread() {
		closure()
	} else {
		dispatch_sync(dispatch_get_main_queue(), closure)
	}
}

struct DangerousReturnWKNavigation {
	static let emptyNav = WKNavigation()
}