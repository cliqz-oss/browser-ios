//
//  BrowserViewControllerExtension.swift
//  Client
//
//  Created by Sahakyan on 4/28/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

extension BrowserViewController {
	
	func loadInitialURL() {
		if let urlString = self.initialURL,
		   let url = NSURL(string: urlString) {
			self.navigateToURL(url)
		}
	}
}