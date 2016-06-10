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
		let r = alterTableWithExtraColumn(TableBookmarksLocal, columnName: "bookmarked_date")
		switch  (r.value) {
			case .Failure:
				let notificationCenter = NSNotificationCenter.defaultCenter()
				notificationCenter.addObserver(self, selector: #selector(BrowserDB.onDatabaseCreation(_:)), name: NotificationDatabaseWasCreated, object: nil)
			default:
				break
		}
	}

	private func alterTableWithExtraColumn(tableName: String, columnName: String) -> Success {
		if !isColumnExist(tableName, columnName: columnName) {
			
			return self.run([
				("ALTER TABLE \(tableName) ADD COLUMN \(columnName) INTEGER NOT NULL DEFAULT 0", nil)
				])
		}
		return succeed()
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
			self.alterTableWithExtraColumn(TableBookmarksLocal, columnName: "bookmarked_date")
			NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDatabaseWasCreated, object: nil)
		}
	}

}