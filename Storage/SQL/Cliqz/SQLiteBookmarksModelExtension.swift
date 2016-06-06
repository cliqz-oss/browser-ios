//
//  SQLiteBookmarksModelExtension.swift
//  Client
//
//  Created by Sahakyan on 6/2/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

import Shared
import Deferred
import XCGLogger

private let log = Logger.syncLogger


public protocol CliqzSQLiteBookmarks {

	func getBookmarks() -> Deferred<Maybe<Cursor<BookmarkNode>>>

}
