/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared

private let log = Logger.browserLogger

protocol TabManagerDelegate: class {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?)
    func tabManager(_ tabManager: TabManager, didCreateTab tab: Tab)
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab)
    // Cliqz: Added removeIndex to didRemoveTab method
//    func tabManager(tabManager: TabManager, didRemoveTab tab: Tab)
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, removeIndex: Int)
    func tabManagerDidRestoreTabs(_ tabManager: TabManager)
    func tabManagerDidAddTabs(_ tabManager: TabManager)
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast:ButtonToast?)
}

protocol TabManagerStateDelegate: class {
    func tabManagerWillStoreTabs(_ tabs: [Tab])
}

// We can't use a WeakList here because this is a protocol.
class WeakTabManagerDelegate {
    weak var value : TabManagerDelegate?

    init (value: TabManagerDelegate) {
        self.value = value
    }

    func get() -> TabManagerDelegate? {
        return value
    }
}

// TabManager must extend NSObjectProtocol in order to implement WKNavigationDelegate
class TabManager : NSObject {
    fileprivate var delegates = [WeakTabManagerDelegate]()
    weak var stateDelegate: TabManagerStateDelegate?

    func addDelegate(_ delegate: TabManagerDelegate) {
        assert(Thread.isMainThread)
        delegates.append(WeakTabManagerDelegate(value: delegate))
    }

    func removeDelegate(_ delegate: TabManagerDelegate) {
        assert(Thread.isMainThread)
        for i in 0 ..< delegates.count {
            let del = delegates[i]
            if delegate === del.get() {
                delegates.remove(at: i)
                return
            }
        }
    }

    fileprivate(set) var tabs = [Tab]()
    fileprivate var _selectedIndex = -1
    fileprivate let navDelegate: TabManagerNavDelegate
    fileprivate(set) var isRestoring = false

    // A WKWebViewConfiguration used for normal tabs
    lazy fileprivate var configuration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        // Cliqz: Moved `blockPopups` to SettingsPrefs
//        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !(self.prefs.boolForKey("blockPopups") ?? true)
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !SettingsPrefs.getBlockPopupsPref()
        
        return configuration
    }()

    // A WKWebViewConfiguration used for private mode tabs
    @available(iOS 9, *)
    lazy fileprivate var privateConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        // Cliqz: Moved `blockPopups` to SettingsPrefs
