//
//  ReactHomeViewController.swift
//  Client
//
//  Created by Sahakyan on 5/18/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

@objc(BrowserActions)
public class BrowserActions: NSObject {
	
	@objc(openLink:)
	public func openLink(url: NSString) {
		print("Hello React")
		if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, u = NSURL(string:url as String) {
			appDelegate.openUrlInWebView(u)
		}
	}
	
	@objc(queryCliqz:)
	public func queryCliqz(url: NSString) {
		print("Hello React")
	}
}
