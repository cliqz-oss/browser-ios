/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

private let log = Logger.syncLogger

class NoSuchRecordError: MaybeErrorType {
    let guid: GUID
    init(guid: GUID) {
        self.guid = guid
    }
    var description: String {
        return "No such record: \(guid)."
    }
}

func failOrSucceed<T>(_ err: NSError?, op: String, val: T) -> Deferred<Maybe<T>> {
    if let err = err {
        log.debug("\(op) failed: \(err.localizedDescription)")
        return deferMaybe(DatabaseError(err: err))
    }

    return deferMaybe(val)
}

func failOrSucceed(_ err: NSError?, op: String) -> Success {
    return failOrSucceed(err, op: op, val: ())
}

private var ignoredSchemes = ["about"]

public func isIgnoredURL(_ url: URL) -> Bool {
    let scheme = url.scheme
    if let _ = ignoredSchemes.index(of: scheme!) {
        return true
    }

    if url.host == "localhost" {
        return true
    }

    return false
}

public func isIgnoredURL(_ url: String) -> Bool {
    if let url = URL(string: url) {
        return isIgnoredURL(url)
    }

    return false
}

/*
// Here's the Swift equivalent of the below.
func simulatedFrecency(now: MicrosecondTimestamp, then: MicrosecondTimestamp, visitCount: Int) -> Double {
    let ageMicroseconds = (now - then)
    let ageDays = Double(ageMicroseconds) / 86400000000.0         // In SQL the .0 does the coercion.
    let f = 100 * 225 / ((ageSeconds * ageSeconds) + 225)
    return Double(visitCount) * max(1.0, f)
}
*/

// The constants in these functions were arrived at by utterly unscientific experimentation.

func getRemoteFrecencySQL() -> String {
    let visitCountExpression = "remoteVisitCount"
    let now = Date.nowMicroseconds()
    let microsecondsPerDay = 86_400_000_000.0      // 1000 * 1000 * 60 * 60 * 24
    let ageDays = "((\(now) - remoteVisitDate) / \(microsecondsPerDay))"

    return "\(visitCountExpression) * max(1, 100 * 110 / (\(ageDays) * \(ageDays) + 110))"
}

func getLocalFrecencySQL() -> String {
    let visitCountExpression = "((2 + localVisitCount) * (2 + localVisitCount))"
    let now = Date.nowMicroseconds()
    let microsecondsPerDay = 86_400_000_000.0      // 1000 * 1000 * 60 * 60 * 24
    let ageDays = "((\(now) - localVisitDate) / \(microsecondsPerDay))"

    return "\(visitCountExpression) * max(2, 100 * 225 / (\(ageDays) * \(ageDays) + 225))"
}

extension SDRow {
    func getTimestamp(_ column: String) -> Timestamp? {
        return (self[column] as? NSNumber)?.uint64Value
    }

    func getBoolean(_ column: String) -> Bool {
        if let val = self[column] as? Int {
            return val != 0
        }
        return false
    }
}

/**
 * The sqlite-backed implementation of the history protocol.
 */
open class SQLiteHistory {
    let db: BrowserDB
    let favicons: FaviconsTable<Favicon>
    let prefs: Prefs

    required public init(db: BrowserDB, prefs: Prefs) {
        self.db = db
        self.favicons = FaviconsTable<Favicon>()
        self.prefs = prefs

        // BrowserTable exists only to perform create/update etc. operations -- it's not
        // a queryable thing that needs to stick around.
        switch db.createOrUpdate(BrowserTable()) {
        case .failure:
            log.error("Failed to create/update the scheme table. Aborting.")
            fatalError()
        case .closed:
            log.info("Database not created as the SQLiteConnection is closed.")
        case .success:
            log.debug("Database succesfully created/updated")
        }
    }
}

private let topSitesQuery = "SELECT * FROM \(TableCachedTopSites) ORDER BY frecencies DESC LIMIT (?)"

extension SQLiteHistory: BrowserHistory {
    public func removeSiteFromTopSites(_ site: Site) -> Success {
        if let host = site.url.asURL?.normalizedHost() {
            return db.run([("UPDATE \(TableDomains) set showOnTopSites = 0 WHERE domain = ?", [host] as Args)])
                >>> { return self.refreshTopSitesCache() }
        }
        return deferMaybe(DatabaseError(description: "Invalid url for site \(site.url)"))
    }

    public func removeHistoryForURL(_ url: String) -> Success {
        let visitArgs: Args = [url]
        let deleteVisits = "DELETE FROM \(TableVisits) WHERE siteID = (SELECT id FROM \(TableHistory) WHERE url = ?)"

        let markArgs: Args = [Date.nowNumber(), url]
        let markDeleted = "UPDATE \(TableHistory) SET url = NULL, is_deleted = 1, should_upload = 1, local_modified = ? WHERE url = ?"

        return db.run([(deleteVisits, visitArgs),
                       (markDeleted, markArgs),
                       favicons.getCleanupCommands()])
    }

    // Note: clearing history isn't really a sane concept in the presence of Sync.
    // This method should be split to do something else.
    // Bug 1162778.
    public func clearHistory() -> Success {
        return self.db.run([
            ("DELETE FROM \(TableVisits)", nil),
            ("DELETE FROM \(TableHistory)", nil),
            ("DELETE FROM \(TableDomains)", nil),
            self.favicons.getCleanupCommands(),
            ])
            // We've probably deleted a lot of stuff. Vacuum now to recover the space.
            >>> effect(self.db.vacuum)
    }

    func recordVisitedSite(_ site: Site) -> Success {
        var error: NSError? = nil

        // Don't store visits to sites with about: protocols
        if isIgnoredURL(site.url) {
            return deferMaybe(IgnoredSiteError())
        }

        db.withWritableConnection(&error) { (conn, err: inout NSError?) -> Int in
            let now = Date.nowNumber()

            let i = self.updateSite(site, atTime: now, withConnection: conn)
            if i > 0 {
                return i
            }

            // Insert instead.
            return self.insertSite(site, atTime: now, withConnection: conn)
        }

        return failOrSucceed(error, op: "Record site")
    }