//        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !(self.prefs.boolForKey("blockPopups") ?? true)
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !SettingsPrefs.getBlockPopupsPref()

        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        return configuration
    }()

    // Cliqz: dispatch queue used to presit tabs in background
    fileprivate let preserveTabsQueue = DispatchQueue(label: "com.cliqz.tabManager.preserveTabs")

    fileprivate let imageStore: DiskImageStore?

    fileprivate let prefs: Prefs
    var selectedIndex: Int { return _selectedIndex }
    var tempTabs: [Tab]?

    var normalTabs: [Tab] {
        assert(Thread.isMainThread)

        return tabs.filter { !$0.isPrivate }
    }

    var privateTabs: [Tab] {
        assert(Thread.isMainThread)

        if #available(iOS 9, *) {
            return tabs.filter { $0.isPrivate }
        } else {
            return []
        }
    }

    init(prefs: Prefs, imageStore: DiskImageStore?) {
        assert(Thread.isMainThread)

        self.prefs = prefs
        self.navDelegate = TabManagerNavDelegate()
        self.imageStore = imageStore
        super.init()

        addNavigationDelegate(self)

        NotificationCenter.default.addObserver(self, selector: #selector(TabManager.prefsDidChange), name: UserDefaults.didChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func addNavigationDelegate(_ delegate: WKNavigationDelegate) {
        assert(Thread.isMainThread)

        self.navDelegate.insert(delegate)
    }

    var count: Int {
        assert(Thread.isMainThread)

        return tabs.count
    }
    
    var selectedTab: Tab? {
        assert(Thread.isMainThread)

        if !(0..<count ~= _selectedIndex) {
            return nil
        }

        return tabs[_selectedIndex]
    }

    subscript(index: Int) -> Tab? {
        assert(Thread.isMainThread)

        if index >= tabs.count {
            return nil
        }
        return tabs[index]
    }

    subscript(webView: WKWebView) -> Tab? {
        assert(Thread.isMainThread)

        for tab in tabs {
            if tab.webView === webView {
                return tab
            }
        }

        return nil
    }
	// Cliqz: [UIWebView] Temporary Added to get the tab that contains specific WebView
	func tabForWebView(_ webView: UIWebView) -> Tab? {
		objc_sync_enter(self); defer { objc_sync_exit(self) }
		
		for tab in tabs {
			if tab.webView === webView {
				return tab
			}
		}
		
		return nil
	}

    func getTabFor(_ url: URL) -> Tab? {
        assert(Thread.isMainThread)

        for tab in tabs {
            if (tab.webView?.url == url) {
                return tab
            }
        }
        return nil
    }

    func selectTab(_ tab: Tab?) {
        assert(Thread.isMainThread)

        if selectedTab === tab {
            return
        }

        let previous = selectedTab

        if let tab = tab {
            _selectedIndex = tabs.index(of: tab) ?? -1
        } else {
            _selectedIndex = -1
        }
        
        preserveTabs()

        assert(tab === selectedTab, "Expected tab is selected")
        selectedTab?.createWebview()

        for delegate in delegates {
            delegate.get()?.tabManager(self, didSelectedTabChange: tab, previous: previous)
        }
    }

    func expireSnackbars() {
        assert(Thread.isMainThread)

        for tab in tabs {
            tab.expireSnackbars()
        }
    }

    @available(iOS 9, *)
    func addTab(_ request: URLRequest! = nil, configuration: WKWebViewConfiguration! = nil, isPrivate: Bool) -> Tab {
        return self.addTab(request, configuration: configuration, flushToDisk: true, zombie: false, isPrivate: isPrivate)
    }

    @available(iOS 9, *)
    func addTabAndSelect(_ request: URLRequest! = nil, configuration: WKWebViewConfiguration! = nil, isPrivate: Bool) -> Tab {
        let tab = addTab(request, configuration: configuration, isPrivate: isPrivate)
        selectTab(tab)
        return tab
    }

    func addTabAndSelect(_ request: URLRequest! = nil, configuration: WKWebViewConfiguration! = nil) -> Tab {
        let tab = addTab(request, configuration: configuration)
        selectTab(tab)
        return tab
    }

    // This method is duplicated to hide the flushToDisk option from consumers.
    func addTab(_ request: URLRequest! = nil, configuration: WKWebViewConfiguration! = nil) -> Tab {
        return self.addTab(request, configuration: configuration, flushToDisk: true, zombie: false)
    }

    func addTabsForURLs(_ urls: [URL], zombie: Bool) {
        assert(Thread.isMainThread)

        if urls.isEmpty {
            return
        }

        var tab: Tab!
        for url in urls {
            tab = self.addTab(URLRequest(url: url), flushToDisk: false, zombie: zombie)
        }

        // Flush.
        storeChanges()

        // Select the most recent.
        self.selectTab(tab)

        // Notify that we bulk-loaded so we can adjust counts.
        for delegate in delegates {
            delegate.get()?.tabManagerDidAddTabs(self)
        }
    }

    @available(iOS 9, *)
    fileprivate func addTab(_ request: URLRequest? = nil, configuration: WKWebViewConfiguration? = nil, flushToDisk: Bool, zombie: Bool, isPrivate: Bool) -> Tab {
        assert(Thread.isMainThread)

        // Take the given configuration. Or if it was nil, take our default configuration for the current browsing mode.
        let configuration: WKWebViewConfiguration = configuration ?? (isPrivate ? privateConfiguration : self.configuration)

        let tab = Tab(configuration: configuration, isPrivate: isPrivate)
        configureTab(tab, request: request, flushToDisk: flushToDisk, zombie: zombie)
        return tab
    }

    fileprivate func addTab(_ request: URLRequest? = nil, configuration: WKWebViewConfiguration? = nil, flushToDisk: Bool, zombie: Bool) -> Tab {
        assert(Thread.isMainThread)

        let tab = Tab(configuration: configuration ?? self.configuration)
        configureTab(tab, request: request, flushToDisk: flushToDisk, zombie: zombie)
        return tab
    }

    func configureTab(_ tab: Tab, request: URLRequest?, flushToDisk: Bool, zombie: Bool) {
        assert(Thread.isMainThread)

        for delegate in delegates {
            delegate.get()?.tabManager(self, didCreateTab: tab)
        }

        tabs.append(tab)

        for delegate in delegates {
            delegate.get()?.tabManager(self, didAddTab: tab)
        }

        if !zombie {
            tab.createWebview()
        }
        tab.navigationDelegate = self.navDelegate

        if let request = request {
            tab.loadRequest(request)
        } else {
            let newTabChoice = NewTabAccessors.getNewTabPage(prefs)
            switch newTabChoice {
            case .HomePage:
                // We definitely have a homepage if we've got here 
                // (so we can safely dereference it).
                let url = HomePageAccessors.getHomePage(prefs)!
                tab.loadRequest(URLRequest(url: url))
            case .BlankPage:
                // Do nothing: we're already seeing a blank page.
                break
            default:
                // The common case, where the NewTabPage enum defines
                // one of the about:home pages.
                if let url = newTabChoice.url {
                    tab.loadRequest(PrivilegedRequest(url: url) as URLRequest)
                }
            }
        }
        if flushToDisk {
        	storeChanges()
        }
    }

    // This method is duplicated to hide the flushToDisk option from consumers.
    func removeTab(_ tab: Tab) {
        self.removeTab(tab, flushToDisk: true, notify: true)
        hideNetworkActivitySpinner()
    }

    /// - Parameter notify: if set to true, will call the delegate after the tab
    ///   is removed.
    fileprivate func removeTab(_ tab: Tab, flushToDisk: Bool, notify: Bool) {
        assert(Thread.isMainThread)
        // If the removed tab was selected, find the new tab to select.
        if tab === selectedTab {
            if let index = getIndex(tab) {
                if index + 1 < count {
                    selectTab(tabs[index + 1])
                } else if index - 1 >= 0 {
                    selectTab(tabs[index - 1])
                } else {
                    assert(count == 1, "Removing last tab")
                    selectTab(nil)
                }
            }
        }

        let prevCount = count
        var removeIndex = -1
        for i in 0..<count {
            if tabs[i] === tab {
                removeIndex = i
                tabs.remove(at: i)
                break
            }
        }
        if _selectedIndex > removeIndex && _selectedIndex > 0 {
            _selectedIndex -= 1
        }
        assert(count == prevCount - 1, "Tab removed")

        if tab != selectedTab {
            _selectedIndex = selectedTab == nil ? -1 : tabs.index(of: selectedTab!) ?? 0
        }

        // There's still some time between this and the webView being destroyed.
        // We don't want to pick up any stray events.
        tab.webView?.navigationDelegate = nil

        if notify {
            for delegate in delegates {
                // Cliqz: Added removeIndex to didRemoveTab method
//                delegate.get()?.tabManager(self, didRemoveTab: tab)
                delegate.get()?.tabManager(self, didRemoveTab: tab, removeIndex: removeIndex)
            }
        }

        // Make sure we never reach 0 normal tabs
        if !tab.isPrivate && normalTabs.count == 0 {
            addTabAndSelect()
        }

        if flushToDisk {
        	storeChanges()
        }
    }

    /// Removes all private tabs from the manager.
    /// - Parameter notify: if set to true, the delegate is called when a tab is
    ///   removed.
    func removeAllPrivateTabsAndNotify(_ notify: Bool) {
        privateTabs.forEach({ removeTab($0, flushToDisk: true, notify: notify) })
    }
    
    func removeTabsWithUndoToast(_ tabs: [Tab]) {
        guard AppConstants.MOZ_UNDO_DELETE_TABS_TOAST else {
            removeTabs(tabs)
            return
        }
        tempTabs = tabs
        var tabsCopy = tabs
        
        // Remove the current tab last to prevent switching tabs while removing tabs
        if let selectedTab = selectedTab {
            if let selectedIndex = tabsCopy.index(of: selectedTab) {
                let removed = tabsCopy.remove(at: selectedIndex)
                removeTabs(tabsCopy)
                removeTab(removed)
            }
            else {
                removeTabs(tabsCopy)
            }
        }
        for tab in tabs {
            tab.hideContent()
        }
        var toast: ButtonToast?
        if let numberOfTabs = tempTabs?.count, numberOfTabs > 0  {
            toast = ButtonToast(labelText: String.localizedStringWithFormat(Strings.TabsDeleteAllUndoTitle, numberOfTabs), buttonText: Strings.TabsDeleteAllUndoAction, completion: { buttonPressed in
                if (buttonPressed) {
                    self.undoCloseTabs()
                    for delegate in self.delegates {
                        delegate.get()?.tabManagerDidAddTabs(self)
                    }
                }
                self.eraseUndoCache()
            })
        }
        for delegate in delegates {
            delegate.get()?.tabManagerDidRemoveAllTabs(self, toast: toast)
        }
    }
    
    func undoCloseTabs() {
        guard let tempTabs = self.tempTabs, tempTabs.count ?? 0 > 0 else {
            return
        }
        
        let tabsCopy = normalTabs
        restoreTabs(tempTabs)
        for tab in tempTabs {
            tab.showContent(true)
        }
        if !tempTabs[0].isPrivate ?? true {
            removeTabs(tabsCopy)
        }
        selectTab(tempTabs.first)
        self.tempTabs?.removeAll()
        tabs.first?.createWebview()
    }
    
    func eraseUndoCache() {
        tempTabs?.removeAll()
    }

    func removeTabs(_ tabs: [Tab]) {
        for tab in tabs {
            self.removeTab(tab, flushToDisk: false, notify: true)
        }
        storeChanges()
    }
    
    func removeAll() {
        removeTabs(self.tabs)
    }

    func getIndex(_ tab: Tab) -> Int? {
        assert(Thread.isMainThread)

        for i in 0..<count {
            if tabs[i] === tab {
                return i
            }
        }

        assertionFailure("Tab not in tabs list")
        return nil
    }

    func getTabForURL(_ url: URL) -> Tab? {
        assert(Thread.isMainThread)

        return tabs.filter { $0.webView?.url == url } .first
    }

    func storeChanges() {
        stateDelegate?.tabManagerWillStoreTabs(normalTabs)

        // Also save (full) tab state to disk.
        preserveTabs()
    }

    func prefsDidChange() {
        // Cliqz: [UIWebview] CliqzWebViewConfiguration does not contain preferences 
#if !CLIQZ
        DispatchQueue.main.async {
            // Cliqz: Moved `blockPopups` to SettingsPrefs
//            let allowPopups = !(self.prefs.boolForKey("blockPopups") ?? true)
            let allowPopups = !SettingsPrefs.getBlockPopupsPref()
            
            // Each tab may have its own configuration, so we should tell each of them in turn.
            for tab in self.tabs {
                tab.webView?.configuration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
            }
            // The default tab configurations also need to change.
            self.configuration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
            if #available(iOS 9, *) {
                self.privateConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
            }
        }
#endif
    }

    func resetProcessPool() {
        assert(Thread.isMainThread)
        configuration.processPool = WKProcessPool()
    }

	func purgeInactiveTabs() {
		for tab in self.tabs {
			if tab != self.selectedTab {
				tab.purgeWebView()
			}
		}
	}

}

