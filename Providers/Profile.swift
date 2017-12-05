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

public enum SyncDisplayState {
    case inProgress
    case good
    case bad(message: String?)
    case stale(message: String)

    func asObject() -> [String: String]? {
        switch self {
        case .bad(let msg):
            guard let message = msg else {
                return ["state": "Error"]
            }
            return ["state": "Error",
                    "message": message]
        case .stale(let message):
            return ["state": "Warning",
                    "message": message]
        default:
            break
        }
        return nil
    }
}

public func ==(a: SyncDisplayState, b: SyncDisplayState) -> Bool {
    switch (a, b) {
    case (.inProgress,   .inProgress): return true
    case (.good,   .good): return true
    case (.bad(let a), .bad(let b)) where a == b: return true
    case (.stale(let a), .stale(let b)) where a == b: return true
    default: return false
    }
}

public protocol SyncManager {
    var isSyncing: Bool { get }
    var lastSyncFinishTime: Timestamp? { get set }
    var syncDisplayState: SyncDisplayState? { get }

    func hasSyncedHistory() -> Deferred<Maybe<Bool>>
    func hasSyncedLogins() -> Deferred<Maybe<Bool>>

    func syncClients() -> SyncResult
    func syncClientsThenTabs() -> SyncResult
    func syncHistory() -> SyncResult
    func syncLogins() -> SyncResult
    func syncEverything() -> Success

    // The simplest possible approach.
    func beginTimedSyncs()
    func endTimedSyncs()
    func applicationDidEnterBackground()
    func applicationDidBecomeActive()

    func onNewProfile()
    func onRemovedAccount(_ account: FirefoxAccount?) -> Success
    func onAddedAccount() -> Success
}

typealias EngineIdentifier = String
typealias SyncFunction = (SyncDelegate, Prefs, Ready) -> SyncResult
private typealias EngineStatus = (EngineIdentifier, SyncStatus)

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

        super.init(rootPath: rootPath.appendingPathComponent(profileDirName))
    }
}

//class CommandStoringSyncDelegate: SyncDelegate {
//    let profile: Profile
//
//    init() {
//        profile = BrowserProfile(localName: "profile", app: nil)
//    }
//
////    func displaySentTabForURL(_ URL: URL, title: String) {
////        let item = ShareItem(url: URL.absoluteString, title: title, favicon: nil)
////        //self.profile.queue.addToQueue(item)
////    }
//}

/**
 * This exists because the Sync code is extension-safe, and thus doesn't get
 * direct access to UIApplication.sharedApplication, which it would need to
 * display a notification.
 * This will also likely be the extension point for wipes, resets, and
 * getting access to data sources during a sync.
 */

let TabSendURLKey = "TabSendURL"
let TabSendTitleKey = "TabSendTitle"
let TabSendCategory = "TabSendCategory"

enum SentTabAction: String {
    case View = "TabSendViewAction"
    case Bookmark = "TabSendBookmarkAction"
    case ReadingList = "TabSendReadingListAction"
}

class BrowserProfileSyncDelegate: SyncDelegate {
    let app: UIApplication

    init(app: UIApplication) {
        self.app = app
    }