    func updateSite(_ site: Site, atTime time: NSNumber, withConnection conn: SQLiteDBConnection) -> Int {
        // We know we're adding a new visit, so we'll need to upload this record.
        // If we ever switch to per-visit change flags, this should turn into a CASE statement like
        //   CASE WHEN title IS ? THEN max(should_upload, 1) ELSE should_upload END
        // so that we don't flag this as changed unless the title changed.
        //
        // Note that we will never match against a deleted item, because deleted items have no URL,
        // so we don't need to unset is_deleted here.
        if let host = site.url.asURL?.normalizedHost() {
            let update = "UPDATE \(TableHistory) SET title = ?, local_modified = ?, should_upload = 1, domain_id = (SELECT id FROM \(TableDomains) where domain = ?) WHERE url = ?"
            let updateArgs: Args? = [site.title, time, host, site.url]
            if Logger.logPII {
                log.debug("Setting title to \(site.title) for URL \(site.url)")
            }
            let error = conn.executeChange(update, withArgs: updateArgs)
            if error != nil {
                log.warning("Update failed with \(error?.localizedDescription)")
                return 0
            }
            return conn.numberOfRowsModified
        }
        return 0
    }

    fileprivate func insertSite(_ site: Site, atTime time: NSNumber, withConnection conn: SQLiteDBConnection) -> Int {

        if let host = site.url.asURL?.normalizedHost() {
            if let error = conn.executeChange("INSERT OR IGNORE INTO \(TableDomains) (domain) VALUES (?)", withArgs: [host]) {
                log.warning("Domain insertion failed with \(error.localizedDescription)")
                return 0
            }

            let insert = "INSERT INTO \(TableHistory) " +
                         "(guid, url, title, local_modified, is_deleted, should_upload, domain_id) " +
                         "SELECT ?, ?, ?, ?, 0, 1, id FROM \(TableDomains) WHERE domain = ?"
            let insertArgs: Args? = [site.guid ?? Bytes.generateGUID(), site.url, site.title, time, host]
            if let error = conn.executeChange(insert, withArgs: insertArgs) {
                log.warning("Site insertion failed with \(error.localizedDescription)")
                return 0
            }

            return 1
        }

        if Logger.logPII {
            log.warning("Invalid URL \(site.url). Not stored in history.")
        }
        return 0
    }

    // TODO: thread siteID into this to avoid the need to do the lookup.
    func addLocalVisitForExistingSite(_ visit: SiteVisit) -> Success {
        var error: NSError? = nil
        db.withWritableConnection(&error) { (conn, err: inout NSError?) -> Int in
            // INSERT OR IGNORE because we *might* have a clock error that causes a timestamp
            // collision with an existing visit, and it would really suck to error out for that reason.
            let insert = "INSERT OR IGNORE INTO \(TableVisits) (siteID, date, type, is_local) VALUES (" +
                         "(SELECT id FROM \(TableHistory) WHERE url = ?), ?, ?, 1)"
            let realDate = NSNumber(value: visit.date)
            let insertArgs: Args? = [visit.site.url, realDate, visit.type.rawValue]
            error = conn.executeChange(insert, withArgs: insertArgs)
            if error != nil {
//                log.warning("Visit insertion failed with \(err?.localizedDescription)")
                return 0
            }
            return 1
        }

        return failOrSucceed(error, op: "Record visit")
    }

    public func addLocalVisit(_ visit: SiteVisit) -> Success {
        return recordVisitedSite(visit.site)
         >>> { self.addLocalVisitForExistingSite(visit) }
    }

    public func getSitesByFrecencyWithHistoryLimit(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        return self.getSitesByFrecencyWithHistoryLimit(limit, includeIcon: true)
    }

    public func getSitesByFrecencyWithHistoryLimit(_ limit: Int, includeIcon: Bool) -> Deferred<Maybe<Cursor<Site>>> {
        // Exclude redirect domains. Bug 1194852.
        let (whereData, groupBy) = self.topSiteClauses()
        return self.getFilteredSitesByFrecencyWithHistoryLimit(limit, bookmarksLimit: 0, groupClause: groupBy, whereData: whereData, includeIcon: includeIcon)
    }

    public func getTopSitesWithLimit(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        // Cliqz: Used Cliqz customized query to get top sites instead of the regular Fire Fox one
        let topSitesQuery = "select mzh.id as historyID, mzh.guid as guid, mzh.url as url, mzh.title as title, sum(mzh.days_count) as total_count, count(id) as visit_count " +  
                                    "from ( " +
                                        "select \(TableHistory).id , \(TableHistory).guid, \(TableHistory).url, \(TableHistory).title, \(TableVisits).siteID, " +
                                                "(\(TableVisits).date /(86400* 1000000) - (strftime('%s', date('now', '-6 months'))/86400) ) as days_count, " +
                                                "MAX(\(TableHistory).local_modified, ifnull(\(TableHistory).server_modified,0)) as last_visit_date " +
                                        "from \(TableVisits), \(TableHistory) " +
                                        "where \(TableVisits).date > (strftime('%s', date('now', '-6 months'))*1000000) " +
												"and \(TableHistory).url NOT IN (SELECT url FROM \(TableHiddenTopSites)) " +
                                                "and \(TableHistory).url NOT LIKE 'query:%' " + 
                                                "and \(TableVisits).siteID == \(TableHistory).id " +
                                                "and \(TableHistory).is_deleted == 0 " +
                                                "and (\(TableVisits).type < 4  or \(TableVisits).type == 6)" +
                                    ") as mzh " +
                            "group by mzh.siteID " +
							// Cliqz: Changed next 2 lines to fix top sites logic
                            "having visit_count > 2 " +
                            "order by total_count desc,visit_count desc, mzh.last_visit_date desc " +
                            "limit (?)"
        
        return self.db.runQuery(topSitesQuery, args: [limit], factory: SQLiteHistory.iconHistoryColumnFactory)
    }

    public func setTopSitesNeedsInvalidation() {
        prefs.setBool(false, forKey: PrefsKeys.KeyTopSitesCacheIsValid)
    }

    public func updateTopSitesCacheIfInvalidated() -> Deferred<Maybe<Bool>> {
        if prefs.boolForKey(PrefsKeys.KeyTopSitesCacheIsValid) ?? false {
            return deferMaybe(false)
        }
        
        return refreshTopSitesCache() >>> always(true)
    }

    public func setTopSitesCacheSize(_ size: Int32) {
        let oldValue = prefs.intForKey(PrefsKeys.KeyTopSitesCacheSize) ?? 0
        if oldValue != size {
            prefs.setInt(size, forKey: PrefsKeys.KeyTopSitesCacheSize)
            setTopSitesNeedsInvalidation()
        }
    }

    public func refreshTopSitesCache() -> Success {
        let cacheSize = Int(prefs.intForKey(PrefsKeys.KeyTopSitesCacheSize) ?? 0)
        return updateTopSitesCacheWithLimit(cacheSize)
    }