extension TabManager {

    public class SavedTab: NSObject, NSCoding {
        let isSelected: Bool
        let title: String?
        let isPrivate: Bool
        var sessionData: SessionData?
        var screenshotUUID: UUID?
        var faviconURL: String?

        var jsonDictionary: [String: AnyObject] {
            let title: String = self.title ?? "null"
            let faviconURL: String = self.faviconURL ?? "null"
            let uuid: String = self.screenshotUUID?.uuidString ?? "null"

            var json: [String: AnyObject] = [
                "title": title as AnyObject,
                "isPrivate": String(self.isPrivate) as AnyObject,
                "isSelected": String(self.isSelected) as AnyObject,
                "faviconURL": faviconURL as AnyObject,
                "screenshotUUID": uuid as AnyObject
            ]

            if let sessionDataInfo = self.sessionData?.jsonDictionary {
                json["sessionData"] = sessionDataInfo as AnyObject?
            }

            return json
        }

        init?(tab: Tab, isSelected: Bool) {
            guard !tab.isPrivate else { return nil }
            
            // Cliqz: preserve tabs is done now in background thread
//            assert(NSThread.isMainThread())

            self.screenshotUUID = tab.screenshotUUID as UUID?
            self.isSelected = isSelected
            self.title = tab.displayTitle
            self.isPrivate = tab.isPrivate
            self.faviconURL = tab.displayFavicon?.url
            super.init()

            if tab.sessionData == nil {
				self.sessionData = tab.generateSessionData()
            } else {
                self.sessionData = tab.sessionData
            }
        }

