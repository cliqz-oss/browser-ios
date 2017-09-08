//
//  CIBrowserViewController.swift
//  Client
//
//  Created by Tim Palade on 8/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import Shared
import Storage
import Crashlytics

private let KVOLoading = "loading"
private let KVOEstimatedProgress = "estimatedProgress"
private let KVOURL = "URL"
private let KVOCanGoBack = "canGoBack"
private let KVOCanGoForward = "canGoForward"
private let KVOContentSize = "contentSize"

final class CIBrowserViewController: UIViewController {
	
    private let label = UILabel()
	
	var currentResponseStatusCode = 0

	fileprivate let profile: Profile
	fileprivate let tabManager: TabManager

	let lastVisitedWebsiteKey = "lastVisitedWebsite"

	fileprivate var cliqzWebView: CliqzWebView?

	init(profile: Profile, tabManager: TabManager) {
		self.profile = profile
		self.tabManager = tabManager
		super.init(nibName: nil, bundle: nil)
		self.tabManager.addDelegate(self)
		self.tabManager.addNavigationDelegate(self)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.clipsToBounds = true
        // Do any additional setup after loading the view.
        setUpComponent()
        setStyling()
        setConstraints()
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let tab = self.tabManager.selectedTab,
			let view = tab.webView {
			initWebView(view, ofTab: tab)
		}
	}

	func loadURL(_ url: URL?) {
		if let validURL = url,
			let tab = tabManager.selectedTab,
			let _ = tab.loadRequest(PrivilegedRequest(url: validURL) as URLRequest) {
			// TODO: should be reviewed
//				self.recordNavigationInTab(tab, navigation: nav, visitType: .Link)
		} else {
			// TODO: handle exceptional case
		}
	}

    func setUpComponent() {
    }
    
    func setStyling() {
        view.backgroundColor = UIColor.init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    }
    
    func setConstraints() {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		// Cliqz: Replaced forced unwrapping of optional (let webView = object as! CliqzWebView) with a guard check to avoid crashes
		guard let webView = object as? CliqzWebView else { return }
		if webView !== tabManager.selectedTab?.webView {
			return
		}
		guard let path = keyPath else { assertionFailure("Unhandled KVO key: \(keyPath)"); return }
		switch path {
		case KVOEstimatedProgress:
			guard webView == tabManager.selectedTab?.webView,
				let progress = change?[NSKeyValueChangeKey.newKey] as? Float else { break }
			// TODO
//			urlBar.updateProgressBar(progress)
		case KVOLoading:
			guard let loading = change?[NSKeyValueChangeKey.newKey] as? Bool else { break }
			
			if webView == tabManager.selectedTab?.webView {
				// TODO
//				navigationToolbar.updateReloadStatus(loading)
			}
			
			if (!loading) {
				// TODO
//				runScriptsOnWebView(webView)
			}
		case KVOURL:
			// Cliqz: temporary solution, later we should fix subscript and replace with original code
			//            guard let tab = tabManager[webView] else { break }
			guard let tab = tabManager.tabForWebView(webView) else { break }
			// To prevent spoofing, only change the URL immediately if the new URL is on
			// the same origin as the current URL. Otherwise, do nothing and wait for
			// didCommitNavigation to confirm the page load.
			if tab.url?.origin == webView.url?.origin {
				tab.url = webView.url
				
				if tab === tabManager.selectedTab && !tab.restoring {
					updateUIForReaderHomeStateForTab(tab)
				}
			}
		case KVOCanGoBack:
			guard webView == tabManager.selectedTab?.webView,
				let canGoBack = change?[NSKeyValueChangeKey.newKey] as? Bool else { break }
			// TODO
//			navigationToolbar.updateBackStatus(canGoBack)
		case KVOCanGoForward:
			guard webView == tabManager.selectedTab?.webView,
				let canGoForward = change?[NSKeyValueChangeKey.newKey] as? Bool else { break }
			// TODO
//			navigationToolbar.updateForwardStatus(canGoForward)
		default:
			assertionFailure("Unhandled KVO key: \(keyPath)")
		}
	}

}

