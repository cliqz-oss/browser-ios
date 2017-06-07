/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger
import Deferred
import Shared
import Deferred
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public let NotificationDatabaseWasRecreated = "NotificationDatabaseWasRecreated"

private let log = Logger.syncLogger

public typealias Args = [Any?]

protocol Changeable {
    func run(_ sql: String, withArgs args: Args?) -> Success
    func run(_ commands: [String]) -> Success
    func run(_ commands: [(sql: String, args: Args?)]) -> Success
}

protocol Queryable {
    func runQuery<T>(_ sql: String, args: Args?, factory: @escaping (SDRow) -> T) -> Deferred<Maybe<Cursor<T>>>
}

public enum DatabaseOpResult {
    case success
    case failure
    case closed
}

// Version 1 - Basic history table.
// Version 2 - Added a visits table, refactored the history table to be a GenericTable.
// Version 3 - Added a favicons table.
// Version 4 - Added a readinglist table.
// Version 5 - Added the clients and the tabs tables.
// Version 6 - Visit timestamps are now microseconds.
// Version 7 - Eliminate most tables. See BrowserTable instead.
open class BrowserDB {
    fileprivate let db: SwiftData
    // XXX: Increasing this should blow away old history, since we currently don't support any upgrades.
    fileprivate let Version: Int = 7
    fileprivate let files: FileAccessor
    fileprivate let filename: String
    fileprivate let secretKey: String?
    fileprivate let schemaTable: SchemaTable

    fileprivate var initialized = [String]()

    // SQLITE_MAX_VARIABLE_NUMBER = 999 by default. This controls how many ?s can
    // appear in a query string.
    open static let MaxVariableNumber = 999

    public init(filename: String, secretKey: String? = nil, files: FileAccessor) {
        log.debug("Initializing BrowserDB: \(filename).")
        self.files = files
        self.filename = filename
        self.schemaTable = SchemaTable()
        self.secretKey = secretKey

        let file = ((try! files.getAndEnsureDirectory()) as NSString).appendingPathComponent(filename)
        self.db = SwiftData(filename: file, key: secretKey, prevKey: nil)

        if AppConstants.BuildChannel == .Developer && secretKey != nil {
            log.debug("Creating db: \(file) with secret = \(secretKey)")
        }

        // Create or update will also delete and create the database if our key was incorrect.
		switch self.createOrUpdate(self.schemaTable) {
        case .failure:
            log.error("Failed to create/update the scheme table. Aborting.")
            fatalError()
        case .closed:
            log.info("Database not created as the SQLiteConnection is closed.")
        case .success:
            log.debug("db: \(file) with secret = \(secretKey) has been created")
        }
        
        if filename == "browser.db" {
            // Cliqz: new method call to extend tables if needed
            self.extendTables()
        }
    }

    // Creates a table and writes its table info into the table-table database.
    fileprivate func createTable(_ conn: SQLiteDBConnection, table: SectionCreator) -> TableResult {
        log.debug("Try create \(table.name) version \(table.version)")
        if !table.create(conn) {
            // If creating failed, we'll bail without storing the table info
            log.debug("Creation failed.")
            return .failed
        }

        var err: NSError? = nil
        return schemaTable.insert(conn, item: table, err: &err) > -1 ? .created : .failed
    }

    // Updates a table and writes its table into the table-table database.
    // Exposed internally for testing.
    func updateTable(_ conn: SQLiteDBConnection, table: SectionUpdater) -> TableResult {
        log.debug("Trying update \(table.name) version \(table.version)")
        var from = 0
        // Try to find the stored version of the table
        let cursor = schemaTable.query(conn, options: QueryOptions(filter: table.name))
        if cursor.count > 0 {
            if let info = cursor[0] as? TableInfoWrapper {
                from = info.version
            }
        }

        // If the versions match, no need to update
        if from == table.version {
            return .exists
        }

        if !table.updateTable(conn, from: from) {
            // If the update failed, we'll bail without writing the change to the table-table.
            log.debug("Updating failed.")
            return .failed
        }

        var err: NSError? = nil

        // Yes, we UPDATE OR INSERT… because we might be transferring ownership of a database table
        // to a different Table. It'll trigger exists, and thus take the update path, but we won't
        // necessarily have an existing schema entry -- i.e., we'll be updating from 0.
        if schemaTable.update(conn, item: table, err: &err) > 0 ||
           schemaTable.insert(conn, item: table, err: &err) > 0 {
            return .updated
        }
        return .failed
    }