    public func areTopSitesDirty(withLimit limit: Int) -> Deferred<Maybe<Bool>> {
        let (whereData, groupBy) = self.topSiteClauses()
        let (query, args) = self.filteredSitesByFrecencyQueryWithHistoryLimit(limit, bookmarksLimit: 0, groupClause: groupBy, whereData: whereData)
        let cacheArgs: Args = [limit]

        return accumulate([
            { self.db.runQuery(query, args: args, factory: SQLiteHistory.iconHistoryColumnFactory) },
            { self.db.runQuery(topSitesQuery, args: cacheArgs, factory: SQLiteHistory.iconHistoryColumnFactory) }
        ]).bind { results in
            guard let results = results.successValue else {
                // Something weird happened - default to dirty.
                return deferMaybe(true)
            }

            let frecencyResults = results[0]
            let cacheResults = results[1]

            // Counts don't match? Exit early and say we're dirty.
            if frecencyResults.count != cacheResults.count {
                return deferMaybe(true)
            }

            var isDirty = false
            // Check step-wise that the ordering and entries are the same
            (0..<frecencyResults.count).forEach { index in
                guard let frecencyID = frecencyResults[index]?.id,
                      let cacheID = cacheResults[index]?.id, frecencyID == cacheID else {
                    // It only takes one difference to make everything dirty
                    isDirty = true
                    return
                }
            }

            return deferMaybe(isDirty)
        }
    }

    fileprivate func updateTopSitesCacheWithLimit(_ limit : Int) -> Success {
        let (whereData, groupBy) = self.topSiteClauses()
        let (query, args) = self.filteredSitesByFrecencyQueryWithHistoryLimit(limit, bookmarksLimit: 0, groupClause: groupBy, whereData: whereData)

        // We must project, because we get bookmarks in these results.
        let insertQuery = [
            "INSERT INTO \(TableCachedTopSites)",
            "SELECT historyID, url, title, guid, domain_id, domain,",
            "localVisitDate, remoteVisitDate, localVisitCount, remoteVisitCount,",
            "iconID, iconURL, iconDate, iconType, iconWidth, frecencies",
            "FROM (", query, ")"
        ].joined(separator: " ")

        return (self.clearTopSitesCache() >>> {
            return self.db.run(insertQuery, withArgs: args)
        }) >>> {
            self.prefs.setBool(true, forKey: PrefsKeys.KeyTopSitesCacheIsValid)
            return succeed()
        }
    }

    public func clearTopSitesCache() -> Success {
        let deleteQuery = "DELETE FROM \(TableCachedTopSites)"
        return self.db.run(deleteQuery, withArgs: nil) >>> {
            self.prefs.removeObjectForKey(PrefsKeys.KeyTopSitesCacheIsValid)
            return succeed()
        }
    }

    public func getSitesByFrecencyWithHistoryLimit(_ limit: Int, bookmarksLimit: Int, whereURLContains filter: String) -> Deferred<Maybe<Cursor<Site>>> {
        return self.getFilteredSitesByFrecencyWithHistoryLimit(limit, bookmarksLimit: bookmarksLimit, whereURLContains: filter, includeIcon: true)
    }

    public func getSitesByFrecencyWithHistoryLimit(_ limit: Int, whereURLContains filter: String) -> Deferred<Maybe<Cursor<Site>>> {
        return self.getFilteredSitesByFrecencyWithHistoryLimit(limit, bookmarksLimit: 0, whereURLContains: filter, includeIcon: true)
    }

    public func getSitesByLastVisit(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        return self.getFilteredSitesByVisitDateWithLimit(limit, whereURLContains: nil, includeIcon: true)
    }

    fileprivate class func basicHistoryColumnFactory(_ row: SDRow) -> Site {
        let id = row["historyID"] as! Int
        let url = row["url"] as! String
        let title = row["title"] as! String
        let guid = row["guid"] as! String

        // Extract a boolean from the row if it's present.
        let iB = row["is_bookmarked"] as? Int
        let isBookmarked: Bool? = (iB == nil) ? nil : (iB! != 0)

        let site = Site(url: url, title: title, bookmarked: isBookmarked)
        site.guid = guid
        site.id = id

        // Find the most recent visit, regardless of which column it might be in.
        let local = row.getTimestamp("localVisitDate") ?? 0
        let remote = row.getTimestamp("remoteVisitDate") ?? 0
        let either = row.getTimestamp("visitDate") ?? 0

        let latest = max(local, remote, either)
        if latest > 0 {
            site.latestVisit = Visit(date: latest, type: VisitType.Unknown)
        }

        return site
    }

    fileprivate class func iconColumnFactory(_ row: SDRow) -> Favicon? {
        if let iconType = row["iconType"] as? Int,
            let iconURL = row["iconURL"] as? String,
            let iconDate = row["iconDate"] as? Double,
            let _ = row["iconID"] as? Int {
                let date = Date(timeIntervalSince1970: iconDate)
                return Favicon(url: iconURL, date: date, type: IconType(rawValue: iconType)!)
        }
        return nil
    }

    fileprivate class func iconHistoryColumnFactory(_ row: SDRow) -> Site {
        let site = basicHistoryColumnFactory(row)
        site.icon = iconColumnFactory(row)
        return site
    }

    fileprivate func topSiteClauses() -> (String, String) {
        let whereData = "(\(TableDomains).showOnTopSites IS 1) AND (\(TableDomains).domain NOT LIKE 'r.%') "
        let groupBy = "GROUP BY domain_id "
        return (whereData, groupBy)
    }

    fileprivate func computeWordsWithFilter(_ filter: String) -> [String] {
        // Split filter on whitespace.
        let words = filter.components(separatedBy: CharacterSet.whitespaces)

        // Remove substrings and duplicates.
        // TODO: this can probably be improved.
        return words.enumerated().filter({ (index: Int, word: String) in
            if word.isEmpty {
                return false
            }

            for i in words.indices where i != index {
                if words[i].range(of: word) != nil && (words[i].characters.count != word.characters.count || i < index) {
                    return false
                }
            }

            return true
        }).map({ $0.1 })
    }

    /**
     * Take input like "foo bar" and a template fragment and produce output like
     *
     *   ((x.y LIKE ?) OR (x.z LIKE ?)) AND ((x.y LIKE ?) OR (x.z LIKE ?))
     *
     * with args ["foo", "foo", "bar", "bar"].
     */
    internal func computeWhereFragmentWithFilter(_ filter: String, perWordFragment: String, perWordArgs: (String) -> Args) -> (fragment: String, args: Args) {
        precondition(!filter.isEmpty)

        let words = computeWordsWithFilter(filter)
        return self.computeWhereFragmentForWords(words, perWordFragment: perWordFragment, perWordArgs: perWordArgs)
    }

