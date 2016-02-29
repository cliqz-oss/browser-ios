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
    
    public func setHistoryFavorite(ids: [Int], value: Bool) -> Success {
        let idsCommaSeparated = ids.map{String($0)}.joinWithSeparator(",")
        let favorite = value ? 1:0
        return self.db.run([
            ("UPDATE \(TableVisits) SET favorite = \(favorite) WHERE id in (\(idsCommaSeparated))", nil)
            ])
    }
    
    public func clearHistory(favorite: Int) -> Success {
        return self.db.run([
            ("DELETE FROM \(TableVisits) WHERE favorite = \(favorite)", nil),
            ("DELETE FROM \(TableHistory) WHERE id NOT IN (SELECT distinct(siteID) FROM \(TableVisits))", nil),
            ("DELETE FROM \(TableDomains) WHERE id NOT IN (SELECT (domain_id) FROM \(TableHistory))", nil),
            self.favicons.getCleanupCommands(),
            ])
            // We've probably deleted a lot of stuff. Vacuum now to recover the space.
            >>> effect(self.db.vacuum)
    }
    
    public func removeHistory(ids: [Int]) -> Success {
        let idsCommaSeparated = ids.map{String($0)}.joinWithSeparator(",")

        return self.db.run([
            ("DELETE FROM \(TableVisits) WHERE id in \(idsCommaSeparated)", nil),
            ("DELETE FROM \(TableHistory) WHERE id NOT IN (SELECT distinct(siteID) FROM \(TableVisits))", nil),
            ("DELETE FROM \(TableDomains) WHERE id NOT IN (SELECT (domain_id) FROM \(TableHistory))", nil),
            self.favicons.getCleanupCommands(),
            ])
    }
    
    public func getHistoryVisits(limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        let args: Args?
        args = []
        
        let historySQL =
        "SELECT \(TableVisits).id, \(TableVisits).date, \(TableVisits).favorite, \(TableHistory).url, \(TableHistory).title " +
            "FROM \(TableHistory) " +
            "INNER JOIN \(TableVisits) ON \(TableVisits).siteID = \(TableHistory).id " +
            "ORDER BY \(TableVisits).id DESC " +
        "LIMIT \(limit) "
        
        // TODO countFactory
        return db.runQuery(historySQL, args: args, factory: SQLiteHistory.historyVisitsFactory)
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
    
    //MARK: - Factories
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
    
    private class func historyVisitsFactory(row: SDRow) -> Site {
        let id = row["id"] as! Int
        let url = row["url"] as! String
        let title = row["title"] as! String
        let favorite = row["favorite"] as! Bool
        
        let site = Site(url: url, title: title)
        site.id = id
        site.favorite = favorite
        
        let date = row.getTimestamp("date") ?? 0
        site.latestVisit = Visit(date: date, type: VisitType.Unknown)
        
        return site
    }
    

}
