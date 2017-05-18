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
	}
	
	@objc(queryCliqz:)
	public func queryCliqz(url: NSString) {
		print("Hello React")
	}
}