        required public init?(coder: NSCoder) {
            self.sessionData = coder.decodeObject(forKey: "sessionData") as? SessionData
            self.screenshotUUID = coder.decodeObject(forKey: "screenshotUUID") as? UUID
            self.isSelected = coder.decodeBool(forKey: "isSelected")
            self.title = coder.decodeObject(forKey: "title") as? String
            self.isPrivate = coder.decodeBool(forKey: "isPrivate")
            self.faviconURL = coder.decodeObject(forKey: "faviconURL") as? String
        }

        func encode(with coder: NSCoder) {
            coder.encode(sessionData, forKey: "sessionData")
            coder.encode(screenshotUUID, forKey: "screenshotUUID")
            coder.encode(isSelected, forKey: "isSelected")
            coder.encode(title, forKey: "title")
            coder.encode(isPrivate, forKey: "isPrivate")
            coder.encode(faviconURL, forKey: "faviconURL")
        }
    }

    static fileprivate func tabsStateArchivePath() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: documentsPath).appendingPathComponent("tabsState.archive").path
    }

    static func tabArchiveData() -> Data? {
        let tabStateArchivePath = tabsStateArchivePath()
        if FileManager.default.fileExists(atPath: tabStateArchivePath) {
            return (try? Data(contentsOf: URL(fileURLWithPath: tabStateArchivePath)))
        } else {
            return nil
        }
    }

    static func tabsToRestore() -> [SavedTab]? {
        if let tabData = tabArchiveData() {
            let unarchiver = NSKeyedUnarchiver(forReadingWith: tabData)
            unarchiver.setClass(SavedTab.self, forClassName: "tabs")
            return unarchiver.decodeObject(forKey: "tabs") as? [SavedTab]
        } else {
            return nil
        }
    }

    private func preserveTabsInternal() {
        // Cliqz: preserve tabs is done now in background thread
//        assert(NSThread.isMainThread())

        guard !isRestoring else { return }

        let path = TabManager.tabsStateArchivePath()
        var savedTabs = [SavedTab]()
        // Cliqz: commented any code related to tab screenshot for performance as we don't use it
        var savedUUIDs = Set<String>()
        for (tabIndex, tab) in tabs.enumerated() {
            if let savedTab = SavedTab(tab: tab, isSelected: tabIndex == selectedIndex) {
                savedTabs.append(savedTab)
                // Cliqz: commented any code related to tab screenshot for performance as we don't use it
//                if let screenshot = tab.screenshot,
//                   let screenshotUUID = tab.screenshotUUID
//                {
//                    savedUUIDs.insert(screenshotUUID.UUIDString)
//                    imageStore?.put(screenshotUUID.UUIDString, image: screenshot)
//                }
            }
        }
        // Cliqz: commented any code related to tab screenshot for performance as we don't use it
//        // Clean up any screenshots that are no longer associated with a tab.
//        imageStore?.clearExcluding(savedUUIDs)

        let tabStateData = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: tabStateData)
        archiver.setClassName("tabs", for: SavedTab.self)
        archiver.encode(savedTabs, forKey: "tabs")
        archiver.finishEncoding()
        tabStateData.write(toFile: path, atomically: true)
    }

    func preserveTabs() {
        // This is wrapped in an Objective-C @try/@catch handler because NSKeyedArchiver may throw exceptions which Swift cannot handle
        _ = Try(withTry: { () -> Void in
                // Cliqz: call preserveTabsInternal in background thread
                self.preserveTabsQueue.async(execute: {
                    self.preserveTabsInternal()
                })
            }) { (exception) -> Void in
            print("Failed to preserve tabs: \(exception)")
        }
    }

    fileprivate func restoreTabsInternal() {
        log.debug("Restoring tabs.")
        guard let savedTabs = TabManager.tabsToRestore() else {
            log.debug("Nothing to restore.")
            return
        }

        var tabToSelect: Tab?
        for (_, savedTab) in savedTabs.enumerated() {
            let tab: Tab
            if #available(iOS 9, *) {
                tab = self.addTab(flushToDisk: false, zombie: true, isPrivate: savedTab.isPrivate)
            } else {
                tab = self.addTab(flushToDisk: false, zombie: true)
            }
            
            if let faviconURL = savedTab.faviconURL {
                let icon = Favicon(url: faviconURL, date: Date(), type: IconType.noneFound)
                icon.width = 1
                tab.favicons.append(icon)
            }

            // Set the UUID for the tab, asynchronously fetch the UIImage, then store
            // the screenshot in the tab as long as long as a newer one hasn't been taken.
            if let screenshotUUID = savedTab.screenshotUUID,
               let imageStore = self.imageStore {
                tab.screenshotUUID = screenshotUUID
                imageStore.get(screenshotUUID.uuidString) >>== { screenshot in
                    if tab.screenshotUUID == screenshotUUID {
                        tab.setScreenshot(screenshot, revUUID: false)
                    }
                }
            }

            if savedTab.isSelected {
                tabToSelect = tab
            }

            tab.sessionData = savedTab.sessionData
            tab.lastTitle = savedTab.title
            
            // Cliqz: restore the url of the tab so that it could be listed in tabOverView
            if let urls = tab.sessionData?.urls, let currentPage = tab.sessionData?.currentPage, urls.count > 0 {
                // Note that current index is reverted, 0, -1, -2, .. - (n-1)
                let index = (urls.count - 1) + currentPage
                if index < urls.count {
                    let url = urls[index]
                    tab.url = url
                    if url.host != "localhost" {
                        tab.restoringUrl = url
                    }
                }
            }
        }

        if tabToSelect == nil {
            tabToSelect = tabs.first
        }

        log.debug("Done adding tabs.")

        // Only tell our delegates that we restored tabs if we actually restored a tab(s)
        if savedTabs.count > 0 {
            log.debug("Notifying delegates.")
            for delegate in delegates {
                delegate.get()?.tabManagerDidRestoreTabs(self)
            }
        }

        if let tab = tabToSelect {
            log.debug("Selecting a tab.")
            selectTab(tab)
            log.debug("Creating webview for selected tab.")
            tab.createWebview()
        }

        log.debug("Done.")
    }

    func restoreTabs() {
        isRestoring = true

        if count == 0 && !AppConstants.IsRunningTest && !DebugSettingsBundleOptions.skipSessionRestore {
            // This is wrapped in an Objective-C @try/@catch handler because NSKeyedUnarchiver may throw exceptions which Swift cannot handle
            let _ = Try(
                withTry: { () -> Void in
                    self.restoreTabsInternal()
                },
                catch: { exception in
                    print("Failed to restore tabs: \(exception)")
                }
            )
        }

        if count == 0 {
            let tab = addTab()
            selectTab(tab)
        }

        isRestoring = false
    }
    
    func restoreTabs(_ savedTabs: [Tab]) {
        isRestoring = true
        for tab in savedTabs {
            tabs.append(tab)
            tab.navigationDelegate = self.navDelegate
            for delegate in delegates {
                delegate.get()?.tabManager(self, didAddTab: tab)
            }
        }
        isRestoring = false
    }
}

