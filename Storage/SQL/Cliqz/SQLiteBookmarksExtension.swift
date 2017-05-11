//
//  SQLiteBookmarksExtension.swift
//  Client
//
//  Created by Sahakyan on 6/1/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

import Shared
import Deferred
import XCGLogger


private let log = Logger.syncLogger

extension SQLiteBookmarks: CliqzShareToDestination {
	public func addToMobileBookmarks(_ url: URL, title: String, favicon: Favicon?, bookmarkedDate: Timestamp) -> Success {
		return self.insertBookmark(url, title: title, favicon: favicon, bookmarkedDate: bookmarkedDate,
		                           intoFolder: BookmarkRoots.MobileFolderGUID,
		                           withTitle: BookmarksFolderTitleMobile)
	}
	
	public func shareItem(_ item: CliqzShareItem) {
		// We parse here in anticipation of getting real URLs at some point.
		if let url = item.url.asURL {
			let title = item.title ?? url.absoluteString
			self.addToMobileBookmarks(url, title: title, favicon: item.favicon, bookmarkedDate: item.bookmarkedDate)
		}
	}
	
	fileprivate func insertBookmarkInTransaction(_ deferred: Success, url: URL, title: String, favicon: Favicon?, bookmarkedDate: Timestamp, intoFolder parent: GUID, withTitle parentTitle: String) -> (_ conn: SQLiteDBConnection, _ err: inout NSError?) -> Bool {
		
		return { (conn: SQLiteDBConnection, err: inout NSError?) -> Bool in

		log.debug("Inserting Cliqz bookmark in transaction on thread \(Thread.current)")
		
		// Keep going if this returns true.
		func change(_ sql: String, args: Args?, desc: String) -> Bool {
			err = conn.executeChange(sql, withArgs: args)
			if let err = err {
				log.error(desc)
				deferred.fillIfUnfilled(Maybe(failure: DatabaseError(err: err)))
				return false
			}
			return true
		}
		
		let urlString = url.absoluteString
		let newGUID = Bytes.generateGUID()
		
		//// Insert the new bookmark and icon without touching structure.
		var args: Args = [
			newGUID as AnyObject?,
			BookmarkNodeType.bookmark.rawValue as AnyObject?,
			urlString as AnyObject?,
			title as AnyObject?,
			parent as AnyObject?,
			parentTitle as AnyObject?,
			Date.nowNumber(),
			SyncStatus.new.rawValue as AnyObject?,
			NSNumber(value: bookmarkedDate)
			]
		
		let faviconID: Int?
		
		// Insert the favicon.
		if let icon = favicon {
			faviconID = self.favicons.insertOrUpdate(conn, obj: icon)
		} else {
			faviconID = nil
		}
		
		log.debug("Cliqz: Inserting bookmark with GUID \(newGUID) and specified icon \(faviconID).")
		
		// If the caller didn't provide an icon (and they usually don't!),
		// do a reverse lookup in history. We use a view to make this simple.
		let iconValue: String
		if let faviconID = faviconID {
			iconValue = "?"
			args.append(faviconID as AnyObject?)
		} else {
			iconValue = "(SELECT iconID FROM \(ViewIconForURL) WHERE url = ?)"
			args.append(urlString as AnyObject?)
		}
		
		let insertSQL = "INSERT INTO \(TableBookmarksLocal) " +
			"(guid, type, bmkUri, title, parentid, parentName, local_modified, sync_status, bookmarked_date, faviconID) " +
			"VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, \(iconValue))"
		if !change(insertSQL, args: args, desc: "Error inserting \(newGUID).") {
			return false
		}

		log.debug("Cliqz: Returning true to commit transaction on thread \(Thread.current)")
		
		/// Fill the deferred and commit the transaction.
		deferred.fill(Maybe(success: ()))
		return true
		}
	}
	
	/**
	* Assumption: the provided folder GUID exists in either the local table or the mirror table.
	*/
	func insertBookmark(_ url: URL, title: String, favicon: Favicon?, bookmarkedDate: Timestamp, intoFolder parent: GUID, withTitle parentTitle: String) -> Success {
		log.debug("Cliqz: Inserting bookmark task on thread \(Thread.current)")
		let deferred = Success()
		
		var error: NSError?
		let inTransaction = self.insertBookmarkInTransaction(deferred, url: url, title: title, favicon: favicon, bookmarkedDate: bookmarkedDate, intoFolder: parent, withTitle: parentTitle)
		error = self.db.transaction(synchronous: false, err: &error, callback: inTransaction)
		
		log.debug("Cliqz: Returning deferred on thread \(Thread.current)")
		return deferred
	}

}

extension MergedSQLiteBookmarks: CliqzShareToDestination {
	public func shareItem(_ item: CliqzShareItem) {
		self.local.shareItem(item)
	}
}