extension CIBrowserViewController {

	fileprivate func showAntiPhishingAlert(_ domainName: String) {
		let antiPhishingShowTime = Date.getCurrentMillis()
		
		let title = NSLocalizedString("Warning: deceptive website!", tableName: "Cliqz", comment: "Antiphishing alert title")
		let message = NSLocalizedString("CLIQZ has blocked access to %1$ because it has been reported as a phishing website.Phishing websites disguise as other sites you may trust in order to trick you into disclosing your login, password or other sensitive information", tableName: "Cliqz", comment: "Antiphishing alert message")
		let personnalizedMessage = message.replace("%1$", replacement: domainName)
		
		let alert = UIAlertController(title: title, message: personnalizedMessage, preferredStyle: .alert)
		
		let backToSafeSiteButtonTitle = NSLocalizedString("Back to safe site", tableName: "Cliqz", comment: "Back to safe site buttun title in antiphishing alert title")
		alert.addAction(UIAlertAction(title: backToSafeSiteButtonTitle, style: .default, handler: { (action) in
			// go back
			// TOOD: handle go back
//			self.goBack()
			TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("click", "back", nil))
			let duration = Int(Date.getCurrentMillis()-antiPhishingShowTime)
			TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("hide", nil, duration))
		}))
		
		let continueDespiteWarningButtonTitle = NSLocalizedString("Continue despite warning", tableName: "Cliqz", comment: "Continue despite warning buttun title in antiphishing alert title")
		alert.addAction(UIAlertAction(title: continueDespiteWarningButtonTitle, style: .destructive, handler: { (action) in
			TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("click", "continue", nil))
			let duration = Int(Date.getCurrentMillis()-antiPhishingShowTime)
			TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("hide", nil, duration))
		}))
		
		self.present(alert, animated: true, completion: nil)
		TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("show", nil, nil))
	}

	// Recognize a iTunes Store URL. These all trigger the native apps. Note that appstore.com and phobos.apple.com
	// used to be in this list. I have removed them because they now redirect to itunes.apple.com. If we special case
	// them then iOS will actually first open Safari, which then redirects to the app store. This works but it will
	// leave a 'Back to Safari' button in the status bar, which we do not want.
	fileprivate func isStoreURL(_ url: URL) -> Bool {
		if url.scheme == "http" || url.scheme == "https" {
			if url.host == "itunes.apple.com" {
				return true
			}
		}
		return false
	}

	// Recognize an Apple Maps URL. This will trigger the native app. But only if a search query is present. Otherwise
	// it could just be a visit to a regular page on maps.apple.com.
	fileprivate func isAppleMapsURL(_ url: URL) -> Bool {
		if url.scheme == "http" || url.scheme == "https" {
			if url.host == "maps.apple.com" && url.query != nil {
				return true
			}
		}
		return false
	}

	// Mark: User Agent Spoofing
	fileprivate func resetSpoofedUserAgentIfRequired(_ webView: WKWebView, newURL: URL) {
		guard #available(iOS 9.0, *) else {
			return
		}
		
		// Reset the UA when a different domain is being loaded
		if webView.url?.host != newURL.host {
			webView.customUserAgent = nil
		}
	}
	
	fileprivate func restoreSpoofedUserAgentIfRequired(_ webView: WKWebView, newRequest: URLRequest) {
		guard #available(iOS 9.0, *) else {
			return
		}
		
		// Restore any non-default UA from the request's header
		let ua = newRequest.value(forHTTPHeaderField: "User-Agent")
		webView.customUserAgent = ua != UserAgent.defaultUserAgent() ? ua : nil
	}

	// TODO: Review and compare with main method there might be missing antitracking button updating part
	fileprivate func updateUIForReaderHomeStateForTab(_ tab: Tab) {
		// Cliqz: Added gaurd statement to avoid overridding url when search results are displayed
		guard tab.url != nil && !tab.url!.absoluteString.contains("/cliqz/") else {
			return
		}

		if let url = tab.url {
			if ReaderModeUtils.isReaderModeURL(url) {
//				showReaderModeBar(animated: false)
				NotificationCenter.default.addObserver(self, selector: #selector(BrowserViewController.SELDynamicFontChanged(_:)), name: NotificationDynamicFontChanged, object: nil)
			} else {
//				hideReaderModeBar(animated: false)
				NotificationCenter.default.removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
			}
		}
	}

	/// Updates the URL bar text and button states.
	/// Call this whenever the page URL changes.
	fileprivate func updateURLBarDisplayURL(_ tab: Tab) {
		// TODO: update URLbar and Status bar

		Router.shared.action(action: Action(data: ["url": tab.displayURL], type: .urlIsModified, context: .urlBarVC))

//		urlBar.updateTrackersCount((tab.webView?.unsafeRequests)!)
		// Cliqz: update the toolbar only if the search controller is not visible
//		if searchController?.view.isHidden == true {
//			let isPage = tab.displayURL?.isWebPage() ?? false
//			navigationToolbar.updatePageStatus(isPage)
//		}
		
		guard let _ = tab.displayURL?.absoluteString else {
			return
		}
	
		// TODO: move bookmark checking part to seperate method and handle toolbar updating part
//		profile.bookmarks.modelFactory >>== {
//			$0.isBookmarked(url).uponQueue(DispatchQueue.main) { [weak tab] result in
//				guard let bookmarked = result.successValue else {
//					return
//				}
//				tab?.isBookmarked = bookmarked
//				if !AppConstants.MOZ_MENU {
//					///self.navigationToolbar.updateBookmarkStatus(bookmarked)
//				}
//			}
//		}
//		self.toolbar?.updateTabStatus(tab.keepOpen)
//		// ------------------------------------------
//		self.updateReminderButtonState(url_str: url)
//		// ------------------------------------------
	}

	// TODO: Review the logic in original version and would be better to separate for  this controller
	// Cliqz: Logging the Navigation Telemetry signals
	fileprivate func startNavigation(_ webView: WKWebView, navigationAction: WKNavigationAction) {
	}

	// TODO: Review the logic and would be better to separate for  this controller
	// Cliqz: Logging the Navigation Telemetry signals
	fileprivate func finishNavigation(_ webView: CliqzWebView) {
	}

	// Cliqz: Method to store last visited sites
	fileprivate func saveLastVisitedWebSite() {
		if let selectedTab = self.tabManager.selectedTab,
			let lastVisitedWebsite = selectedTab.webView?.url?.absoluteString, selectedTab.isPrivate == false && !lastVisitedWebsite.hasPrefix("http://localhost") {
			LocalDataStore.setObject(lastVisitedWebsite, forKey: self.lastVisitedWebsiteKey)
		}
	}

	fileprivate func postLocationChangeNotificationForTab(_ tab: Tab, navigation: WKNavigation?) {
		let notificationCenter = NotificationCenter.default
		var info = [AnyHashable: Any]()
		info["url"] = tab.displayURL
		info["title"] = tab.title
		if let visitType = self.getVisitTypeForTab(tab, navigation: navigation)?.rawValue {
			info["visitType"] = visitType
		}
		info["isPrivate"] = tab.isPrivate
		notificationCenter.post(name: NotificationOnLocationChange, object: self, userInfo: info)
	}

	fileprivate func getVisitTypeForTab(_ tab: Tab, navigation: WKNavigation?) -> VisitType? {
		guard let navigation = navigation else {
			// See https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/Cocoa/NavigationState.mm#L390
			return VisitType.Link
		}
		
		return VisitType.Link
		// TODO: review if we need to track typedNavigations
//		return self.typedNavigation.removeValue(forKey: navigation) ?? VisitType.Link
	}

	fileprivate func initWebView(_ webView: CliqzWebView, ofTab tab: Tab) {
		// Observers that live as long as the tab. Make sure these are all cleared
		// in willDeleteWebView below!
		self.cliqzWebView = webView
		self.view.addSubview(webView)
		webView.snp.makeConstraints { (make) in
			make.edges.equalToSuperview()
		}
		webView.addObserver(self, forKeyPath: KVOEstimatedProgress, options: .new, context: nil)
		webView.addObserver(self, forKeyPath: KVOLoading, options: .new, context: nil)
		webView.addObserver(self, forKeyPath: KVOCanGoBack, options: .new, context: nil)
		webView.addObserver(self, forKeyPath: KVOCanGoForward, options: .new, context: nil)
		webView.addObserver(self, forKeyPath: KVOURL, options: .new, context: nil)
		
		// TODO: review scrollController
		//		webView.scrollView.addObserver(self.scrollController, forKeyPath: KVOContentSize, options: .new, context: nil)
		
		webView.UIDelegate = self
		
		// TODO: check for missing reader mode logic
		
		let favicons = FaviconManager(tab: tab, profile: profile)
		tab.addHelper(favicons, name: FaviconManager.name())
		
		let errorHelper = ErrorPageHelper()
		tab.addHelper(errorHelper, name: ErrorPageHelper.name())
		
		// TODO: Review helpers logic and enable if neccesary
		if #available(iOS 9, *) {} else {
			//			let windowCloseHelper = WindowCloseHelper(tab: tab)
			//			windowCloseHelper.delegate = self
			//			tab.addHelper(windowCloseHelper, name: WindowCloseHelper.name())
		}
		
		//		let sessionRestoreHelper = SessionRestoreHelper(tab: tab)
		//		sessionRestoreHelper.delegate = self
		//		tab.addHelper(sessionRestoreHelper, name: SessionRestoreHelper.name())
		
		//		let findInPageHelper = FindInPageHelper(tab: tab)
		//		findInPageHelper.delegate = self
		//		tab.addHelper(findInPageHelper, name: FindInPageHelper.name())
		
		//		let printHelper = PrintHelper(tab: tab)
		//		tab.addHelper(printHelper, name: PrintHelper.name())
		
		//		let customSearchHelper = CustomSearchHelper(tab: tab)
		//		tab.addHelper(customSearchHelper, name: CustomSearchHelper.name())
		
		//		tab.addHelper(LocalRequestHelper(), name: LocalRequestHelper.name())
		
		// Cliqz: Add custom user scripts
		//		addCustomUserScripts(tab)
	}
}

