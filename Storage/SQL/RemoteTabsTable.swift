/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

let TableClients: String = "clients"
let TableTabs = "tabs"

class RemoteClientsTable<T>: GenericTable<RemoteClient> {
    override var name: String { return TableClients }
    override var version: Int { return 1 }

    // TODO: index on guid and last_modified.
    override var rows: String { return [
            "guid TEXT PRIMARY KEY",
            "name TEXT NOT NULL",
            "modified INTEGER NOT NULL",
            "type TEXT",
            "formfactor TEXT",
            "os TEXT",
        ].joined(separator: ",")
    }

    // TODO: this won't work correctly with NULL fields.
    override func getInsertAndArgs(_ item: inout RemoteClient) -> (String, Args)? {
        let args: Args = [
            item.guid,
            item.name,
            NSNumber(value: item.modified),
            item.type,
            item.formfactor,
            item.os,
        ]
        return ("INSERT INTO \(name) (guid, name, modified, type, formfactor, os) VALUES (?, ?, ?, ?, ?, ?)", args)
    }

    override func getUpdateAndArgs(_ item: inout RemoteClient) -> (String, Args)? {
        let args: Args = [
            item.name,
            NSNumber(value: item.modified),
            item.type,
            item.formfactor,
            item.os,
            item.guid,
        ]

        return ("UPDATE \(name) SET name = ?, modified = ?, type = ?, formfactor = ?, os = ? WHERE guid = ?", args)
    }

    override func getDeleteAndArgs(_ item: inout RemoteClient?) -> (String, Args)? {
        if let item = item {
            return ("DELETE FROM \(name) WHERE guid = ?", [item.guid])
        }

        return ("DELETE FROM \(name)", [])
    }

    override var factory: ((_ row: SDRow) -> RemoteClient)? {
        return { row -> RemoteClient in
            return RemoteClient(guid: row["guid"] as? String,
                                name: row["name"] as! String,
                                modified: (row["modified"] as! NSNumber).uint64Value,
                                type: row["type"] as? String,
                                formfactor: row["formfactor"] as? String,
                                os: row["os"] as? String)
        }
    }

    override func getQueryAndArgs(_ options: QueryOptions?) -> (String, Args)? {
        return ("SELECT * FROM \(name) ORDER BY modified DESC", [])
    }
}

class RemoteTabsTable<T>: GenericTable<RemoteTab> {
    override var name: String { return TableTabs }
    override var version: Int { return 2 }

    // TODO: index on id, client_guid, last_used, and position.
    override var rows: String { return [
            "id INTEGER PRIMARY KEY AUTOINCREMENT", // An individual tab has no GUID from Sync.
            "client_guid TEXT REFERENCES clients(guid) ON DELETE CASCADE",
            "url TEXT NOT NULL",
            "title TEXT", // TODO: NOT NULL throughout.
            "history TEXT",
            "last_used INTEGER",
        ].joined(separator: ",")
    }

    private static func convertHistoryToString(_ history: [URL]) -> String? {
        let historyAsStrings = optFilter(history.map { $0.absoluteString })

        let data = try! JSONSerialization.data(withJSONObject: historyAsStrings, options: [])
        return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String
    }

    private func convertStringToHistory(_ history: String?) -> [URL] {
        if let data = history?.data(using: String.Encoding.utf8) {
			if let urlStrings = try! JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments]) as? [String] {
                return optFilter(urlStrings.map { URL(string: $0) })
            }
        }
        return []
    }

    override func getInsertAndArgs(_ item: inout RemoteTab) -> (String, Args)? {
        let args: Args = [
            item.clientGUID,
            item.URL.absoluteString,
            item.title,
            RemoteTabsTable.convertHistoryToString(item.history),
            NSNumber(value: item.lastUsed),
        ]

        return ("INSERT INTO \(name) (client_guid, url, title, history, last_used) VALUES (?, ?, ?, ?, ?)", args)
    }

    override func getUpdateAndArgs(_ item: inout RemoteTab) -> (String, Args)? {
        let args: Args = [
            item.title,
            RemoteTabsTable.convertHistoryToString(item.history),
            NSNumber(value: item.lastUsed),

            // Key by (client_guid, url) rather than (transient) id.
            item.clientGUID,
            item.URL.absoluteString,
        ]

        return ("UPDATE \(name) SET title = ?, history = ?, last_used = ? WHERE client_guid IS ? AND url = ?", args)
    }

    override func getDeleteAndArgs(_ item: inout RemoteTab?) -> (String, Args)? {
        if let item = item {
            return ("DELETE FROM \(name) WHERE client_guid = IS AND url = ?", [item.clientGUID, item.URL.absoluteString])
        }

        return ("DELETE FROM \(name)", [])
    }

    override var factory: ((_ row: SDRow) -> RemoteTab)? {
        return { (row: SDRow) -> RemoteTab in
            return RemoteTab(
                clientGUID: row["client_guid"] as? String,
                URL: URL(string: row["url"] as! String)!, // TODO: find a way to make this less dangerous.
                title: row["title"] as! String,
                history: self.convertStringToHistory(row["history"] as? String),
                lastUsed: row.getTimestamp("last_used")!,
                icon: nil      // TODO
            )
        }
    }

    override func getQueryAndArgs(_ options: QueryOptions?) -> (String, Args)? {
        // Per-client chunks, each chunk in client-order.
        return ("SELECT * FROM \(name) WHERE client_guid IS NOT NULL ORDER BY client_guid DESC, last_used DESC", [])
    }
}