    internal func computeWhereFragmentForWords(_ words: [String], perWordFragment: String, perWordArgs: (String) -> Args) -> (fragment: String, args: Args) {
        assert(!words.isEmpty)

        let fragment = Array(repeating: perWordFragment, count: words.count).joined(separator: " AND ")
        let args = words.flatMap(perWordArgs)
        return (fragment, args)
    }

    fileprivate func getFilteredSitesByVisitDateWithLimit(_ limit: Int,
                                                      whereURLContains filter: String? = nil,
                                                      includeIcon: Bool = true) -> Deferred<Maybe<Cursor<Site>>> {
        let args: Args?
        let whereClause: String
        if let filter = filter?.trimmingCharacters(in: CharacterSet.whitespaces), !filter.isEmpty {
            let perWordFragment = "((\(TableHistory).url LIKE ?) OR (\(TableHistory).title LIKE ?))"
            let perWordArgs: (String) -> Args = { ["%\($0)%" as Optional<AnyObject>, "%\($0)%" as Optional<AnyObject>] }
            let (filterFragment, filterArgs) = computeWhereFragmentWithFilter(filter, perWordFragment: perWordFragment, perWordArgs: perWordArgs)

            // No deleted item has a URL, so there is no need to explicitly add that here.
            whereClause = "WHERE (\(filterFragment))"
            args = filterArgs
        } else {
            whereClause = "WHERE (\(TableHistory).is_deleted = 0)"
            args = []
        }

        let ungroupedSQL = [
        "SELECT \(TableHistory).id AS historyID, \(TableHistory).url AS url, title, guid, domain_id, domain,",
        "COALESCE(max(case \(TableVisits).is_local when 1 then \(TableVisits).date else 0 end), 0) AS localVisitDate,",
        "COALESCE(max(case \(TableVisits).is_local when 0 then \(TableVisits).date else 0 end), 0) AS remoteVisitDate,",
        "COALESCE(count(\(TableVisits).is_local), 0) AS visitCount",
        "FROM \(TableHistory)",
        "INNER JOIN \(TableDomains) ON \(TableDomains).id = \(TableHistory).domain_id",
        "INNER JOIN \(TableVisits) ON \(TableVisits).siteID = \(TableHistory).id",
        whereClause,
        "GROUP BY historyID",
        ].joined(separator: " ")

        let historySQL = [
        "SELECT historyID, url, title, guid, domain_id, domain, visitCount,",
        "max(localVisitDate) AS localVisitDate,",
        "max(remoteVisitDate) AS remoteVisitDate",
        "FROM (", ungroupedSQL, ")",
        "WHERE (visitCount > 0)",    // Eliminate dead rows from coalescing.
        "GROUP BY historyID",
        "ORDER BY max(localVisitDate, remoteVisitDate) DESC",
        "LIMIT \(limit)",
        ].joined(separator: " ")

        if includeIcon {
            // We select the history items then immediately join to get the largest icon.
            // We do this so that we limit and filter *before* joining against icons.
            let sql = [
            "SELECT",
            "historyID, url, title, guid, domain_id, domain,",
            "localVisitDate, remoteVisitDate, visitCount, ",
            "iconID, iconURL, iconDate, iconType, iconWidth ",
            "FROM (", historySQL, ") LEFT OUTER JOIN ",
            "view_history_id_favicon ON historyID = view_history_id_favicon.id",
            ].joined(separator: " ")
            let factory = SQLiteHistory.iconHistoryColumnFactory
            return db.runQuery(sql, args: args, factory: factory)
        }

        let factory = SQLiteHistory.basicHistoryColumnFactory
        return db.runQuery(historySQL, args: args, factory: factory)
    }

    fileprivate func getFilteredSitesByFrecencyWithHistoryLimit(_ limit: Int,
                                                            bookmarksLimit: Int,
                                                            whereURLContains filter: String? = nil,
                                                            groupClause: String = "GROUP BY historyID ",
                                                            whereData: String? = nil,
                                                            includeIcon: Bool = true) -> Deferred<Maybe<Cursor<Site>>> {
        let factory: (SDRow) -> Site
        if includeIcon {
            factory = SQLiteHistory.iconHistoryColumnFactory
        } else {
            factory = SQLiteHistory.basicHistoryColumnFactory
        }

        let (query, args) = filteredSitesByFrecencyQueryWithHistoryLimit(
            limit,
            bookmarksLimit: bookmarksLimit,
            whereURLContains: filter,
            groupClause: groupClause,
            whereData: whereData,
            includeIcon: includeIcon
        )

        return db.runQuery(query, args: args, factory: factory)
    }

