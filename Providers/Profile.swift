/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Foundation
import Account
import ReadingList
import Shared
import Storage
import Sync
import XCGLogger
import SwiftKeychainWrapper
import Deferred
import SwiftyJSON

private let log = Logger.syncLogger

public let NotificationProfileDidStartSyncing = "NotificationProfileDidStartSyncing"
public let NotificationProfileDidFinishSyncing = Notification.Name("NotificationProfileDidFinishSyncing")
public let ProfileRemoteTabsSyncDelay: TimeInterval = 0.1


typealias EngineIdentifier = String
private typealias EngineStatus = (EngineIdentifier)

class ProfileFileAccessor: FileAccessor {
    convenience init(profile: Profile) {
        self.init(localName: profile.localName())
    }

    init(localName: String) {
        let profileDirName = "profile.\(localName)"

        // Bug 1147262: First option is for device, second is for simulator.
        var rootPath: NSString
        if let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier(),
			let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedContainerIdentifier)
			{
			let path = url.path
            rootPath = path as NSString
        } else {
            log.error("Unable to find the shared container. Defaulting profile location to ~/Documents instead.")
            rootPath = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]) as NSString
        }
        debugPrint("rootpath -- \(rootPath.appendingPathComponent(profileDirName))")
        super.init(rootPath: rootPath.appendingPathComponent(profileDirName))
    }
}

/**
 * This exists because the Sync code is extension-safe, and thus doesn't get
 * direct access to UIApplication.sharedApplication, which it would need to
 * display a notification.
 * This will also likely be the extension point for wipes, resets, and
 * getting access to data sources during a sync.
 */

/**
 * A Profile manages access to the user's data.
 */
protocol Profile: class {
	// Cliqz: Added CliqzShareToDestination and CliqzSQLiteBookmarks protocols to extend bookmarks behaviour
//    var bookmarks: BookmarksModelFactorySource & ShareToDestination & SyncableBookmarks & LocalItemSource & MirrorItemSource & CliqzShareToDestination & CliqzSQLiteBookmarks { get }
    
    // var favicons: Favicons { get }
    var prefs: Prefs { get }
//    var queue: TabQueue { get }
    var searchEngines: SearchEngines { get }
    var files: FileAccessor { get }
    
    
//    var favicons: Favicons { get }
    var readingList: ReadingListService? { get }
    var logins: BrowserLogins & SyncableLogins & ResettableSyncStorage { get }
    var certStore: CertStore { get }
    var recentlyClosedTabs: ClosedTabsStore { get }

    func shutdown()

    // I got really weird EXC_BAD_ACCESS errors on a non-null reference when I made this a getter.
    // Similar to <http://stackoverflow.com/questions/26029317/exc-bad-access-when-indirectly-accessing-inherited-member-in-swift>.
    func localName() -> String

}

public class BrowserProfile: Profile {
    private let name: String
    internal let files: FileAccessor
    
    weak private var app: UIApplication?

    /**
     * N.B., BrowserProfile is used from our extensions, often via a pattern like
     *
     *   BrowserProfile(…).foo.saveSomething(…)
     *
     * This can break if BrowserProfile's initializer does async work that
     * subsequently — and asynchronously — expects the profile to stick around:
     * see Bug 1218833. Be sure to only perform synchronous actions here.
     */
    init(localName: String, app: UIApplication?, clear: Bool = false) {
        log.debug("Initing profile \(localName) on thread \(Thread.current).")
        self.name = localName
        self.files = ProfileFileAccessor(localName: localName)
        self.app = app
        
        if clear {
            do {
                try FileManager.default.removeItem(atPath: self.files.rootPath as String)
            } catch {
                log.info("Cannot clear profile: \(error)")
            }
        }

		self.loginsDB = BrowserDB(filename: "logins.db", secretKey: BrowserProfile.loginsKey, files: files)
		// self.db = BrowserDB(filename: "browser.db", files: files)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(BrowserProfile.onLocationChange(_:)), name: NotificationOnLocationChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(BrowserProfile.onProfileDidFinishSyncing(notification:)), name: NotificationProfileDidFinishSyncing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(BrowserProfile.onPrivateDataClearedHistory(notification:)), name: NotificationPrivateDataClearedHistory, object: nil)


        // If the profile dir doesn't exist yet, this is first run (for this profile).
        if !files.exists("") {
            log.info("New profile. Removing old account metadata.")
            //self.removeAccountMetadata()
            //self.removeExistingAuthenticationInfo()
            prefs.clearAll()
        }

        // Always start by needing invalidation.
        // This is the same as self.history.setTopSitesNeedsInvalidation, but without the
        // side-effect of instantiating SQLiteHistory (and thus BrowserDB) on the main thread.
        prefs.setBool(false, forKey: PrefsKeys.KeyTopSitesCacheIsValid)


        if isChinaEdition {
            // On first run, set the Home button to be in the toolbar.
            if prefs.boolForKey(PrefsKeys.KeyHomePageButtonIsInMenu) == nil {
                prefs.setBool(false, forKey: PrefsKeys.KeyHomePageButtonIsInMenu)
            }
            // Set the default homepage.
            prefs.setString(PrefsDefaults.ChineseHomePageURL, forKey: PrefsKeys.KeyDefaultHomePageURL)

            if prefs.stringForKey(PrefsKeys.KeyNewTab) == nil {
                prefs.setString(PrefsDefaults.ChineseNewTabDefault, forKey: PrefsKeys.KeyNewTab)
            }
        } else {
            // Remove the default homepage. This does not change the user's preference,
            // just the behaviour when there is no homepage.
            prefs.removeObjectForKey(PrefsKeys.KeyDefaultHomePageURL)
        }
    }