extension TabManager : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        let isNoImageMode = self.prefs.boolForKey(PrefsKeys.KeyNoImageModeStatus) ?? false
        let tab = self[webView]
        tab?.setNoImageMode(isNoImageMode, force: false)
        let isNightMode = NightModeAccessors.isNightMode(self.prefs)
        tab?.setNightMode(isNightMode)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideNetworkActivitySpinner()
        // only store changes if this is not an error page
        // as we current handle tab restore as error page redirects then this ensures that we don't
        // call storeChanges unnecessarily on startup
        if let url = webView.url {
            if !ErrorPageHelper.isErrorPageURL(url) {
                storeChanges()
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideNetworkActivitySpinner()
    }

    func hideNetworkActivitySpinner() {
        for tab in tabs {
            if let tabWebView = tab.webView {
                // If we find one tab loading, we don't hide the spinner
                if tabWebView.isLoading {
                    return
                }
            }
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    /// Called when the WKWebView's content process has gone away. If this happens for the currently selected tab
    /// then we immediately reload it.

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if let tab = selectedTab, tab.webView == webView {
            webView.reload()
        }
    }
}

extension TabManager {
    class func tabRestorationDebugInfo() -> String {
        assert(Thread.isMainThread)

        let tabs = TabManager.tabsToRestore()?.map { $0.jsonDictionary } ?? []
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: tabs, options: [.prettyPrinted])
            return String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        } catch _ {
            return ""
        }
    }
}