    fileprivate func filteredSitesByFrecencyQueryWithHistoryLimit(_ historyLimit: Int,
                                                              bookmarksLimit: Int,
                                                              whereURLContains filter: String? = nil,
                                                              groupClause: String = "GROUP BY historyID ",
                                                              whereData: String? = nil,
                                                              includeIcon: Bool = true) -> (String, Args?) {
        let includeBookmarks = bookmarksLimit > 0
        let localFrecencySQL = getLocalFrecencySQL()
        let remoteFrecencySQL = getRemoteFrecencySQL()
        let sixMonthsInMicroseconds: UInt64 = 15_724_800_000_000      // 182 * 1000 * 1000 * 60 * 60 * 24
        let sixMonthsAgo = Date.nowMicroseconds() - sixMonthsInMicroseconds

        let args: Args
        let whereClause: String
        let whereFragment = (whereData == nil) ? "" : " AND (\(whereData!))"

        if let filter = filter?.trimmingCharacters(in: CharacterSet.whitespaces), !filter.isEmpty {
            let perWordFragment = "((url LIKE ?) OR (title LIKE ?))"
            let perWordArgs: (String) -> Args = { ["%\($0)%" as Optional<AnyObject>, "%\($0)%" as Optional<AnyObject>] }
            let (filterFragment, filterArgs) = computeWhereFragmentWithFilter(filter, perWordFragment: perWordFragment, perWordArgs: perWordArgs)
            // Cliqz: Exclude queries records when searching for history of specific query
            let whereQuery = "url NOT LIKE 'query:%'"
            
            // No deleted item has a URL, so there is no need to explicitly add that here.
            whereClause = "WHERE (\(filterFragment))\(whereFragment) AND (\(whereQuery))"

            if includeBookmarks {
                // We'll need them twice: once to filter history, and once to filter bookmarks.
                args = filterArgs + filterArgs
            } else {
                args = filterArgs
            }
        } else {
            whereClause = " WHERE (\(TableHistory).is_deleted = 0)\(whereFragment)"
            args = []
        }

        // Innermost: grab history items and basic visit/domain metadata.
        var ungroupedSQL =
        "SELECT \(TableHistory).id AS historyID, \(TableHistory).url AS url, \(TableHistory).title AS title, \(TableHistory).guid AS guid, domain_id, domain" +
        ", COALESCE(max(case \(TableVisits).is_local when 1 then \(TableVisits).date else 0 end), 0) AS localVisitDate" +
        ", COALESCE(max(case \(TableVisits).is_local when 0 then \(TableVisits).date else 0 end), 0) AS remoteVisitDate" +
        ", COALESCE(sum(\(TableVisits).is_local), 0) AS localVisitCount" +
        ", COALESCE(sum(case \(TableVisits).is_local when 1 then 0 else 1 end), 0) AS remoteVisitCount" +
        " FROM \(TableHistory) " +
        "INNER JOIN \(TableDomains) ON \(TableDomains).id = \(TableHistory).domain_id " +
        "INNER JOIN \(TableVisits) ON \(TableVisits).siteID = \(TableHistory).id "

        if includeBookmarks && AppConstants.MOZ_AWESOMEBAR_DUPES {
            ungroupedSQL.append("LEFT JOIN \(ViewAllBookmarks) on \(ViewAllBookmarks).url = \(TableHistory).url ")
        }
        ungroupedSQL.append(whereClause.replacingOccurrences(of: "url", with: "\(TableHistory).url").replacingOccurrences(of: "title", with: "\(TableHistory).title"))
        if includeBookmarks && AppConstants.MOZ_AWESOMEBAR_DUPES {
            ungroupedSQL.append(" AND \(ViewAllBookmarks).url IS NULL")
        }
        ungroupedSQL.append(" GROUP BY historyID")

        // Next: limit to only those that have been visited at all within the last six months.
        // (Don't do that in the innermost: we want to get the full count, even if some visits are older.)
        // Discard all but the 1000 most frecent.
        // Compute and return the frecency for all 1000 URLs.
        let frecenciedSQL =
        "SELECT *, (\(localFrecencySQL) + \(remoteFrecencySQL)) AS frecency" +
        " FROM (" + ungroupedSQL + ")" +
        " WHERE (" +
        "((localVisitCount > 0) OR (remoteVisitCount > 0)) AND " +                         // Eliminate dead rows from coalescing.
        "((localVisitDate > \(sixMonthsAgo)) OR (remoteVisitDate > \(sixMonthsAgo)))" +    // Exclude really old items.
        ") ORDER BY frecency DESC" +
        " LIMIT 1000"                                 // Don't even look at a huge set. This avoids work.
        
        // Next: merge by domain and sum frecency, ordering by that sum and reducing to a (typically much lower) limit.
        // TODO: make is_bookmarked here accurate by joining against ViewAllBookmarks.
        // TODO: ensure that the same URL doesn't appear twice in the list, either from duplicate
        //       bookmarks or from being in both bookmarks and history.
        let historySQL = [
            "SELECT historyID, url, title, guid, domain_id, domain,",
            "max(localVisitDate) AS localVisitDate,",
            "max(remoteVisitDate) AS remoteVisitDate,",
            "sum(localVisitCount) AS localVisitCount,",
            "sum(remoteVisitCount) AS remoteVisitCount,",
            "sum(frecency) AS frecencies,",
            "0 AS is_bookmarked",
            "FROM (", frecenciedSQL, ") ",
            groupClause,
            "ORDER BY frecencies DESC",
            "LIMIT \(historyLimit)",
        ].joined(separator: " ")

        if includeIcon {
            // We select the history items then immediately join to get the largest icon.
            // We do this so that we limit and filter *before* joining against icons.
            let historyWithIconsSQL = [
                "SELECT historyID, url, title, guid, domain_id, domain,",
                "localVisitDate, remoteVisitDate, localVisitCount, remoteVisitCount,",
                "iconID, iconURL, iconDate, iconType, iconWidth, frecencies, is_bookmarked",
                "FROM (", historySQL, ") LEFT OUTER JOIN",
                "view_history_id_favicon ON historyID = view_history_id_favicon.id",
                "ORDER BY frecencies DESC",
            ].joined(separator: " ")

            if !includeBookmarks {
                return (historyWithIconsSQL, args)
            }

            // Find bookmarks, too.
            // This isn't required by the protocol we're implementing, but we're able to do
            // it because we share storage with bookmarks.
            // Note that this is part-duplicated below.
            let bookmarksWithIconsSQL = [
                "SELECT NULL AS historyID, url, title, guid, NULL AS domain_id, NULL AS domain,",
                "visitDate AS localVisitDate, 0 AS remoteVisitDate, 0 AS localVisitCount,",
                "0 AS remoteVisitCount,",
                "iconID, iconURL, iconDate, iconType, iconWidth,",
                "visitDate AS frecencies,",  // Fake this for ordering purposes.
                "1 AS is_bookmarked",
                "FROM", ViewAwesomebarBookmarksWithIcons,
                whereClause,                  // The columns match, so we can reuse this.
                AppConstants.MOZ_AWESOMEBAR_DUPES ? "GROUP BY url" : "",
                "ORDER BY visitDate DESC LIMIT \(bookmarksLimit)",
            ].joined(separator: " ")

            let sql =
            "SELECT * FROM (SELECT * FROM (\(historyWithIconsSQL)) UNION SELECT * FROM (\(bookmarksWithIconsSQL))) ORDER BY is_bookmarked DESC, frecencies DESC"
            return (sql, args)
        }

        if !includeBookmarks {
            return (historySQL, args)
        }

        // Note that this is part-duplicated above.
        let bookmarksSQL = [
            "SELECT NULL AS historyID, url, title, guid, NULL AS domain_id, NULL AS domain,",
            "visitDate AS localVisitDate, 0 AS remoteVisitDate, 0 AS localVisitCount,",
            "0 AS remoteVisitCount,",
            "visitDate AS frecencies,",  // Fake this for ordering purposes.
            "1 AS is_bookmarked",
            "FROM", ViewAwesomebarBookmarks,
            whereClause,                  // The columns match, so we can reuse this.
            "GROUP BY url",
            "ORDER BY visitDate DESC LIMIT \(bookmarksLimit)",
        ].joined(separator: " ")

        let allSQL = "SELECT * FROM (SELECT * FROM (\(historySQL)) UNION SELECT * FROM (\(bookmarksSQL))) ORDER BY is_bookmarked DESC, frecencies DESC"
        return (allSQL, args)
    }
}

