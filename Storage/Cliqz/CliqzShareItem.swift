//
//  CliqzShareItem.swift
//  Client
//
//  Created by Sahakyan on 6/1/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import Shared

public struct CliqzShareItem  {
	public let url: String
	public let title: String?
	public let favicon: Favicon?
	public let bookmarkedDate: Timestamp
	
	public init(url: String, title: String?, favicon: Favicon?, bookmarkedDate: Timestamp) {
		self.url = url
		self.title = title
		self.favicon = favicon
		self.bookmarkedDate = bookmarkedDate
	}
}

public protocol CliqzShareToDestination {
	func shareItem(_ item: CliqzShareItem)
}
