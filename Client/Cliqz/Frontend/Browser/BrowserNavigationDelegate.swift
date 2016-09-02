//
//  BrowserNavigationDelegate.swift
//  Client
//
//  Created by Sahakyan on 8/31/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

protocol BrowserNavigationDelegate: class {

	func navigateToURL(url: NSURL)
	func navigateToURLInNewTab(url: NSURL)
	func navigateToQuery(query: String)

}