    // Utility for table classes. They should call this when they're initialized to force
    // creation of the table in the database.
    func createOrUpdate(_ tables: Table...) -> DatabaseOpResult {
        guard !db.closed else {
            log.info("Database is closed - skipping schema create/updates")
            return .closed
        }
        
        var success = true

        let doCreate = { (table: Table, connection: SQLiteDBConnection) -> () in
            switch self.createTable(connection, table: table) {
            case .created:
                success = true
                return
            case .exists:
                log.debug("Table already exists.")
                success = true
                return
            default:
                success = false
            }
        }

        if let _ = self.db.transaction({ connection -> Bool in
            let thread = Thread.current.description
            // If the table doesn't exist, we'll create it.
            for table in tables {
                log.debug("Create or update \(table.name) version \(table.version) on \(thread).")
                if !table.exists(connection) {
                    log.debug("Doesn't exist. Creating table \(table.name).")
                    doCreate(table, connection)
                } else {
                    // Otherwise, we'll update it
                    switch self.updateTable(connection, table: table) {
                    case .updated:
                        log.debug("Updated table \(table.name).")
                        success = true
                        break
                    case .exists:
                        log.debug("Table \(table.name) already exists.")
                        success = true
                        break
                    default:
                        log.error("Update failed for \(table.name). Dropping and recreating.")

                        table.drop(connection)
                        var err: NSError? = nil
                        self.schemaTable.delete(connection, item: table, err: &err)

                        doCreate(table, connection)
                    }
                }

                if !success {
                    log.warning("Failed to configure multiple tables. Aborting.")
                    return false
                }
            }
			// Cliqz: Added notification to notify when db creation is finished
			let notify = Notification(name: Notification.Name(rawValue: NotificationDatabaseWasCreated), object: self.filename)
			NotificationCenter.default.post(notify)

            return success
        }) {
            // Err getting a transaction
            success = false
        }

        // If we failed, move the file and try again. This will probably break things that are already
        // attached and expecting a working DB, but at least we should be able to restart.
        var notify: Notification? = nil
        if !success {
            log.debug("Couldn't create or update \(tables.map { $0.name }).")
            log.debug("Attempting to move \(self.filename) to another location.")

            // Make sure that we don't still have open the files that we want to move!
            // Note that we use sqlite3_close_v2, which might actually _not_ close the
            // database file yet. For this reason we move the -shm and -wal files, too.
            db.forceClose()

            // Note that a backup file might already exist! We append a counter to avoid this.
            var bakCounter = 0
            var bak: String
            repeat {
                bakCounter += 1
                bak = "\(self.filename).bak.\(bakCounter)"
            } while self.files.exists(bak)

            do {
                try self.files.move(self.filename, toRelativePath: bak)

                let shm = self.filename + "-shm"
                let wal = self.filename + "-wal"
                log.debug("Moving \(shm) and \(wal)…")
                if self.files.exists(shm) {
                    log.debug("\(shm) exists.")
                    try self.files.move(shm, toRelativePath: bak + "-shm")
                }
                if self.files.exists(wal) {
                    log.debug("\(wal) exists.")
                    try self.files.move(wal, toRelativePath: bak + "-wal")
                }
                success = true

                // Notify the world that we moved the database. This allows us to
                // reset sync and start over in the case of corruption.
                let notification = NotificationDatabaseWasRecreated
                notify = Notification(name: Notification.Name(rawValue: notification), object: self.filename)
            } catch _ {
                success = false
            }
            assert(success)

            // Do this after the relevant tables have been created.
            defer {
                if let notify = notify {
                    NotificationCenter.default.post(notify)
                }
            }

            self.reopenIfClosed()
            if let _ = db.transaction({ connection -> Bool in
                for table in tables {
                    doCreate(table, connection)
                    if !success {
                        return false
                    }
                }
                return success
            }) {
                success = false;
            }
        }

        return success ? .success : .failure
    }