extension CIBrowserViewController: TabManagerDelegate {
	
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
		if let wv = previous?.webView {
			wv.endEditing(true)
			wv.accessibilityLabel = nil
			wv.accessibilityElementsHidden = true
			wv.accessibilityIdentifier = nil
			wv.removeFromSuperview()
		}
		if let tab = selected, let webView = tab.webView {
			TelemetryLogger.sharedInstance.updateForgetModeStatue(tab.isPrivate)
			// TODO: Check for readermode logic
			self.view.addSubview(webView)
			webView.snp.makeConstraints { make in
				make.edges.equalToSuperview()
			}
			webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
			webView.accessibilityIdentifier = "contentView"
			webView.accessibilityElementsHidden = false
			// Cliqz: back and forward swipe
			// TODO: integrate swipe logic
//			for swipe in [historySwiper.goBackSwipe, historySwiper.goForwardSwipe] {
//				tab.webView?.scrollView.panGestureRecognizer.require(toFail: swipe)
//			}
			if let url = webView.url?.absoluteString {
				// TODO: integrate missing logic
			} else {
				// The web view can go gray if it was zombified due to memory pressure.
				// When this happens, the URL is nil, so try restoring the page upon selection.
				tab.reload()
			}
		}
    }
	
    func tabManager(_ tabManager: TabManager, didCreateTab tab: Tab) {
		
    }
    
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
		// If we are restoring tabs then we update the count once at the end
		if !tabManager.isRestoring {
//			updateTabCountUsingTabManager(tabManager)
		}
		tab.tabDelegate = self
    }
	
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, removeIndex: Int) {
		if let url = tab.url, !AboutUtils.isAboutURL(tab.url) && !tab.isPrivate {
			self.profile.recentlyClosedTabs.addTab(url, title: tab.title, faviconURL: tab.displayFavicon?.url)
		}
    }
	
    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        
    }
    
    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        
    }
    
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast:ButtonToast?) {
    
    }
}