extension SQLiteHistory: Favicons {
    // These two getter functions are only exposed for testing purposes (and aren't part of the public interface).
    func getFaviconsForURL(_ url: String) -> Deferred<Maybe<Cursor<Favicon?>>> {
        let sql = "SELECT iconID AS id, iconURL AS url, iconDate AS date, iconType AS type, iconWidth AS width FROM " +
            "\(ViewWidestFaviconsForSites), \(TableHistory) WHERE " +
            "\(TableHistory).id = siteID AND \(TableHistory).url = ?"
        let args: Args = [url]
        return db.runQuery(sql, args: args, factory: SQLiteHistory.iconColumnFactory)
    }

    func getFaviconsForBookmarkedURL(_ url: String) -> Deferred<Maybe<Cursor<Favicon?>>> {
        let sql =
        "SELECT " +
        "  \(TableFavicons).id AS id" +
        ", \(TableFavicons).url AS url" +
        ", \(TableFavicons).date AS date" +
        ", \(TableFavicons).type AS type" +
        ", \(TableFavicons).width AS width" +
        " FROM \(TableFavicons), \(ViewBookmarksLocalOnMirror) AS bm" +
        " WHERE bm.faviconID = \(TableFavicons).id AND bm.bmkUri IS ?"
        let args: Args = [url]
        return db.runQuery(sql, args: args, factory: SQLiteHistory.iconColumnFactory)
    }
    
    public func getSitesForURLs(_ urls: [String]) -> Deferred<Maybe<Cursor<Site?>>> {
        let inExpression = urls.joined(separator: "\",\"")
        let sql = "SELECT \(TableHistory).id AS historyID, \(TableHistory).url AS url, title, guid, iconID, iconURL, iconDate, iconType, iconWidth FROM " +
            "\(ViewWidestFaviconsForSites), \(TableHistory) WHERE " +
            "\(TableHistory).id = siteID AND \(TableHistory).url IN (\"\(inExpression)\")"
        let args: Args = []
        return db.runQuery(sql, args: args, factory: SQLiteHistory.iconHistoryColumnFactory)
    }

    public func clearAllFavicons() -> Success {
        var err: NSError? = nil

        db.withWritableConnection(&err) { (conn, err: inout NSError?) -> Int in
            err = conn.executeChange("DELETE FROM \(TableFaviconSites)", withArgs: nil)
            if err == nil {
                err = conn.executeChange("DELETE FROM \(TableFavicons)", withArgs: nil)
            }
            return 1
        }

        return failOrSucceed(err, op: "Clear favicons")
    }

    public func addFavicon(_ icon: Favicon) -> Deferred<Maybe<Int>> {
        var err: NSError?
        let res = db.withWritableConnection(&err) { (conn, err: inout NSError?) -> Int in
            // Blind! We don't see failure here.
            let id = self.favicons.insertOrUpdate(conn, obj: icon)
            return id ?? 0
        }

        if err == nil {
            return deferMaybe(res)
        }
        return deferMaybe(DatabaseError(err: err))
    }

    /**
     * This method assumes that the site has already been recorded
     * in the history table.
     */
    public func addFavicon(_ icon: Favicon, forSite site: Site) -> Deferred<Maybe<Int>> {
        if Logger.logPII {
            log.verbose("Adding favicon \(icon.url) for site \(site.url).")
        }
        func doChange(_ query: String, args: Args?) -> Deferred<Maybe<Int>> {
            var err: NSError?
            let res = db.withWritableConnection(&err) { (conn, err: inout NSError?) -> Int in
                // Blind! We don't see failure here.
                let id = self.favicons.insertOrUpdate(conn, obj: icon)

                // Now set up the mapping.
                err = conn.executeChange(query, withArgs: args)
                if let err = err {
                    log.error("Got error adding icon: \(err).")
                    return 0
                }

                // Try to update the favicon ID column in each bookmarks table. There can be
                // multiple bookmarks with a particular URI, and a mirror bookmark can be
                // locally changed, so either or both of these statements can update multiple rows.
                if let id = id {
                    conn.executeChange("UPDATE \(TableBookmarksLocal) SET faviconID = ? WHERE bmkUri = ?", withArgs: [id, site.url])
                    conn.executeChange("UPDATE \(TableBookmarksMirror) SET faviconID = ? WHERE bmkUri = ?", withArgs: [id, site.url])
                }

                return id ?? 0
            }

            if res == 0 {
                return deferMaybe(DatabaseError(err: err))
            }
            return deferMaybe(icon.id!)
        }

        let siteSubselect = "(SELECT id FROM \(TableHistory) WHERE url = ?)"
        let iconSubselect = "(SELECT id FROM \(TableFavicons) WHERE url = ?)"
        let insertOrIgnore = "INSERT OR IGNORE INTO \(TableFaviconSites)(siteID, faviconID) VALUES "
        if let iconID = icon.id {
            // Easy!
            if let siteID = site.id {
                // So easy!
                let args: Args? = [siteID, iconID]
                return doChange("\(insertOrIgnore) (?, ?)", args: args)
            }

            // Nearly easy.
            let args: Args? = [site.url, iconID]
            return doChange("\(insertOrIgnore) (\(siteSubselect), ?)", args: args)

        }

        // Sigh.
        if let siteID = site.id {
            let args: Args? = [siteID, icon.url]
            return doChange("\(insertOrIgnore) (?, \(iconSubselect))", args: args)
        }

        // The worst.
        let args: Args? = [site.url, icon.url]
        return doChange("\(insertOrIgnore) (\(siteSubselect), \(iconSubselect))", args: args)
    }
}

extension SQLiteHistory: SyncableHistory {
    /**
     * TODO:
     * When we replace an existing row, we want to create a deleted row with the old
     * GUID and switch the new one in -- if the old record has escaped to a Sync server,
     * we want to delete it so that we don't have two records with the same URL on the server.
     * We will know if it's been uploaded because it'll have a server_modified time.
     */
    public func ensurePlaceWithURL(_ url: String, hasGUID guid: GUID) -> Success {
        let args: Args = [guid, url, guid]

        // The additional IS NOT is to ensure that we don't do a write for no reason.
        return db.run("UPDATE \(TableHistory) SET guid = ? WHERE url = ? AND guid IS NOT ?", withArgs: args)
    }

    public func deleteByGUID(_ guid: GUID, deletedAt: Timestamp) -> Success {
        let args: Args = [guid]
        // This relies on ON DELETE CASCADE to remove visits.
        return db.run("DELETE FROM \(TableHistory) WHERE guid = ?", withArgs: args)
    }