// WKNavigationDelegates must implement NSObjectProtocol
class TabManagerNavDelegate : NSObject, WKNavigationDelegate {
    fileprivate var delegates = WeakList<WKNavigationDelegate>()

    func insert(_ delegate: WKNavigationDelegate) {
        delegates.insert(delegate)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didCommit: navigation)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        for delegate in delegates {
            delegate.webView?(webView, didFail: navigation, withError: error)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error) {
            for delegate in delegates {
                delegate.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
            }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didFinish: navigation)
        }
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition,
        URLCredential?) -> Void) {
            let authenticatingDelegates = delegates.filter {
                $0.responds(to: #selector(WKNavigationDelegate.webView(_:didReceive:completionHandler:)))
            }

            guard let firstAuthenticatingDelegate = authenticatingDelegates.first else {
                return completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
            }

            firstAuthenticatingDelegate.webView?(webView, didReceive: challenge) { (disposition, credential) in
                completionHandler(disposition, credential)
            }
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didStartProvisionalNavigation: navigation)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            var res = WKNavigationActionPolicy.allow
            for delegate in delegates {
                delegate.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: { policy in
                    if policy == .cancel {
                        res = policy
                    }
                })
            }

            decisionHandler(res)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            var res = WKNavigationResponsePolicy.allow
            for delegate in delegates {
                delegate.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: { policy in
                    if policy == .cancel {
                        res = policy
                    }
                })
            }

            decisionHandler(res)
    }
}