extension CIBrowserViewController: WKNavigationDelegate {

	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		guard tabManager.selectedTab?.webView == webView else {
			return
		}
		
		// TODO: check if needed
//		updateFindInPageVisibility(visible: false)
		
		// If we are going to navigate to a new page, hide the reader mode button. Unless we
		// are going to a about:reader page. Then we keep it on screen: it will change status
		// (orange color) as soon as the page has loaded.
		if let url = webView.url {
			if !ReaderModeUtils.isReaderModeURL(url) {
				// TODO: check if needed
//				urlBar.updateReaderModeState(ReaderModeState.Unavailable)
//				hideReaderModeBar(animated: false)
			}
		}
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		guard let url = navigationAction.request.url else {
			decisionHandler(WKNavigationActionPolicy.cancel)
			return
		}
		
		// Display AntiPhishing Alert to warn the user of in case of anti-phishing website
		AntiPhishingDetector.isPhishingURL(url) { (isPhishingSite) in
			if isPhishingSite {
				self.showAntiPhishingAlert(url.host!)
			}
		}
		
		// Fixes 1261457 - Rich text editor fails because requests to about:blank are blocked
		if url.scheme == "about" {
			decisionHandler(WKNavigationActionPolicy.allow)
			return
		}
		
		if !navigationAction.isAllowed && navigationAction.navigationType != .backForward {
			decisionHandler(WKNavigationActionPolicy.allow)
			#if BETA
				Answers.logCustomEvent(withName: "UnprivilegedURL", customAttributes: ["URL": url])
			#endif
			return
		}
		
