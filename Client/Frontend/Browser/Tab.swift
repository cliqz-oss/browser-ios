/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared

import XCGLogger

private let log = Logger.browserLogger

protocol TabHelper {
    static func name() -> String
    func scriptMessageHandlerName() -> String?
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage)
}

@objc
protocol TabDelegate {
    func tab(tab: Tab, didAddSnackbar bar: SnackBar)
    func tab(tab: Tab, didRemoveSnackbar bar: SnackBar)
    func tab(tab: Tab, didSelectFindInPageForSelection selection: String)
	// Cliqz:[UIWebView] Type change
	optional func tab(tab: Tab, didCreateWebView webView: CliqzWebView)
	optional func tab(tab: Tab, willDeleteWebView webView: CliqzWebView)
//	optional func tab(tab: Tab, didCreateWebView webView: WKWebView)
//	optional func tab(tab: Tab, willDeleteWebView webView: WKWebView)
    optional func urlChangedForTab(tab:Tab)
}

struct TabState {
    var isPrivate: Bool = false
    var desktopSite: Bool = false
    var isBookmarked: Bool = false
    var url: NSURL?
    var title: String?
    var favicon: Favicon?
}

class Tab: NSObject {
    private var _isPrivate: Bool = false
    internal private(set) var isPrivate: Bool {
        get {
            if #available(iOS 9, *) {
                return _isPrivate
            } else {
                return false
            }
        }
        set {
            if _isPrivate != newValue {
                _isPrivate = newValue
                self.updateAppState()
            }
        }
    }

    var tabState: TabState {
        return TabState(isPrivate: _isPrivate, desktopSite: desktopSite, isBookmarked: isBookmarked, url: url, title: displayTitle, favicon: displayFavicon)
    }

//  Cliqz:  var webView: WKWebView? = nil
	var webView: CliqzWebView? = nil
    weak var tabDelegate: TabDelegate? = nil
    weak var appStateDelegate: AppStateDelegate?
    var bars = [SnackBar]()
    var favicons = [Favicon]()
    var lastExecutedTime: Timestamp?
    var sessionData: SessionData?
    private var lastRequest: NSURLRequest? = nil
    var restoring: Bool = false
    var pendingScreenshot = false
    var url: NSURL?
    // Cliqz: save restoring url for the tab
    var restoringUrl: NSURL?
    var requestInProgress = false
    /// The last title shown by this tab. Used by the tab tray to show titles for zombie tabs.
    var lastTitle: String?

    /// Whether or not the desktop site was requested with the last request, reload or navigation. Note that this property needs to
    /// be managed by the web view's navigation delegate.
    var desktopSite: Bool = false {
        didSet {
            if oldValue != desktopSite {
                self.updateAppState()
            }
        }
    }
    var isBookmarked: Bool = false {
        didSet {
            if oldValue != isBookmarked {
                self.updateAppState()
            }
        }
    }

    private(set) var screenshot: UIImage?
    var screenshotUUID: NSUUID?

    private var helperManager: HelperManager? = nil
    private var configuration: WKWebViewConfiguration? = nil

    /// Any time a tab tries to make requests to display a Javascript Alert and we are not the active
    /// tab instance, queue it for later until we become foregrounded.
    private var alertQueue = [JSAlertInfo]()
    
    // Cliqz: flag to know whether the current tab is in search mode or not
    var inSearchMode : Bool {
        get {
            if !requestInProgress && !SessionRestoreHandler.isRestorePageURL(url) && (url == nil || AboutUtils.isAboutURL(url) || isCliqzGoToURL(url)) {
                return true
            } else {
                return false
            }
        }
    }
    
    init(configuration: WKWebViewConfiguration) {
        self.configuration = configuration
    }

    @available(iOS 9, *)
    init(configuration: WKWebViewConfiguration, isPrivate: Bool) {
        self.configuration = configuration
        super.init()
        self.isPrivate = isPrivate
    }

    class func toTab(tab: Tab) -> RemoteTab? {
        if let displayURL = tab.displayURL where RemoteTab.shouldIncludeURL(displayURL) {
            let history = Array(tab.historyList.filter(RemoteTab.shouldIncludeURL).reverse())
            return RemoteTab(clientGUID: nil,
                URL: displayURL,
                title: tab.displayTitle,
                history: history,
                lastUsed: NSDate.now(),
                icon: nil)
        } else if let sessionData = tab.sessionData where !sessionData.urls.isEmpty {
            let history = Array(sessionData.urls.filter(RemoteTab.shouldIncludeURL).reverse())
            if let displayURL = history.first {
                return RemoteTab(clientGUID: nil,
                    URL: displayURL,
                    title: tab.displayTitle,
                    history: history,
                    lastUsed: sessionData.lastUsedTime,
                    icon: nil)
            }
        }

        return nil
    }

    private func updateAppState() {
        let state = mainStore.updateState(.Tab(tabState: self.tabState))
        self.appStateDelegate?.appDidUpdateState(state)
    }

    weak var navigationDelegate: WKNavigationDelegate? {
        didSet {
            if let webView = webView {
                webView.navigationDelegate = navigationDelegate
            }
        }
    }

    func createWebview() {
        if webView == nil {
            assert(configuration != nil, "Create webview can only be called once")
            configuration!.userContentController = WKUserContentController()
            configuration!.preferences = WKPreferences()
            configuration!.preferences.javaScriptCanOpenWindowsAutomatically = false
            let webView = TabWebView(frame: CGRectZero, configuration: configuration!)
			// Cliqz: [UIWebView] renamed delegate to tabWebViewDelegate
#if CLIQZ
			webView.tabWebViewDelegate = self
            webView.scrollView.layer.masksToBounds = false
#else
			webView.delegate = self
#endif
            configuration = nil

            webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
            webView.allowsBackForwardNavigationGestures = true
            webView.backgroundColor = UIColor.lightGrayColor()

            // Turning off masking allows the web content to flow outside of the scrollView's frame
            // which allows the content appear beneath the toolbars in the BrowserViewController
            webView.scrollView.layer.masksToBounds = false
            webView.navigationDelegate = navigationDelegate
            webView.webViewDelegate = self
            helperManager = HelperManager(webView: webView)

            restore(webView)

            self.webView = webView
            self.webView?.addObserver(self, forKeyPath: "URL", options: .New, context: nil)
            tabDelegate?.tab?(self, didCreateWebView: webView)
        }
    }

