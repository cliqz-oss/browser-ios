//
//  SQLiteHistoryExtension.swift
//  Client
//
//  Created by Mahmoud Adam on 11/18/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation
import Shared
extension SQLiteHistory: ExtendedBrowserHistory {
    
    public func count() -> Int {
        var count = 0
        self.getOldestVisitDate()
        let countSQL = "SELECT COUNT(\(TableHistory).id) AS rowCount FROM \(TableHistory) "
        
        let resultSet = db.runQuery(countSQL, args: nil, factory: SQLiteHistory.countFactory).value
        if let data = resultSet.successValue {
            count = data[0]!
        }
        return count
    }
    
    public func getOldestVisitDate() -> NSDate? {
        var oldestVisitDate: NSDate?
        
        let visitsSQL = "SELECT MIN(\(TableVisits).date) AS date FROM \(TableVisits) "
        
        let resultSet = db.runQuery(visitsSQL, args: nil, factory: SQLiteHistory.dateFactory).value
        if let data = resultSet.successValue {
            oldestVisitDate = data[0]
        }
        return oldestVisitDate
    }
    
    public func alterVisitsTableAddFavoriteColumn() {
        
        if !isColumnExist(TableVisits, columnName: "favorite") {
            self.db.run([
                ("ALTER TABLE \(TableVisits) ADD COLUMN 'favorite' BOOL NOT NULL DEFAULT 0", nil)
                ])
        }
    }
    
    //MARK: - Helper Methods
    private func isColumnExist(tableName: String, columnName: String) -> Bool {
        let tableInfoSQL = "PRAGMA table_info(\(tableName))"
        
        let result = db.runQuery(tableInfoSQL, args: nil, factory: SQLiteHistory.columnNameFactory).value
        if let columnNames = result.successValue {
            for tableColumnName in columnNames {
                if tableColumnName == columnName {
                    return true
                }
            }
        }
        return false
    }
    
    //MARK - Factories
    private class func countFactory(row: SDRow) -> Int {
        let cout = row["rowCount"] as! Int
        return cout
    }
    private class func dateFactory(row: SDRow) -> NSDate {
        
        let timeInMicroSeconds = row.getTimestamp("date")
        let timeIntervalSince1970 = Double(timeInMicroSeconds! / 1000000)
        
        let date = NSDate(timeIntervalSince1970:timeIntervalSince1970)
        return date
    }
    private class func columnNameFactory(row: SDRow) -> String {
        let columnName = row["name"] as! String
        return columnName
    }
}