		if url.absoluteString.range(of: "localhost") == nil {
			startNavigation(webView, navigationAction: navigationAction)
		}
		// First special case are some schemes that are about Calling. We prompt the user to confirm this action. This
		// gives us the exact same behaviour as Safari.
		if url.scheme == "tel" || url.scheme == "facetime" || url.scheme == "facetime-audio" {
			if let phoneNumber = url.path.removingPercentEncoding, !phoneNumber.isEmpty {
				let formatter = PhoneNumberFormatter()
				let formattedPhoneNumber = formatter.formatPhoneNumber(phoneNumber)
				let alert = UIAlertController(title: formattedPhoneNumber, message: nil, preferredStyle: UIAlertControllerStyle.alert)
				alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:"Label for Cancel button"), style: UIAlertActionStyle.cancel, handler: nil))
				alert.addAction(UIAlertAction(title: NSLocalizedString("Call", comment:"Alert Call Button"), style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
					UIApplication.shared.openURL(url)
				}))
				present(alert, animated: true, completion: nil)
			}
			decisionHandler(WKNavigationActionPolicy.cancel)
			return
		}
		
		// Second special case are a set of URLs that look like regular http links, but should be handed over to iOS
		// instead of being loaded in the webview. Note that there is no point in calling canOpenURL() here, because
		// iOS will always say yes. TODO Is this the same as isWhitelisted?
		
		if isAppleMapsURL(url) || isStoreURL(url) {
			UIApplication.shared.openURL(url)
			decisionHandler(WKNavigationActionPolicy.cancel)
			return
		}
		
		// This is the normal case, opening a http or https url, which we handle by loading them in this WKWebView. We
		// always allow this.
		
		if url.scheme == "http" || url.scheme == "https" {
			// Cliqz: Added handling for back/forward functionality
			if url.absoluteString.contains("cliqz/goto.html") {
				if let q = url.query {
					let comp = q.components(separatedBy: "=")
					if comp.count == 2 {
						webView.goBack()
						let query = comp[1].removingPercentEncoding!
						// TODO: oper URL
//						self.urlBar.enterOverlayMode(query, pasted: true)
					}
				}
//				self.urlBar.currentURL = nil
				decisionHandler(WKNavigationActionPolicy.allow)
			} else if navigationAction.navigationType == .linkActivated {
				resetSpoofedUserAgentIfRequired(webView, newURL: url)
			} else if navigationAction.navigationType == .backForward {
				restoreSpoofedUserAgentIfRequired(webView, newRequest: navigationAction.request)
			}
			decisionHandler(WKNavigationActionPolicy.allow)
			return
		}

		// Default to calling openURL(). What this does depends on the iOS version. On iOS 8, it will just work without
		// prompting. On iOS9, depending on the scheme, iOS will prompt: "Firefox" wants to open "Twitter". It will ask
		// every time. There is no way around this prompt. (TODO Confirm this is true by adding them to the Info.plist)
		UIApplication.shared.openURL(url)
		decisionHandler(WKNavigationActionPolicy.cancel)
	}

	func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		
		// If this is a certificate challenge, see if the certificate has previously been
		// accepted by the user.
		let origin = "\(challenge.protectionSpace.host):\(challenge.protectionSpace.port)"
		if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
			let trust = challenge.protectionSpace.serverTrust,
			let cert = SecTrustGetCertificateAtIndex(trust, 0), profile.certStore.containsCertificate(cert, forOrigin: origin) {
			completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: trust))
			return
		}
		
		guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
			challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest ||
			challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM,
			let tab = tabManager[webView] else {
				completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
				return
		}
		
		// The challenge may come from a background tab, so ensure it's the one visible.
		tabManager.selectTab(tab)
		
		let loginsHelper = tab.getHelper(LoginsHelper.name()) as? LoginsHelper
		Authenticator.handleAuthRequest(self, challenge: challenge, loginsHelper: loginsHelper).uponQueue(DispatchQueue.main) { res in
			if let credentials = res.successValue {
				completionHandler(.useCredential, credentials.credentials)
			} else {
				completionHandler(URLSession.AuthChallengeDisposition.rejectProtectionSpace, nil)
			}
		}
	}

	func webView(_ _webView: WKWebView, didCommit navigation: WKNavigation!) {
		guard let container = _webView as? ContainerWebView else { return }
		guard let webView = container.legacyWebView else { return }
		guard let tab = tabManager.tabForWebView(webView) else { return }
		
		tab.url = webView.url
		
		if tabManager.selectedTab === tab {
			updateURLBarDisplayURL(tab)
			updateUIForReaderHomeStateForTab(tab)
			// TODO: Check if it's needed
//			appDidUpdateState(getCurrentAppState())
		}
	}

	func webView(_ _webView: WKWebView, didFinish navigation: WKNavigation!) {
		guard let container = _webView as? ContainerWebView else { return }
		guard let webView = container.legacyWebView else { return }
		guard let tab = tabManager.tabForWebView(webView) else { return }

		tabManager.expireSnackbars()
		
		if let url = webView.url, !ErrorPageHelper.isErrorPageURL(url) && !AboutUtils.isAboutHomeURL(url) {
			tab.lastExecutedTime = Date.now()
			

			// Cliqz: prevented adding all 4XX & 5XX urls to local history
			if self.currentResponseStatusCode < 400 {
				postLocationChangeNotificationForTab(tab, navigation: navigation)
			}
			
			// Fire the readability check. This is here and not in the pageShow event handler in ReaderMode.js anymore
			// because that event wil not always fire due to unreliable page caching. This will either let us know that
			// the currently loaded page can be turned into reading mode or if the page already is in reading mode. We
			// ignore the result because we are being called back asynchronous when the readermode status changes.
			webView.evaluateJavaScript("_firefox_ReaderMode.checkReadability()", completionHandler: nil)
		}
		
		if tab === tabManager.selectedTab {
			UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
			// must be followed by LayoutChanged, as ScreenChanged will make VoiceOver
			// cursor land on the correct initial element, but if not followed by LayoutChanged,
			// VoiceOver will sometimes be stuck on the element, not allowing user to move
			// forward/backward. Strange, but LayoutChanged fixes that.
			UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
		}
		
		//Cliqz: Navigation telemetry signal
		if webView.url?.absoluteString.range(of: "localhost") == nil {
			finishNavigation(webView)
		}
		
		// Cliqz: save last visited website for 3D touch action
		saveLastVisitedWebSite()
		
		// Remember whether or not a desktop site was requested
		if #available(iOS 9.0, *) {
			tab.desktopSite = webView.customUserAgent?.isEmpty == false
		}
		
		//Cliqz: store changes of tabs
		if let url = tab.url {
			if !ErrorPageHelper.isErrorPageURL(url) {
				self.tabManager.storeChanges()
			}
		}
	}

	func webView(_ _webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		
		guard let container = _webView as? ContainerWebView else { return }
		guard let webView = container.legacyWebView else { return }
		guard let tab = tabManager.tabForWebView(webView) else { return }
		
		// Ignore the "Frame load interrupted" error that is triggered when we cancel a request
		// to open an external application and hand it over to UIApplication.openURL(). The result
		// will be that we switch to the external app, for example the app store, while keeping the
		// original web page in the tab instead of replacing it with an error page.
		let error = error as NSError
		if error.domain == "WebKitErrorDomain" && error.code == 102 {
			return
		}
		
		if error.code == Int(CFNetworkErrors.cfurlErrorCancelled.rawValue) {
			if tab === tabManager.selectedTab {
				// TODO: redirect to url
//				urlBar.currentURL = tab.displayURL
			}
			return
		}

		if let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
			ErrorPageHelper().showPage(error, forUrl: url, inWebView: webView)
		}
	}
}

