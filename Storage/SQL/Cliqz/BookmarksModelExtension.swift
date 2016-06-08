//
//  BookmarksModelExtension.swift
//  Client
//
//  Created by Sahakyan on 6/3/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import Shared

public class CliqzBookmarkItem: BookmarkItem {
	public let bookmarkedDate: Timestamp!
	
	public init(guid: String, title: String, url: String, bookmarkedDate: Timestamp, isEditable: Bool=false) {
		self.bookmarkedDate = bookmarkedDate
		super.init(guid: guid, title: title, url: url, isEditable: isEditable)
	}
}