    // Extensions don't have a UIApplication.
    convenience init(localName: String) {
        self.init(localName: localName, app: nil)
    }

    func reopen() {
        log.debug("Reopening profile.")

		//db.reopenIfClosed()

		loginsDB.reopenIfClosed()
    }

    func shutdown() {
        log.debug("Shutting down profile.")

		//db.forceClose()

		loginsDB.forceClose()
    }

    @objc
    func onLocationChange(_ notification: NSNotification) {
        if let _ = notification.userInfo!["visitType"] as? Int,
           let url = notification.userInfo!["url"] as? URL, !isIgnoredURL(url),
           let title = notification.userInfo!["title"] as? NSString {
            // Only record local vists if the change notification originated from a non-private tab
            if !(notification.userInfo!["isPrivate"] as? Bool ?? false) {
                // We don't record a visit if no type was specified -- that means "ignore me".
                RealmStore.addVisitSync(url: url.absoluteString, title: String(title))
            }
        } else {
            log.debug("Ignoring navigation.")
        }
    }

    // These selectors run on which ever thread sent the notifications (not the main thread)
    @objc
    func onProfileDidFinishSyncing(notification: NSNotification) {
        //
    }

    @objc
    func onPrivateDataClearedHistory(notification: NSNotification) {
        // Immediately invalidate the top sites cache
    }

    deinit {
        log.debug("Deiniting profile \(self.localName).")
        NotificationCenter.default.removeObserver(self, name: NotificationOnLocationChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
        NotificationCenter.default.removeObserver(self, name: NotificationPrivateDataClearedHistory, object: nil)
    }

    func localName() -> String {
        return name
    }
    
    lazy var logins: BrowserLogins & SyncableLogins & ResettableSyncStorage = {
        return SQLiteLogins(db: self.loginsDB)
    }()


    /**
     * Favicons, history, and bookmarks are all stored in one intermeshed
     * collection of tables.
     *
     * Any other class that needs to access any one of these should ensure
     * that this is initialized first.
     */
    // Cliqz: added ExtendedBrowserHistory protocol to history to get extra data for telemetry signals

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs, files: self.files)
    }()

    func makePrefs() -> Prefs {
        return NSUserDefaultsPrefs(prefix: self.localName())
    }

    lazy var prefs: Prefs = {
        return self.makePrefs()
    }()

    lazy var readingList: ReadingListService? = {
        return ReadingListService(profileStoragePath: self.files.rootPath as String)
    }()


    lazy var certStore: CertStore = {
        return CertStore()
    }()

    lazy var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()


    // This is currently only used within the dispatch_once block in loginsDB, so we don't
    // have to worry about races giving us two keys. But if this were ever to be used
    // elsewhere, it'd be unsafe, so we wrap this in a dispatch_once, too.
    private static var loginsKey: String? {
        let key = "sqlcipher.key.logins.db"
		let keychain = KeychainWrapper.sharedAppContainerKeychain
		if keychain.hasValue(forKey: key) {
			return keychain.string(forKey: key)
		}

		let Length: UInt = 256
		let secret = Bytes.generateRandomBytes(Length).base64EncodedString
		keychain.set(secret, forKey: key)
		return secret
    }

    //let db: BrowserDB
    let loginsDB: BrowserDB

    var isChinaEdition: Bool {
        let locale = NSLocale.current
        return prefs.boolForKey("useChinaSyncService") ?? (locale.identifier == "zh_CN")
    }
}