extension CIBrowserViewController: TabDelegate {

	func urlChangedForTab(_ tab: Tab) {
		if self.tabManager.selectedTab == tab  && tab.url?.baseDomain() != "localhost" {
			//update the url in the urlbar
//			self.urlBar.currentURL = tab.url
		}
	}

	func tab(_ tab: Tab, didCreateWebView webView: CliqzWebView) {
		self.initWebView(webView, ofTab: tab)
	}
	
	// Cliqz:[UIWebView] Type change
	//    func tab(tab: Tab, willDeleteWebView webView: WKWebView) {
	func tab(_ tab: Tab, willDeleteWebView webView: CliqzWebView) {
		tab.cancelQueuedAlerts()

		webView.removeObserver(self, forKeyPath: KVOEstimatedProgress)
		webView.removeObserver(self, forKeyPath: KVOLoading)
		webView.removeObserver(self, forKeyPath: KVOCanGoBack)
		webView.removeObserver(self, forKeyPath: KVOCanGoForward)
//		webView.scrollView.removeObserver(self.scrollController, forKeyPath: KVOContentSize)
		webView.removeObserver(self, forKeyPath: KVOURL)
		
		webView.UIDelegate = nil
		webView.scrollView.delegate = nil
		webView.removeFromSuperview()
	}

	func tab(_ tab: Tab, didAddSnackbar bar: SnackBar) {
	}
	
	func tab(_ tab: Tab, didRemoveSnackbar bar: SnackBar) {
	}
	
	func tab(_ tab: Tab, didSelectFindInPageForSelection selection: String) {
	}
}

extension CIBrowserViewController: WKUIDelegate {
}

private extension WKNavigationAction {
	/// Allow local requests only if the request is privileged.
	var isAllowed: Bool {
		guard let url = request.url else {
			return true
		}
		return !url.isWebPage() || !url.isLocal || request.isPrivileged
	}
}