// Cliqz:[UIWebView] Changed type to CliqzWebView
//    func restore(webView: WKWebView) {
	func restore(webView: CliqzWebView) {
        // Pulls restored session data from a previous SavedTab to load into the Tab. If it's nil, a session restore
        // has already been triggered via custom URL, so we use the last request to trigger it again; otherwise,
        // we extract the information needed to restore the tabs and create a NSURLRequest with the custom session restore URL
        // to trigger the session restore via custom handlers
        if let sessionData = self.sessionData {
            restoring = true

            var updatedURLs = [String]()
            for url in sessionData.urls {
                guard let updatedURL = WebServer.sharedInstance.updateLocalURL(url),
                      let urlString = updatedURL.absoluteString else {
                    assertionFailure("Invalid session URL: \(url)")
                    continue
                }
                updatedURLs.append(urlString)
            }

            let currentPage = sessionData.currentPage
            self.sessionData = nil
            var jsonDict = [String: AnyObject]()
            jsonDict["history"] = updatedURLs
            jsonDict["currentPage"] = currentPage
            let escapedJSON = JSON.stringify(jsonDict, pretty: false).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            let restoreURL = NSURL(string: "\(WebServer.sharedInstance.base)/about/sessionrestore?history=\(escapedJSON)")
            lastRequest = PrivilegedRequest(URL: restoreURL!)
            webView.loadRequest(lastRequest!)
        } else if let request = lastRequest {
            webView.loadRequest(request)
        } else {
            log.error("creating webview with no lastRequest and no session data: \(self.url)")
        }
    }

    deinit {
        if let webView = webView {
            tabDelegate?.tab?(self, willDeleteWebView: webView)
            webView.removeObserver(self, forKeyPath: "URL")
        }
    }

    var loading: Bool {
        return webView?.loading ?? false
    }

    var estimatedProgress: Double {
        return webView?.estimatedProgress ?? 0
    }
    
#if CLIQZ
    var backList: [LegacyBackForwardListItem]? {
        return webView?.backForwardList.backList
    }
    
    var forwardList: [LegacyBackForwardListItem]? {
        return webView?.backForwardList.forwardList
    }
    
    var historyList: [NSURL] {
        func listToUrl(item: LegacyBackForwardListItem) -> NSURL { return item.URL }
        var tabs = self.backList?.map(listToUrl) ?? [NSURL]()
        tabs.append(self.url!)
        return tabs
    }
    
