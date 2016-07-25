//
//  SQLiteHistoryExtension.swift
//  Client
//
//  Created by Mahmoud Adam on 11/18/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation
import Shared
import Deferred

extension SQLiteHistory: ExtendedBrowserHistory {
    
    public func count() -> Int {
        var count = 0
        self.getOldestVisitDate()
        let countSQL = "SELECT COUNT(\(TableHistory).id) AS rowCount FROM \(TableHistory) "
        
        let resultSet = db.runQuery(countSQL, args: nil, factory: SQLiteHistory.countFactory).value
        if let data = resultSet.successValue {
			if let d = data[0] {
				count = d
			}
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
    
    public func removeHistory(ids: [Int]) -> Success {
        let idsCommaSeparated = ids.map{String($0)}.joinWithSeparator(",")

        return self.db.run([
            ("DELETE FROM \(TableVisits) WHERE id in (\(idsCommaSeparated))", nil),
            ("DELETE FROM \(TableHistory) WHERE id NOT IN (SELECT distinct(siteID) FROM \(TableVisits))", nil),
            ("DELETE FROM \(TableDomains) WHERE id NOT IN (SELECT (domain_id) FROM \(TableHistory))", nil),
            self.favicons.getCleanupCommands(),
            ])
    }
	
	// TODO: check if possible to use FF's version of getHistory
    public func getHistoryVisits(limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        let args: Args?
        args = []
		
        let historySQL =
        "SELECT \(TableVisits).id, \(TableVisits).date, \(TableHistory).url, \(TableHistory).title " +
            "FROM \(TableHistory) " +
            "INNER JOIN \(TableVisits) ON \(TableVisits).siteID = \(TableHistory).id " +
            "ORDER BY \(TableVisits).id ASC " +
        "LIMIT \(limit) "
        
        // TODO countFactory
        return db.runQuery(historySQL, args: args, factory: SQLiteHistory.historyVisitsFactory)
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
	
    internal class func historyVisitsFactory(row: SDRow) -> Site {
        let id = row["id"] as! Int
        let url = row["url"] as! String
        let title = row["title"] as! String
		
        let site = Site(url: url, title: title)
        site.id = id
		
        let date = row.getTimestamp("date") ?? 0
        site.latestVisit = Visit(date: date, type: VisitType.Unknown)

        return site
    }
    

}
