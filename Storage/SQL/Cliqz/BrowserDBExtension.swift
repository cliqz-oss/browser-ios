//
//  BrowserDBExtension.swift
//  Client
//
//  Created by Sahakyan on 6/1/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import Deferred
import Shared

public let NotificationDatabaseWasCreated = "NotificationDatabaseWasCreated"

extension BrowserDB {

	func extendTables() {
		let columnName = "bookmarked_date"
		if !isColumnExist(TableBookmarksLocal, columnName: columnName) {
			let r = alterTableWithExtraColumn(TableBookmarksLocal, columnName: columnName)
			switch  (r.value) {
			case .Failure:
				let notificationCenter = NSNotificationCenter.defaultCenter()
				notificationCenter.addObserver(self, selector: #selector(BrowserDB.onDatabaseCreation(_:)), name: NotificationDatabaseWasCreated, object: nil)
			default:
				migrateOldBookmarks()
			}
		}
	}

	private func alterTableWithExtraColumn(tableName: String, columnName: String) -> Success {
		return self.run([
				("ALTER TABLE \(tableName) ADD COLUMN \(columnName) INTEGER NOT NULL DEFAULT 0", nil)
				])
	}

	private func isColumnExist(tableName: String, columnName: String) -> Bool {
		let tableInfoSQL = "PRAGMA table_info(\(tableName))"

		let result = self.runQuery(tableInfoSQL, args: nil, factory: BrowserDB.columnNameFactory).value
		if let columnNames = result.successValue {
			for tableColumnName in columnNames {
				if tableColumnName == columnName {
					return true
				}
			}
		}
		return false
	}
	
	private class func columnNameFactory(row: SDRow) -> String {
		let columnName = row["name"] as! String
		return columnName
	}

	@objc func onDatabaseCreation(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) {
			self.extendBookmarksTable()
			NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDatabaseWasCreated, object: nil)
		}
	}
	
	private func extendBookmarksTable() {
		self.alterTableWithExtraColumn(TableBookmarksLocal, columnName: "bookmarked_date")
		self.migrateOldBookmarks()
	}

	private func migrateOldBookmarks() {
		if isColumnExist(TableVisits, columnName: "favorite") {
			let fetchFavoritesSQL = "SELECT \(TableVisits).id, \(TableVisits).date, \(TableHistory).url, \(TableHistory).title " +
				"FROM \(TableHistory) " +
				"INNER JOIN \(TableVisits) ON \(TableVisits).siteID = \(TableHistory).id " +
				"WHERE \(TableVisits).favorite = 1 "
			let results = self.runQuery(fetchFavoritesSQL, args: nil, factory: SQLiteHistory.historyVisitsFactory).value
			if let favs = results.successValue {
				for f in favs {
					if !isURLBookmarked(f?.url) {
						let newGUID = Bytes.generateGUID()
						let args: Args = [
							newGUID,
							BookmarkNodeType.Bookmark.rawValue,
							f?.url,
							f?.title,
							BookmarkRoots.MobileFolderGUID,
							BookmarksFolderTitleMobile,
							NSNumber(unsignedLongLong: (f?.latestVisit?.date)! / 1000),
							SyncStatus.New.rawValue,
							NSNumber(unsignedLongLong: (f?.latestVisit?.date)! / 1000),
							f?.url
						]
						let insertSQL = "INSERT INTO \(TableBookmarksLocal) " +
							"(guid, type, bmkUri, title, parentid, parentName, local_modified, sync_status, bookmarked_date, faviconID) " +
							"VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, (SELECT iconID FROM \(ViewIconForURL) WHERE url = ?))"
						self.run(insertSQL, withArgs: args)
					}
				}
			}
		}
	}
	
	private func idFactory(row: SDRow) -> Int {
		return row[0] as! Int
	}

	private func isURLBookmarked(url: String?) -> Bool {
		guard let u = url else {
			return false
		}
		let urlArgs: Args = [
			u
		]
		let isBookmarkedURLSQL = "SELECT id FROM \(TableBookmarksLocal) WHERE bmkUri = ?"
		guard let v = self.runQuery(isBookmarkedURLSQL, args: urlArgs, factory: idFactory).value.successValue where
			v.asArray().count > 0  else {
				return false
		}
		return true
	}

}