#else
    
    var backList: [WKBackForwardListItem]? {
        return webView?.backForwardList.backList
    }
    
    var forwardList: [WKBackForwardListItem]? {
        return webView?.backForwardList.forwardList
    }
    
    var historyList: [NSURL] {
        func listToUrl(item: WKBackForwardListItem) -> NSURL { return item.URL }
        var tabs = self.backList?.map(listToUrl) ?? [NSURL]()
        tabs.append(self.url!)
        return tabs
    }
    
#endif

    var title: String? {
        return webView?.title
    }

    var displayTitle: String {
        if let title = webView?.title {
            if !title.isEmpty {
                return title
            }
        }

        guard let lastTitle = lastTitle where !lastTitle.isEmpty else {
            return displayURL?.absoluteString ??  ""
        }

        return lastTitle
    }

    var currentInitialURL: NSURL? {
        get {
            let initalURL = self.webView?.backForwardList.currentItem?.initialURL
            return initalURL
        }
    }

    var displayFavicon: Favicon? {
        var width = 0
        var largest: Favicon?
        for icon in favicons {
            if icon.width > width {
                width = icon.width!
                largest = icon
            }
        }
        return largest
    }

    var displayURL: NSURL? {
        if let url = url {
            if ReaderModeUtils.isReaderModeURL(url) {
                return ReaderModeUtils.decodeURL(url)
            }
            if isCliqzGoToURL(url) {
                return nil
            }
            if ErrorPageHelper.isErrorPageURL(url) {
                let decodedURL = ErrorPageHelper.originalURLFromQuery(url)
                if !AboutUtils.isAboutURL(decodedURL) {
                    return decodedURL
                } else {
                    return nil
                }
            }

            if let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) where (urlComponents.user != nil) || (urlComponents.password != nil) {
                urlComponents.user = nil
                urlComponents.password = nil
                return urlComponents.URL
            }

            if !AboutUtils.isAboutURL(url) {
                return url
            }
        }
        return nil
    }

    var canGoBack: Bool {
        return webView?.canGoBack ?? false
    }

    var canGoForward: Bool {
        return webView?.canGoForward ?? false
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

#if CLIQZ
    func goToBackForwardListItem(item: LegacyBackForwardListItem) {
        webView?.goToBackForwardListItem(item)
    }
#else
    func goToBackForwardListItem(item: WKBackForwardListItem) {
        webView?.goToBackForwardListItem(item)
    }
#endif
    
    func loadRequest(request: NSURLRequest) -> WKNavigation? {
        if let webView = webView {
            lastRequest = request
#if CLIQZ
        if !AboutUtils.isAboutURL(request.URL) {
            requestInProgress = true
        }
		// Cliqz:[UIWebView] Replaced with fake WKNavigation
		webView.loadRequest(request)
		return DangerousReturnWKNavigation.emptyNav
#else
		return webView.loadRequest(request)
#endif
        }
        return nil
    }

    func stop() {
        webView?.stopLoading()
    }

    func reload() {
        if #available(iOS 9.0, *) {
            let userAgent: String? = desktopSite ? UserAgent.desktopUserAgent() : nil
            if (userAgent ?? "") != webView?.customUserAgent,
               let currentItem = webView?.backForwardList.currentItem
            {
                webView?.customUserAgent = userAgent

                // Reload the initial URL to avoid UA specific redirection
                loadRequest(NSURLRequest(URL: currentItem.initialURL, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 60))
                return
            }
        }

        if let _ = webView?.reloadFromOrigin() {
            log.info("reloaded zombified tab from origin")
            return
        }

        if let webView = self.webView {
            log.info("restoring webView from scratch")
            restore(webView)
        }
    }

    func addHelper(helper: TabHelper, name: String) {
        helperManager!.addHelper(helper, name: name)
    }

    func getHelper(name name: String) -> TabHelper? {
        return helperManager?.getHelper(name: name)
    }

    func hideContent(animated: Bool = false) {
        webView?.userInteractionEnabled = false
        if animated {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.webView?.alpha = 0.0
            })
        } else {
            webView?.alpha = 0.0
        }
    }

    func showContent(animated: Bool = false) {
        webView?.userInteractionEnabled = true
        if animated {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.webView?.alpha = 1.0
            })
        } else {
            webView?.alpha = 1.0
        }
    }

    func addSnackbar(bar: SnackBar) {
        bars.append(bar)
        tabDelegate?.tab(self, didAddSnackbar: bar)
    }

    func removeSnackbar(bar: SnackBar) {
        if let index = bars.indexOf(bar) {
            bars.removeAtIndex(index)
            tabDelegate?.tab(self, didRemoveSnackbar: bar)
        }
    }

    func removeAllSnackbars() {
        // Enumerate backwards here because we'll remove items from the list as we go.
        for i in (0..<bars.count).reverse() {
            let bar = bars[i]
            removeSnackbar(bar)
        }
    }

    func expireSnackbars() {
        // Enumerate backwards here because we may remove items from the list as we go.
        for i in (0..<bars.count).reverse() {
            let bar = bars[i]
            if !bar.shouldPersist(self) {
                removeSnackbar(bar)
            }
        }
    }

    func setScreenshot(screenshot: UIImage?, revUUID: Bool = true) {
        self.screenshot = screenshot
        if revUUID {
            self.screenshotUUID = NSUUID()
        }
    }

    @available(iOS 9, *)
    func toggleDesktopSite() {
        desktopSite = !desktopSite
        reload()
    }

    func queueJavascriptAlertPrompt(alert: JSAlertInfo) {
        alertQueue.append(alert)
    }

    func dequeueJavascriptAlertPrompt() -> JSAlertInfo? {
        guard !alertQueue.isEmpty else {
            return nil
        }
        return alertQueue.removeFirst()
    }

    func cancelQueuedAlerts() {
        alertQueue.forEach { alert in
            alert.cancel()
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
		// Cliqz:[UIWebView] Type change
//		guard let webView = object as? WKWebView where webView == self.webView,
        guard let webView = object as? CliqzWebView where webView == self.webView,
            let path = keyPath where path == "URL" else {
            return assertionFailure("Unhandled KVO key: \(keyPath)")
        }

        updateAppState()
        requestInProgress = false
    }

    func setNoImageMode(enabled: Bool = false, force: Bool) {
        if enabled || force {
            webView?.evaluateJavaScript("__firefox__.setNoImageMode(\(enabled))", completionHandler: nil)
        }
    }

    func setNightMode(enabled: Bool) {
        webView?.evaluateJavaScript("__firefox__.setNightMode(\(enabled))", completionHandler: nil)
    }
}