    // Fails on non-existence.
    fileprivate func getSiteIDForGUID(_ guid: GUID) -> Deferred<Maybe<Int>> {
        let args: Args = [guid]
        let query = "SELECT id FROM history WHERE guid = ?"
        let factory: (SDRow) -> Int = { return $0["id"] as! Int }

        return db.runQuery(query, args: args, factory: factory)
            >>== { cursor in
                if cursor.count == 0 {
                    return deferMaybe(NoSuchRecordError(guid: guid))
                }
                return deferMaybe(cursor[0]!)
        }
    }

    public func storeRemoteVisits(_ visits: [Visit], forGUID guid: GUID) -> Success {
        return self.getSiteIDForGUID(guid)
            >>== { (siteID: Int) -> Success in
            let visitArgs = visits.map { (visit: Visit) -> Args in
                let realDate = NSNumber(value: visit.date)
                let isLocal = 0
                let args: Args = [siteID, realDate, visit.type.rawValue, isLocal]
                return args
            }

            // Magic happens here. The INSERT OR IGNORE relies on the multi-column uniqueness
            // constraint on `visits`: we allow only one row for (siteID, date, type), so if a
            // local visit already exists, this silently keeps it. End result? Any new remote
            // visits are added with only one query, keeping any existing rows.
            return self.db.bulkInsert(TableVisits, op: .InsertOrIgnore, columns: ["siteID", "date", "type", "is_local"], values: visitArgs)
        }
    }

    fileprivate struct HistoryMetadata {
        let id: Int
        let serverModified: Timestamp?
        let localModified: Timestamp?
        let isDeleted: Bool
        let shouldUpload: Bool
        let title: String
    }

    fileprivate func metadataForGUID(_ guid: GUID) -> Deferred<Maybe<HistoryMetadata?>> {
        let select = "SELECT id, server_modified, local_modified, is_deleted, should_upload, title FROM \(TableHistory) WHERE guid = ?"
        let args: Args = [guid]
        let factory = { (row: SDRow) -> HistoryMetadata in
            return HistoryMetadata(
                id: row["id"] as! Int,
                serverModified: row.getTimestamp("server_modified"),
                localModified: row.getTimestamp("local_modified"),
                isDeleted: row.getBoolean("is_deleted"),
                shouldUpload: row.getBoolean("should_upload"),
                title: row["title"] as! String
            )
        }
        return db.runQuery(select, args: args, factory: factory) >>== { cursor in
            return deferMaybe(cursor[0])
        }
    }

    public func insertOrUpdatePlace(_ place: Place, modified: Timestamp) -> Deferred<Maybe<GUID>> {
        // One of these things will be true here.
        // 0. The item is new.
        //    (a) We have a local place with the same URL but a different GUID.
        //    (b) We have never visited this place locally.
        //    In either case, reconcile and proceed.
        // 1. The remote place is not modified when compared to our mirror of it. This
        //    can occur when we redownload after a partial failure.
        //    (a) And it's not modified locally, either. Nothing to do. Ideally we
        //        will short-circuit so we don't need to update visits. (TODO)
        //    (b) It's modified locally. Don't overwrite anything; let the upload happen.
        // 2. The remote place is modified (either title or visits).
        //    (a) And it's not locally modified. Update the local entry.
        //    (b) And it's locally modified. Preserve the title of whichever was modified last.
        //        N.B., this is the only instance where we compare two timestamps to see
        //        which one wins.

        // We use this throughout.
        let serverModified = NSNumber(value: modified)

        // Check to see if our modified time is unchanged, if the record exists locally, etc.
        let insertWithMetadata = { (metadata: HistoryMetadata?) -> Deferred<Maybe<GUID>> in
            if let metadata = metadata {
                // The item exists locally (perhaps originally with a different GUID).
                if metadata.serverModified == modified {
                    log.verbose("History item \(place.guid) is unchanged; skipping insert-or-update.")
                    return deferMaybe(place.guid)
                }

                // Otherwise, the server record must have changed since we last saw it.
                if metadata.shouldUpload {
                    // Uh oh, it changed locally.
                    // This might well just be a visit change, but we can't tell. Usually this conflict is harmless.
                    log.debug("Warning: history item \(place.guid) changed both locally and remotely. Comparing timestamps from different clocks!")
                    if (metadata.localModified ?? 0) > modified {
                        log.debug("Local changes overriding remote.")

                        // Update server modified time only. (Though it'll be overwritten again after a successful upload.)
                        let update = "UPDATE \(TableHistory) SET server_modified = ? WHERE id = ?"
                        let args: Args = [serverModified, metadata.id]
                        return self.db.run(update, withArgs: args) >>> always(place.guid)
                    }

                    log.verbose("Remote changes overriding local.")
                    // Fall through.
                }

                // The record didn't change locally. Update it.
                log.verbose("Updating local history item for guid \(place.guid).")
                let update = "UPDATE \(TableHistory) SET title = ?, server_modified = ?, is_deleted = 0 WHERE id = ?"
                let args: Args = [place.title, serverModified, metadata.id]
                return self.db.run(update, withArgs: args) >>> always(place.guid)
            }

            // The record doesn't exist locally. Insert it.
            log.verbose("Inserting remote history item for guid \(place.guid).")
            if let host = place.url.asURL?.normalizedHost() {
                if Logger.logPII {
                    log.debug("Inserting: \(place.url).")
                }

                let insertDomain = "INSERT OR IGNORE INTO \(TableDomains) (domain) VALUES (?)"
                let insertHistory = "INSERT INTO \(TableHistory) (guid, url, title, server_modified, is_deleted, should_upload, domain_id) " +
                                    "SELECT ?, ?, ?, ?, 0, 0, id FROM \(TableDomains) where domain = ?"
                return self.db.run([
                    (insertDomain, [host]),
                    (insertHistory, [place.guid, place.url, place.title, serverModified, host])
                ]) >>> always(place.guid)
            } else {
                // This is a URL with no domain. Insert it directly.
                if Logger.logPII {
                    log.debug("Inserting: \(place.url) with no domain.")
                }

                let insertHistory = "INSERT INTO \(TableHistory) (guid, url, title, server_modified, is_deleted, should_upload, domain_id) " +
                                    "VALUES (?, ?, ?, ?, 0, 0, NULL)"
                return self.db.run([
                    (insertHistory, [place.guid, place.url, place.title, serverModified])
                ]) >>> always(place.guid)
            }
        }

        // Make sure that we only need to compare GUIDs by pre-merging on URL.
        return self.ensurePlaceWithURL(place.url, hasGUID: place.guid)
            >>> { self.metadataForGUID(place.guid) >>== insertWithMetadata }
    }

