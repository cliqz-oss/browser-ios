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
    
    public func getOldestVisitDate() -> Date? {
        var oldestVisitDate: Date?

        let visitsSQL = "SELECT MIN(\(TableVisits).date) AS date FROM \(TableVisits) "
        
        let resultSet = db.runQuery(visitsSQL, args: nil, factory: SQLiteHistory.dateFactory).value
        if let data = resultSet.successValue {
            oldestVisitDate = data[0]
        }
        return oldestVisitDate
    }
    
    public func removeHistory(_ ids: [Int]) -> Success {
        let idsCommaSeparated = ids.map{String($0)}.joined(separator: ",")

        return self.db.run([
            ("DELETE FROM \(TableVisits) WHERE id in (\(idsCommaSeparated))", nil),
            ("DELETE FROM \(TableHistory) WHERE id NOT IN (SELECT distinct(siteID) FROM \(TableVisits))", nil),
            ("DELETE FROM \(TableDomains) WHERE id NOT IN (SELECT (domain_id) FROM \(TableHistory))", nil),
            self.favicons.getCleanupCommands(),
            ])
    }
	
	// TODO: check if possible to use FF's version of getHistory
    public func getHistoryVisits(_ offset:Int, limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        let args: Args?
        args = []
		
        // Cliqz: Sort history ASC on date not DESC on id
        let historySQL =
        "SELECT \(TableVisits).id, \(TableVisits).date, \(TableHistory).url, \(TableHistory).title " +
            "FROM \(TableHistory) " +
            "INNER JOIN \(TableVisits) ON \(TableVisits).siteID = \(TableHistory).id " +
            "ORDER BY \(TableVisits).date DESC " +
        "LIMIT \(limit) OFFSET \(offset)"
        
        // TODO countFactory
        return db.runQuery(historySQL, args: args, factory: SQLiteHistory.historyVisitsFactory)
    }

	public func hideTopSite(_ url: String) -> Success {
		let insertSQL = "INSERT INTO \(TableHiddenTopSites) " +
			"(url) " +
			"VALUES (?)"
		let args: Args = [
			url as AnyObject?
		]
		return db.run(insertSQL, withArgs: args)
	}

	public func deleteAllHiddenTopSites() -> Success {
		return self.db.run([
			"DELETE FROM \(TableHiddenTopSites)"])
	}
    
    public func getHiddenTopSitesCount() -> Int {
        var count = 0
        let countSQL = "SELECT COUNT(\(TableHiddenTopSites).id) AS rowCount FROM \(TableHiddenTopSites) "
        
        let resultSet = db.runQuery(countSQL, args: nil, factory: SQLiteHistory.countFactory).value
        if let data = resultSet.successValue {
            if let d = data[0] {
                count = d
            }
        }
        return count
    }
    
    //MARK: - Factories
    fileprivate class func countFactory(_ row: SDRow) -> Int {
        let cout = row["rowCount"] as! Int
        return cout
    }
    
    fileprivate class func dateFactory(_ row: SDRow) -> Date {

        let timeInMicroSeconds = row.getTimestamp("date")
        let timeIntervalSince1970 = Double(timeInMicroSeconds! / 1000000)
        
        let date = Date(timeIntervalSince1970:timeIntervalSince1970)
        return date
    }
	
    internal class func historyVisitsFactory(_ row: SDRow) -> Site {
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