extension Tab: TabWebViewDelegate {
    private func tabWebView(tabWebView: TabWebView, didSelectFindInPageForSelection selection: String) {
        tabDelegate?.tab(self, didSelectFindInPageForSelection: selection)
    }

}

private class HelperManager: NSObject, WKScriptMessageHandler {
    private var helpers = [String: TabHelper]()
#if CLIQZ
	// Cliqz:[UIWebView] Type change
    private weak var webView: CliqzWebView?
#else
	private weak var webView: WKWebView?
#endif

// Cliqz:[UIWebView] Type change
#if CLIQZ
	init(webView: CliqzWebView) {
		self.webView = webView
	}
#else
	init(webView: WKWebView) {
		self.webView = webView
	}
#endif

    @objc func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        for helper in helpers.values {
            if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
                if scriptMessageHandlerName == message.name {
                    helper.userContentController(userContentController, didReceiveScriptMessage: message)
                    return
                }
            }
        }
    }

    func addHelper(helper: TabHelper, name: String) {
        if let _ = helpers[name] {
            assertionFailure("Duplicate helper added: \(name)")
        }

        helpers[name] = helper

        // If this helper handles script messages, then get the handler name and register it. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
            webView?.configuration.userContentController.addScriptMessageHandler(self, name: scriptMessageHandlerName)
        }
    }

    func getHelper(name name: String) -> TabHelper? {
        return helpers[name]
    }
}

extension Tab: CliqzWebViewDelegate{
    func didFinishLoadingRequest(request: NSURLRequest?) {
        //finished loading request
        self.url = request?.URL
        self.tabDelegate?.urlChangedForTab?(self)
    }
}

private protocol TabWebViewDelegate: class {
    func tabWebView(tabWebView: TabWebView, didSelectFindInPageForSelection selection: String)
}

private class TabWebView: CliqzWebView, MenuHelperInterface {
	// Cliqz: renamed delegate to tab
    private weak var tabWebViewDelegate: TabWebViewDelegate?

    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if action == MenuHelper.SelectorFindInPage {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }

    @objc func menuHelperFindInPage(sender: NSNotification) {
        evaluateJavaScript("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
			// Cliqz renamed delegate
            self.tabWebViewDelegate?.tabWebView(self, didSelectFindInPageForSelection: selection)
        }
    }

    private override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        // The find-in-page selection menu only appears if the webview is the first responder.
        becomeFirstResponder()

        return super.hitTest(point, withEvent: event)
    }
}