    typealias IntCallback = (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> Int

    func withConnection<T>(flags: SwiftData.Flags, err: inout NSError?, callback: @escaping (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> T) -> T {
        var res: T!
        err = db.withConnection(flags) { connection in
            // This should never occur. Make it fail hard in debug builds.
            assert(!(connection is FailedSQLiteDBConnection))

            var err: NSError? = nil
            res = callback(connection, &err)
            return err
        }
        return res
    }

    func withWritableConnection<T>(_ err: inout NSError?, callback: @escaping (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> T) -> T {
        return withConnection(flags: SwiftData.Flags.readWrite, err: &err, callback: callback)
    }

    func withReadableConnection<T>(_ err: inout NSError?, callback: @escaping (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> Cursor<T>) -> Cursor<T> {
        return withConnection(flags: SwiftData.Flags.readOnly, err: &err, callback: callback)
    }

    func transaction(_ err: inout NSError?, callback: @escaping (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> Bool) -> NSError? {
        return self.transaction(synchronous: true, err: &err, callback: callback)
    }

    func transaction(synchronous: Bool=true, err: inout NSError?, callback: @escaping (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> Bool) -> NSError? {
        return db.transaction(synchronous: synchronous) { connection in
			// Cliqz: Fixed bug: extra declaration of local variable which overrides method argument and cause wrong behaviour in the case of failing query
            var error: NSError? = nil
            return callback(connection, &error)
        }
    }
}

extension BrowserDB {
    func vacuum() {
        log.debug("Vacuuming a BrowserDB.")
        db.withConnection(SwiftData.Flags.readWriteCreate, synchronous: true) { connection in
            return connection.vacuum()
        }
    }

    func checkpoint() {
        log.debug("Checkpointing a BrowserDB.")
        db.transaction(synchronous: true) { connection in
            connection.checkpoint()
            return true
        }
    }
}

extension BrowserDB {
    public class func varlist(_ count: Int) -> String {
        return "(" + Array(repeating: "?", count: count).joined(separator: ", ") + ")"
    }

    enum InsertOperation: String {
        case Insert = "INSERT"
        case Replace = "REPLACE"
        case InsertOrIgnore = "INSERT OR IGNORE"
        case InsertOrReplace = "INSERT OR REPLACE"
        case InsertOrRollback = "INSERT OR ROLLBACK"
        case InsertOrAbort = "INSERT OR ABORT"
        case InsertOrFail = "INSERT OR FAIL"
    }

    /**
     * Insert multiple sets of values into the given table.
     *
     * Assumptions:
     * 1. The table exists and contains the provided columns.
     * 2. Every item in `values` is the same length.
     * 3. That length is the same as the length of `columns`.
     * 4. Every value in each element of `values` is non-nil.
     *
     * If there are too many items to insert, multiple individual queries will run
     * in sequence.
     *
     * A failure anywhere in the sequence will cause immediate return of failure, but
     * will not roll back — use a transaction if you need one.
     */
    func bulkInsert(_ table: String, op: InsertOperation, columns: [String], values: [Args]) -> Success {
        // Note that there's a limit to how many ?s can be in a single query!
        // So here we execute 999 / (columns * rows) insertions per query.
        // Note that we can't use variables for the column names, so those don't affect the count.
        if values.isEmpty {
            log.debug("No values to insert.")
            return succeed()
        }

        let variablesPerRow = columns.count

        // Sanity check.
        assert(values[0].count == variablesPerRow)

        let cols = columns.joined(separator: ", ")
        let queryStart = "\(op.rawValue) INTO \(table) (\(cols)) VALUES "

        let varString = BrowserDB.varlist(variablesPerRow)

        let insertChunk: ([Args]) -> Success = { vals -> Success in
            let valuesString = Array(repeating: varString, count: vals.count).joined(separator: ", ")
            let args: Args = vals.flatMap { $0 }
            return self.run(queryStart + valuesString, withArgs: args)
        }

        let rowCount = values.count
        if (variablesPerRow * rowCount) < BrowserDB.MaxVariableNumber {
            return insertChunk(values)
        }

        log.debug("Splitting bulk insert across multiple runs. I hope you started a transaction!")
        let rowsPerInsert = (999 / variablesPerRow)
        let chunks = chunk(values, by: rowsPerInsert)
        log.debug("Inserting in \(chunks.count) chunks.")

        // There's no real reason why we can't pass the ArraySlice here, except that I don't
        // want to keep fighting Swift.
        return walk(chunks, f: { insertChunk(Array($0)) })
    }

    func runWithConnection<T>(_ block: @escaping (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> T) -> Deferred<Maybe<T>> {
        return DeferredDBOperation(db: self.db, block: block).start()
    }

    func write(_ sql: String, withArgs args: Args? = nil) -> Deferred<Maybe<Int>> {
        return self.runWithConnection() { (connection, err) -> Int in
            err = connection.executeChange(sql, withArgs: args)
            if err == nil {
                let modified = connection.numberOfRowsModified
                log.debug("Modified rows: \(modified).")
                return modified
            }
            return 0
        }
    }

    public func forceClose() {
        db.forceClose()
    }

    public func reopenIfClosed() {
        db.reopenIfClosed()
    }
}

extension BrowserDB: Changeable {
    func run(_ sql: String, withArgs args: Args? = nil) -> Success {
        return run([(sql, args)])
    }

    func run(_ commands: [String]) -> Success {
        return self.run(commands.map { (sql: $0, args: nil) })
    }

    /**
     * Runs an array of SQL commands. Note: These will all run in order in a transaction and will block
     * the caller's thread until they've finished. If any of them fail the operation will abort (no more
     * commands will be run) and the transaction will roll back, returning a DatabaseError.
     */
    func run(_ commands: [(sql: String, args: Args?)]) -> Success {
        if commands.isEmpty {
            return succeed()
        }

        var err: NSError? = nil
        let errorResult = self.transaction(&err) { (conn, err) -> Bool in
            for (sql, args) in commands {
                err = conn.executeChange(sql, withArgs: args)
                if let err = err {
                    log.warning("SQL operation failed: \(err.localizedDescription)")
                    return false
                }
            }
            return true
        }

        if let err = err ?? errorResult {
            return deferMaybe(DatabaseError(err: err))
        }

        return succeed()
    }
}

extension BrowserDB: Queryable {
    func runQuery<T>(_ sql: String, args: Args?, factory: @escaping (SDRow) -> T) -> Deferred<Maybe<Cursor<T>>> {
        return runWithConnection { (connection, err) -> Cursor<T> in
            return connection.executeQuery(sql, factory: factory, withArgs: args)
        }
    }

    func queryReturnsResults(_ sql: String, args: Args?=nil) -> Deferred<Maybe<Bool>> {
        return self.runQuery(sql, args: args, factory: { row in true })
         >>== { deferMaybe($0[0] ?? false) }
    }

    func queryReturnsNoResults(_ sql: String, args: Args?=nil) -> Deferred<Maybe<Bool>> {
        return self.runQuery(sql, args: nil, factory: { row in false })
          >>== { deferMaybe($0[0] ?? true) }
    }
}

extension SQLiteDBConnection {
    func tablesExist(_ names: [String]) -> Bool {
        let count = names.count
        let inClause = BrowserDB.varlist(names.count)
        let tablesSQL = "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN \(inClause)"

        let res = self.executeQuery(tablesSQL, factory: StringFactory, withArgs: names.map { $0 as AnyObject })
        log.debug("\(res.count) tables exist. Expected \(count)")
        return res.count > 0
    }
}
