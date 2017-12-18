/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit
import Deferred
import WebImage

private let log = Logger.browserLogger

// Removed Clearables as part of Bug 1226654, but keeping the string around.
private let removedSavedLoginsLabel = NSLocalizedString("Saved Logins", tableName: "ClearPrivateData", comment: "Settings item for clearing passwords and login data")

// A base protocol for something that can be cleared.
protocol Clearable {
    func clear() -> Success
    var label: String { get }
}

class ClearableError: MaybeErrorType {
    fileprivate let msg: String
    init(msg: String) {
        self.msg = msg
    }

    var description: String { return msg }
}

// Clears our browsing history, including favicons and thumbnails.
class HistoryClearable: Clearable {
    let profile: Profile
    init(profile: Profile) {
        self.profile = profile
    }

    var label: String {
        return NSLocalizedString("Browsing History", tableName: "ClearPrivateData", comment: "Settings item for clearing browsing history")
    }

    func clear() -> Success {
        // Cliqz: clear unfavorite history itmes
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationPrivateDataClearQueries), object: 0)

        return Deferred<Maybe<Void>>()
    }
}

// Cliqz: For Clearing bookmarked items.
class BookmarksClearable: Clearable {
    let profile: Profile
    init(profile: Profile) {
        self.profile = profile
    }

    var label: String {
        return NSLocalizedString("Favorites", tableName: "Cliqz", comment: "Settings item for clearing favorite history")
    }
    
    func clear() -> Success {
        // clear bookmarked itmes
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationPrivateDataClearQueries), object: 1)
        return Deferred<Maybe<Void>>()
    }
}

struct ClearableErrorType: MaybeErrorType {
    let err: Error

    init(err: Error) {
        self.err = err
    }

    var description: String {
        return "Couldn't clear: \(err)."
    }
}

// Clear the web cache. Note, this has to close all open tabs in order to ensure the data
// cached in them isn't flushed to disk.
class CacheClearable: Clearable {
    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    var label: String {
        return NSLocalizedString("Cache", tableName: "ClearPrivateData", comment: "Settings item for clearing the cache")
    }

    func clear() -> Success {
        if #available(iOS 9.0, *) {
            let dataTypes = Set([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
            WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast, completionHandler: {})
        }
        // Cliqz: clear the cache in the tranditional way to support UIWebView as well
        // else {
            // First ensure we close all open tabs first.
//            tabManager.removeAll()

            // Reset the process pool to ensure no cached data is written back
            tabManager.resetProcessPool()

            // Remove the basic cache.
            URLCache.shared.removeAllCachedResponses()

            // Now let's finish up by destroying our Cache directory.
            do {
                try deleteLibraryFolderContents("Caches")
            } catch {
                return deferMaybe(ClearableErrorType(err: error))
            }
//        }

        log.debug("CacheClearable succeeded.")
        return succeed()
    }
}

private func deleteLibraryFolderContents(_ folder: String) throws {
    let manager = FileManager.default
    let library = manager.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: .userDomainMask)[0]
    let dir = library.appendingPathComponent(folder)
    let contents = try manager.contentsOfDirectory(atPath: dir.path)
    for content in contents {
        do {
            try manager.removeItem(at: dir.appendingPathComponent(content))
        // Cliqz: catch any error instead of only `EPERM` so to prevent app from crashing when it couldn't delete the file for any reason
        } catch { // where ((error as NSError).userInfo[NSUnderlyingErrorKey] as? NSError)?.code == Int(EPERM) {
            // "Not permitted". We ignore this.
            log.debug("Couldn't delete some library contents.")
        }
    }
}

private func deleteLibraryFolder(_ folder: String) throws {
    let manager = FileManager.default
    let library = manager.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: .userDomainMask)[0]
    let dir = library.appendingPathComponent(folder)
    try manager.removeItem(at: dir)
}

// Removes all app cache storage.
class SiteDataClearable: Clearable {
    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    var label: String {
        return NSLocalizedString("Offline Website Data", tableName: "ClearPrivateData", comment: "Settings item for clearing website data")
    }

    func clear() -> Success {
        if #available(iOS 9.0, *) {
            let dataTypes = Set([WKWebsiteDataTypeOfflineWebApplicationCache])
            WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast, completionHandler: {})
        } else {
            // First, close all tabs to make sure they don't hold anything in memory.
//            tabManager.removeAll()

            // Then we just wipe the WebKit directory from our Library.
            do {
                try deleteLibraryFolder("WebKit")
            } catch {
                return deferMaybe(ClearableErrorType(err: error))
            }
        }

        log.debug("SiteDataClearable succeeded.")
        return succeed()
    }
}

// Remove all cookies stored by the site. This includes localStorage, sessionStorage, and WebSQL/IndexedDB.
class CookiesClearable: Clearable {
    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    var label: String {
        return NSLocalizedString("Cookies", tableName: "ClearPrivateData", comment: "Settings item for clearing cookies")
    }

    func clear() -> Success {
        if #available(iOS 9.0, *) {
            // Cliqz: Disable clearing the locale storage when clearing cookies as it clears Cliqz data like saved search queries
//            let dataTypes = Set([WKWebsiteDataTypeCookies, WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeWebSQLDatabases, WKWebsiteDataTypeIndexedDBDatabases])
            let dataTypes = Set([WKWebsiteDataTypeCookies, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeWebSQLDatabases, WKWebsiteDataTypeIndexedDBDatabases])
            WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast, completionHandler: {})
        }
        // Cliqz: clear the cookies in the tranditional way to support UIWebView as well
        // else {
        // First close all tabs to make sure they aren't holding anything in memory.
//        tabManager.removeAll()
        
        // Now we wipe the system cookie store (for our app).
        let storage = HTTPCookieStorage.shared
        if let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }
        
        // And just to be safe, we also wipe the Cookies directory.
        do {
            try deleteLibraryFolderContents("Cookies")
        } catch {
            return deferMaybe(ClearableErrorType(err: error))
        }
//        }

        log.debug("CookiesClearable succeeded.")
        return succeed()
    }
}