    public func getDeletedHistoryToUpload() -> Deferred<Maybe<[GUID]>> {
        // Use the partial index on should_upload to make this nice and quick.
        let sql = "SELECT guid FROM \(TableHistory) WHERE \(TableHistory).should_upload = 1 AND \(TableHistory).is_deleted = 1"
        let f: (SDRow) -> String = { $0["guid"] as! String }

        return self.db.runQuery(sql, args: nil, factory: f) >>== { deferMaybe($0.asArray()) }
    }

    public func getModifiedHistoryToUpload() -> Deferred<Maybe<[(Place, [Visit])]>> {
        // What we want to do: find all items flagged for update, selecting some number of their
        // visits alongside.
        //
        // A difficulty here: we don't want to fetch *all* visits, only some number of the most recent.
        // (It's not enough to only get new ones, because the server record should contain more.)
        //
        // That's the greatest-N-per-group problem in SQL. Please read and understand the solution
        // to this (particularly how the LEFT OUTER JOIN/HAVING clause works) before changing this query!
        //
        // We can do this in a single query, rather than the N+1 that desktop takes.
        // We then need to flatten the cursor. We do that by collecting
        // places as a side-effect of the factory, producing visits as a result, and merging in memory.

        let args: Args = [
            20,                 // Maximum number of visits to retrieve.
        ]

        // Exclude 'unknown' visits, because they're not syncable.
        let filter = "history.should_upload = 1 AND v1.type IS NOT 0"

        let sql =
        "SELECT " +
        "history.id AS siteID, history.guid AS guid, history.url AS url, history.title AS title, " +
        "v1.siteID AS siteID, v1.date AS visitDate, v1.type AS visitType " +
        "FROM " +
        "visits AS v1 " +
        "JOIN history ON history.id = v1.siteID AND \(filter) " +
        "LEFT OUTER JOIN " +
        "visits AS v2 " +
        "ON v1.siteID = v2.siteID AND v1.date < v2.date " +
        "GROUP BY v1.date " +
        "HAVING COUNT(*) < ? " +
        "ORDER BY v1.siteID, v1.date DESC"

        var places = [Int: Place]()
        var visits = [Int: [Visit]]()

        // Add a place to the accumulator, prepare to accumulate visits, return the ID.
        let ensurePlace: (SDRow) -> Int = { row in
            let id = row["siteID"] as! Int
            if places[id] == nil {
                let guid = row["guid"] as! String
                let url = row["url"] as! String
                let title = row["title"] as! String
                places[id] = Place(guid: guid, url: url, title: title)
                visits[id] = Array()
            }
            return id
        }

        // Store the place and the visit.
        let factory: (SDRow) -> Int = { row in
            let date = row.getTimestamp("visitDate")!
            let type = VisitType(rawValue: row["visitType"] as! Int)!
            let visit = Visit(date: date, type: type)
            let id = ensurePlace(row)
            visits[id]?.append(visit)
            return id
        }

        return db.runQuery(sql, args: args, factory: factory)
            >>== { c in

                // Consume every row, with the side effect of populating the places
                // and visit accumulators.
                var ids = Set<Int>()
                for row in c {
                    // Collect every ID first, so that we're guaranteed to have
                    // fully populated the visit lists, and we don't have to
                    // worry about only collecting each place once.
                    ids.insert(row!)
                }

                // Now we're done with the cursor. Close it.
                c.close()

                // Now collect the return value.
                return deferMaybe(ids.map { return (places[$0]!, visits[$0]!) } )
        }
    }

    public func markAsDeleted(_ guids: [GUID]) -> Success {
        // TODO: support longer GUID lists.
        assert(guids.count < BrowserDB.MaxVariableNumber)

        if guids.isEmpty {
            return succeed()
        }

        log.debug("Wiping \(guids.count) deleted GUIDs.")

        // We deliberately don't limit this to records marked as should_upload, just
        // in case a coding error leaves records with is_deleted=1 but not flagged for
        // upload -- this will catch those and throw them away.
        let inClause = BrowserDB.varlist(guids.count)
        let sql =
        "DELETE FROM \(TableHistory) WHERE " +
        "is_deleted = 1 AND guid IN \(inClause)"

        let args: Args = guids.map { $0 as AnyObject }
        return self.db.run(sql, withArgs: args)
    }

    public func markAsSynchronized(_ guids: [GUID], modified: Timestamp) -> Deferred<Maybe<Timestamp>> {
        // TODO: support longer GUID lists.
        assert(guids.count < 99)

        if guids.isEmpty {
            return deferMaybe(modified)
        }

        log.debug("Marking \(guids.count) GUIDs as synchronized. Returning timestamp \(modified).")

        let inClause = BrowserDB.varlist(guids.count)
        let sql =
        "UPDATE \(TableHistory) SET " +
        "should_upload = 0, server_modified = \(modified) " +
        "WHERE guid IN \(inClause)"

        let args: Args = guids.map { $0 as AnyObject }
        return self.db.run(sql, withArgs: args) >>> always(modified)
    }

    public func doneApplyingRecordsAfterDownload() -> Success {
        self.db.checkpoint()
        return succeed()
    }

    public func doneUpdatingMetadataAfterUpload() -> Success {
        self.db.checkpoint()
        return succeed()
    }
}

extension SQLiteHistory {
    // Returns a deferred `true` if there are rows in the DB that have a server_modified time.
    // Because we clear this when we reset or remove the account, and never set server_modified
    // without syncing, the presence of matching rows directly indicates that a deletion
    // would be synced to the server.
    public func hasSyncedHistory() -> Deferred<Maybe<Bool>> {
        return self.db.queryReturnsResults("SELECT 1 FROM \(TableHistory) WHERE server_modified IS NOT NULL LIMIT 1")
    }
}

extension SQLiteHistory: ResettableSyncStorage {
    // We don't drop deletions when we reset -- we might need to upload a deleted item
    // that never made it to the server.
    public func resetClient() -> Success {
        let flag = "UPDATE \(TableHistory) SET should_upload = 1, server_modified = NULL"
        return self.db.run(flag)
    }
}

extension SQLiteHistory: AccountRemovalDelegate {
    public func onRemovedAccount() -> Success {
        log.info("Clearing history metadata and deleted items after account removal.")
        let discard = "DELETE FROM \(TableHistory) WHERE is_deleted = 1"
        return self.db.run(discard) >>> self.resetClient
    }
}
