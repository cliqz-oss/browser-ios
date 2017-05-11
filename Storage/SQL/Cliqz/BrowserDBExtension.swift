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

let TableHiddenTopSites = "hidden_top_sites"

extension BrowserDB {

	func extendTables() {
		createHiddenTopSitesTable()
		let columnName = "bookmarked_date"
		if !isColumnExist(TableBookmarksLocal, columnName: columnName) {
			let r = alterTableWithExtraColumn(TableBookmarksLocal, columnName: columnName)
			switch  (r.value) {
			case .failure:
				let notificationCenter = NotificationCenter.default
				notificationCenter.addObserver(self, selector: #selector(BrowserDB.onDatabaseCreation(_:)), name: NSNotification.Name(rawValue: NotificationDatabaseWasCreated), object: nil)
			default:
				migrateOldBookmarks()
			}
		}
	}
	
	fileprivate func createHiddenTopSitesTable() {
		let hiddenTopSitesTableCreate =
			"CREATE TABLE IF NOT EXISTS \(TableHiddenTopSites) (" +
				"id INTEGER PRIMARY KEY AUTOINCREMENT, " +
				"url TEXT UNIQUE " +
		")"
		self.run([hiddenTopSitesTableCreate])
	}

	fileprivate func alterTableWithExtraColumn(_ tableName: String, columnName: String) -> Success {
		return self.run([
				("ALTER TABLE \(tableName) ADD COLUMN \(columnName) INTEGER NOT NULL DEFAULT 0", nil)
				])
	}

	fileprivate func isColumnExist(_ tableName: String, columnName: String) -> Bool {
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
	
	fileprivate class func columnNameFactory(_ row: SDRow) -> String {
		let columnName = row["name"] as! String
		return columnName
	}

	@objc func onDatabaseCreation(_ notification: Notification) {
		DispatchQueue.main.async {
			self.extendBookmarksTable()
			NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationDatabaseWasCreated), object: nil)
		}
	}
	
	fileprivate func extendBookmarksTable() {
		self.alterTableWithExtraColumn(TableBookmarksLocal, columnName: "bookmarked_date")
		self.migrateOldBookmarks()
	}

	fileprivate func migrateOldBookmarks() {
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
							newGUID as AnyObject?,
							BookmarkNodeType.bookmark.rawValue as AnyObject?,
							f?.url as AnyObject?,
							f?.title as AnyObject?,
							BookmarkRoots.MobileFolderGUID as AnyObject?,
							BookmarksFolderTitleMobile as AnyObject?,
							NSNumber(value: (f?.latestVisit?.date)! / 1000),
							SyncStatus.new.rawValue as AnyObject?,
							NSNumber(value: (f?.latestVisit?.date)! / 1000),
							f?.url as AnyObject?
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
	
	fileprivate func idFactory(_ row: SDRow) -> Int {
		return row[0] as! Int
	}

	fileprivate func isURLBookmarked(_ url: String?) -> Bool {
		guard let u = url else {
			return false
		}
		let urlArgs: Args = [
			u as Optional<AnyObject>
		]
		let isBookmarkedURLSQL = "SELECT id FROM \(TableBookmarksLocal) WHERE bmkUri = ?"
		guard let v = self.runQuery(isBookmarkedURLSQL, args: urlArgs, factory: idFactory).value.successValue,
			v.asArray().count > 0  else {
				return false
		}
		return true
	}

}