    // SyncDelegate
    func displaySentTabForURL(_ URL: URL, title: String) {
        // check to see what the current notification settings are and only try and send a notification if
        // the user has agreed to them
        if let currentSettings = app.currentUserNotificationSettings {
            if currentSettings.types.rawValue & UIUserNotificationType.alert.rawValue != 0 {
                if Logger.logPII {
                    log.info("Displaying notification for URL \(URL.absoluteString)")
                }

                let notification = UILocalNotification()
                notification.fireDate = Date()
                notification.timeZone = NSTimeZone.default
                notification.alertBody = String(format: NSLocalizedString("New tab: %@: %@", comment:"New tab [title] [url]"), title, URL.absoluteString)
                notification.userInfo = [TabSendURLKey: URL.absoluteString, TabSendTitleKey: title]
                notification.alertAction = nil
                notification.category = TabSendCategory

                app.presentLocalNotificationNow(notification)
            }
        }
    }
}

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

    // URLs and account configuration.
    var accountConfiguration: FirefoxAccountConfiguration { get }

    // Do we have an account at all?
    func hasAccount() -> Bool

    // Do we have an account that (as far as we know) is in a syncable state?
    func hasSyncableAccount() -> Bool

    func getAccount() -> FirefoxAccount?
    func removeAccount()
    func setAccount(_ account: FirefoxAccount)
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
		//self.db = BrowserDB(filename: "browser.db", files: files)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(BrowserProfile.onLocationChange(_:)), name: NotificationOnLocationChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(BrowserProfile.onProfileDidFinishSyncing(notification:)), name: NotificationProfileDidFinishSyncing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(BrowserProfile.onPrivateDataClearedHistory(notification:)), name: NotificationPrivateDataClearedHistory, object: nil)


        // If the profile dir doesn't exist yet, this is first run (for this profile).
        if !files.exists("") {
            log.info("New profile. Removing old account metadata.")
            self.removeAccountMetadata()
            self.removeExistingAuthenticationInfo()
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

    var accountConfiguration: FirefoxAccountConfiguration {
        if isChinaEdition {
            return ChinaEditionFirefoxAccountConfiguration()
        }
        return ProductionFirefoxAccountConfiguration()
    }

    private lazy var account: FirefoxAccount? = {
		if let dictionary = KeychainWrapper.sharedAppContainerKeychain.object(forKey: self.name + ".account") as? [String: AnyObject] {
            return FirefoxAccount.fromDictionary(dictionary)
        }
        return nil
    }()

    func hasAccount() -> Bool {
        return account != nil
    }

    func hasSyncableAccount() -> Bool {
        return account?.actionNeeded == FxAActionNeeded.none
    }

    func getAccount() -> FirefoxAccount? {
        return account
    }

    func removeAccountMetadata() {
        self.prefs.removeObjectForKey(PrefsKeys.KeyLastRemoteTabSyncTime)
        KeychainWrapper.sharedAppContainerKeychain.removeObject(forKey: self.name + ".account")
    }

    func removeExistingAuthenticationInfo() {
        KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(nil)
    }

    func removeAccount() {
        let old = self.account
        removeAccountMetadata()
        self.account = nil

        // Tell any observers that our account has changed.
        NotificationCenter.default.post(name: NotificationFirefoxAccountChanged, object: nil)

        // Trigger cleanup. Pass in the account in case we want to try to remove
        // client-specific data from the server.
        //self.syncManager.onRemovedAccount(old)

        // Deregister for remote notifications.
        app?.unregisterForRemoteNotifications()
    }

    func setAccount(_ account: FirefoxAccount) {
        KeychainWrapper.sharedAppContainerKeychain.set(account.dictionary() as NSCoding, forKey: name + ".account")
        self.account = account

        // register for notifications for the account
        registerForNotifications()
        
        // tell any observers that our account has changed
        let userInfo = [NotificationUserInfoKeyHasSyncableAccount: hasSyncableAccount()]
        NotificationCenter.default.post(name: NotificationFirefoxAccountChanged, object: nil, userInfo: userInfo)

        //self.syncManager.onAddedAccount()
    }

    func registerForNotifications() {
        let viewAction = UIMutableUserNotificationAction()
        viewAction.identifier = SentTabAction.View.rawValue
        viewAction.title = NSLocalizedString("View", comment: "View a URL - https://bugzilla.mozilla.org/attachment.cgi?id=8624438, https://bug1157303.bugzilla.mozilla.org/attachment.cgi?id=8624440")
        viewAction.activationMode = UIUserNotificationActivationMode.foreground
        viewAction.isDestructive = false
        viewAction.isAuthenticationRequired = false

        let bookmarkAction = UIMutableUserNotificationAction()
        bookmarkAction.identifier = SentTabAction.Bookmark.rawValue
        bookmarkAction.title = NSLocalizedString("Bookmark", comment: "Bookmark a URL - https://bugzilla.mozilla.org/attachment.cgi?id=8624438, https://bug1157303.bugzilla.mozilla.org/attachment.cgi?id=8624440")
        bookmarkAction.activationMode = UIUserNotificationActivationMode.foreground
        bookmarkAction.isDestructive = false
        bookmarkAction.isAuthenticationRequired = false

        let readingListAction = UIMutableUserNotificationAction()
        readingListAction.identifier = SentTabAction.ReadingList.rawValue
        readingListAction.title = NSLocalizedString("Add to Reading List", comment: "Add URL to the reading list - https://bugzilla.mozilla.org/attachment.cgi?id=8624438, https://bug1157303.bugzilla.mozilla.org/attachment.cgi?id=8624440")
        readingListAction.activationMode = UIUserNotificationActivationMode.foreground
        readingListAction.isDestructive = false
        readingListAction.isAuthenticationRequired = false

        let sentTabsCategory = UIMutableUserNotificationCategory()
        sentTabsCategory.identifier = TabSendCategory
        sentTabsCategory.setActions([readingListAction, bookmarkAction, viewAction], for: UIUserNotificationActionContext.default)

        sentTabsCategory.setActions([bookmarkAction, viewAction], for: UIUserNotificationActionContext.minimal)

        app?.registerUserNotificationSettings(UIUserNotificationSettings(types: UIUserNotificationType.alert, categories: [sentTabsCategory]))
        app?.registerForRemoteNotifications()
    }
}
