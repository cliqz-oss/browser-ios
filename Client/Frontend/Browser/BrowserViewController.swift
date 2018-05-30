/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Photos
import UIKit
import WebKit
import Shared
import Storage
import SnapKit
import XCGLogger
import Alamofire
import Account
import ReadingList
import MobileCoreServices

private let log = Logger.browserLogger

private let KVOLoading = "loading"
private let KVOEstimatedProgress = "estimatedProgress"
private let KVOURL = "URL"
private let KVOCanGoBack = "canGoBack"
private let KVOCanGoForward = "canGoForward"
private let KVOContentSize = "contentSize"

private let ActionSheetTitleMaxLength = 120

private struct BrowserViewControllerUX {
    private static let BackgroundColor = UIConstants.AppBackgroundColor
    private static let ShowHeaderTapAreaHeight: CGFloat = 32
    private static let BookmarkStarAnimationDuration: Double = 0.5
    private static let BookmarkStarAnimationOffset: CGFloat = 80
}

class BrowserViewController: UIViewController {
    // Cliqz: modifed the type of homePanelController to CliqzSearchViewController to show Cliqz index page instead of FireFox home page
    var homePanelController: CliqzSearchViewController?
//    var homePanelController: HomePanelViewController?
    
    var webViewContainer: UIView!
    var urlBar: URLBarView!
    var readerModeBar: ReaderModeBarView?
    var readerModeCache: ReaderModeCache
    private var statusBarOverlay: UIView!
    private(set) var toolbar: BrowserToolbar?
    //Cliqz: use CliqzSearchViewController instead of FireFox one
    private var searchController: CliqzSearchViewController?
//    private var searchController: SearchViewController?
    private var screenshotHelper: ScreenshotHelper!
    private var homePanelIsInline = false
    private var searchLoader: SearchLoader!
    private let snackBars = UIView()
    private let webViewContainerToolbar = UIView()
    private var findInPageBar: FindInPageBar?
    private let findInPageContainer = UIView()

    // popover rotation handling
    private var displayedPopoverController: UIViewController?
    private var updateDisplayedPopoverProperties: (() -> ())?

    private var openInHelper: OpenInHelper?

    // location label actions
    private var pasteGoAction: AccessibleAction!
    private var pasteAction: AccessibleAction!
    private var copyAddressAction: AccessibleAction!

    private weak var tabTrayController: TabTrayController!

    private let profile: Profile
    let tabManager: TabManager

    // These views wrap the urlbar and toolbar to provide background effects on them
    // Cliqz: Replaced BlurWrapper because according new requirements we don't need to blur background of ULRBar
    var header: UIView!
//    var header: BlurWrapper!
    var headerBackdrop: UIView!
    var footer: UIView!
    var footerBackdrop: UIView!
    private var footerBackground: BlurWrapper?
    private var topTouchArea: UIButton!

    // Backdrop used for displaying greyed background for private tabs
    var webViewContainerBackdrop: UIView!

    private var scrollController = BrowserScrollingController()

    private var keyboardState: KeyboardState?

    let WhiteListedUrls = ["\\/\\/itunes\\.apple\\.com\\/"]

    // Tracking navigation items to record history types.
    // TODO: weak references?
    var ignoredNavigation = Set<WKNavigation>()
    var typedNavigation = [WKNavigation: VisitType]()
    var navigationToolbar: BrowserToolbarProtocol {
        return toolbar ?? urlBar
    }
    // Cliqz: webViewOverlay to cover the wkwebview when navigating from search result
    var webViewOverlay: UIView?
    
    private var needsNewTab = true
    
    private var isAppResponsive = false
    
    // Cliqz: Added TransitionAnimator which is responsible for layers change animations
    let transition = TransitionAnimator()
    
    // Cliqz: Added for logging the navigation Telemetry signal
    var isBackNavigation        : Bool = false
    var backListSize            : Int = 0
    var navigationStep          : Int = 0
    var backNavigationStep      : Int = 0
    var navigationEndTime       : Double = NSDate.getCurrentMillis()
    
    // Cliqz: Added to adjust header constraint to work during the animation to/from past layer
    var headerConstraintUpdated:Bool = false
    
    // Cliqz: Furture and past layers
    
    var searchHistoryContainer: UINavigationController?
    private func initSearchHistoryContainer() {
        let searchHistoryViewController = SearchHistoryViewController(profile: self.profile, tabManager: self.tabManager)
        searchHistoryViewController.delegate = self
        
        searchHistoryContainer = UINavigationController(rootViewController: searchHistoryViewController)
        searchHistoryContainer!.transitioningDelegate = self
    }
    
    lazy var recommendationsContainer: UINavigationController = {
        let recommendationsViewController = RecommendationsViewController(profile: self.profile)
        recommendationsViewController.delegate = self
        recommendationsViewController.tabManager = self.tabManager
        
        let containerViewController = UINavigationController(rootViewController: recommendationsViewController)
        containerViewController.transitioningDelegate = self
        return containerViewController
    }()
    
    // Cliqz: key for storing the last visited website
    let lastVisitedWebsiteKey = "lastVisitedWebsite"
    
    // Cliqz: the response state code of the current opened link
    var currentResponseStatusCode = 0
    
    // Cliqz: Added AdBlocker to detect and block ads
    let adBlocker: AdBlocker

	// Cliqz: Added data member for push notification URL string in the case when the app isn't in background to load URL on viewDidAppear.
	var initialURL: String?
//    var initialURL: String? {
//        didSet {
//            if self.urlBar != nil {
//                self.loadInitialURL()
//            }
//        }
//    }

    init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
        self.readerModeCache = DiskReaderModeCache.sharedInstance
        // Cliqz: Initialized AdBlocker object
        self.adBlocker = AdBlocker(profile: profile)
        super.init(nibName: nil, bundle: nil)
        initSearchHistoryContainer()
        didInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        displayedPopoverController?.dismissViewControllerAnimated(true, completion: nil)

        guard let displayedPopoverController = self.displayedPopoverController else {
            return
        }

        coordinator.animateAlongsideTransition(nil) { context in
            self.updateDisplayedPopoverProperties?()
            self.presentViewController(displayedPopoverController, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.debug("BVC received memory warning")
    }

    private func didInit() {
        screenshotHelper = ScreenshotHelper(controller: self)
        tabManager.addDelegate(self)
        tabManager.addNavigationDelegate(self)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    func shouldShowFooterForTraitCollection(previousTraitCollection: UITraitCollection) -> Bool {
        return previousTraitCollection.verticalSizeClass != .Compact &&
               previousTraitCollection.horizontalSizeClass != .Regular
    }


    func toggleSnackBarVisibility(show show: Bool) {
        if show {
            UIView.animateWithDuration(0.1, animations: { self.snackBars.hidden = false })
        } else {
            snackBars.hidden = true
        }
    }

    private func updateToolbarStateForTraitCollection(newCollection: UITraitCollection) {
        let showToolbar = shouldShowFooterForTraitCollection(newCollection)

        urlBar.setShowToolbar(!showToolbar)
        toolbar?.removeFromSuperview()
        toolbar?.browserToolbarDelegate = nil
        footerBackground?.removeFromSuperview()
        footerBackground = nil
        toolbar = nil

        if showToolbar {
            toolbar = BrowserToolbar()
            toolbar?.browserToolbarDelegate = self
            footerBackground = BlurWrapper(view: toolbar!)
            footerBackground?.translatesAutoresizingMaskIntoConstraints = false

            // Cliqz: Use the same BlurWrapper footer style for both private and normal modes
            /*
            // Need to reset the proper blur style
            if let selectedTab = tabManager.selectedTab where selectedTab.isPrivate {
                footerBackground!.blurStyle = .Dark
            }
            */
            footer.addSubview(footerBackground!)
        }

        view.setNeedsUpdateConstraints()
        if let home = homePanelController {
            home.view.setNeedsUpdateConstraints()
        }

        if let tab = tabManager.selectedTab,
               webView = tab.webView {
            updateURLBarDisplayURL(tab)
            navigationToolbar.updateBackStatus(webView.canGoBack)
            navigationToolbar.updateForwardStatus(webView.canGoForward)
            navigationToolbar.updateReloadStatus(tab.loading ?? false)
        }
    }

    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)

        // During split screen launching on iPad, this callback gets fired before viewDidLoad gets a chance to
        // set things up. Make sure to only update the toolbar state if the view is ready for it.
        if isViewLoaded() {
            updateToolbarStateForTraitCollection(newCollection)
        }

        displayedPopoverController?.dismissViewControllerAnimated(true, completion: nil)

        // WKWebView looks like it has a bug where it doesn't invalidate it's visible area when the user
        // performs a device rotation. Since scrolling calls
        // _updateVisibleContentRects (https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/API/Cocoa/WKWebView.mm#L1430)
        // this method nudges the web view's scroll view by a single pixel to force it to invalidate.
        if let scrollView = self.tabManager.selectedTab?.webView?.scrollView {
            let contentOffset = scrollView.contentOffset
            coordinator.animateAlongsideTransition({ context in
                scrollView.setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y + 1), animated: true)
                self.scrollController.showToolbars(animated: false)
            }, completion: { context in
                scrollView.setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y), animated: false)
            })
        }
    }

    // Cliqz: commented method as is it overriden by us
//    func SELappDidEnterBackgroundNotification() {
//        displayedPopoverController?.dismissViewControllerAnimated(false, completion: nil)
//    }

    func SELtappedTopArea() {
        scrollController.showToolbars(animated: true)
    }

    func SELappWillResignActiveNotification() {
        // If we are displying a private tab, hide any elements in the browser that we wouldn't want shown
        // when the app is in the home switcher
        guard let privateTab = tabManager.selectedTab where privateTab.isPrivate else {
            return
        }

        webViewContainerBackdrop.alpha = 1
        webViewContainer.alpha = 0
        urlBar.locationView.alpha = 0
    }

    func SELappDidBecomeActiveNotification() {
        // Re-show any components that might have been hidden because they were being displayed
        // as part of a private mode tab
        UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.webViewContainer.alpha = 1
            self.urlBar.locationView.alpha = 1
            self.view.backgroundColor = UIColor.clearColor()
        }, completion: { _ in
            self.webViewContainerBackdrop.alpha = 0

            // Cliqz Added functionality for session timeout and telemtery logging when app becomes active
            self.appDidBecomeResponsive("warm")
            
            if self.initialURL != nil {
                // Cliqz: Added call for initial URL if one exists
                self.loadInitialURL()
            } else if SessionState.isSessionExpired() {
                // Cliqz: Added call for reset state in case of session timeout
                self.resetState()
            }
            // Cliqz: ask for news notification permission according to our workflow
            self.askForNewsNotificationPermissionIfNeeded()
        })
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BookmarkStatusChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }

    override func viewDidLoad() {
        log.debug("BVC viewDidLoad…")
        super.viewDidLoad()
        log.debug("BVC super viewDidLoad called.")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BrowserViewController.SELBookmarkStatusDidChange(_:)), name: BookmarkStatusChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BrowserViewController.SELappWillResignActiveNotification), name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BrowserViewController.SELappDidBecomeActiveNotification), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BrowserViewController.SELappDidEnterBackgroundNotification), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        KeyboardHelper.defaultHelper.addDelegate(self)

        log.debug("BVC adding footer and header…")
        footerBackdrop = UIView()
        footerBackdrop.backgroundColor = UIColor.whiteColor()
        view.addSubview(footerBackdrop)
        headerBackdrop = UIView()
        headerBackdrop.backgroundColor = UIColor.whiteColor()
        view.addSubview(headerBackdrop)

        log.debug("BVC setting up webViewContainer…")
        webViewContainerBackdrop = UIView()
        webViewContainerBackdrop.backgroundColor = UIColor.grayColor()
        webViewContainerBackdrop.alpha = 0
        view.addSubview(webViewContainerBackdrop)

        webViewContainer = UIView()
        webViewContainer.addSubview(webViewContainerToolbar)
        view.addSubview(webViewContainer)

        log.debug("BVC setting up status bar…")
        // Temporary work around for covering the non-clipped web view content
        statusBarOverlay = UIView()
        statusBarOverlay.backgroundColor = BrowserViewControllerUX.BackgroundColor
        view.addSubview(statusBarOverlay)

        log.debug("BVC setting up top touch area…")
        topTouchArea = UIButton()
        topTouchArea.isAccessibilityElement = false
        topTouchArea.addTarget(self, action: #selector(BrowserViewController.SELtappedTopArea), forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(topTouchArea)

        log.debug("BVC setting up URL bar…")
        // Setup the URL bar, wrapped in a view to get transparency effect
        urlBar = URLBarView()
        urlBar.translatesAutoresizingMaskIntoConstraints = false
        urlBar.delegate = self
        urlBar.browserToolbarDelegate = self
        // Cliqz: Replaced BlurWrapper because of requirements
        header = urlBar //BlurWrapper(view: urlBar)
        view.addSubview(header)

        // UIAccessibilityCustomAction subclass holding an AccessibleAction instance does not work, thus unable to generate AccessibleActions and UIAccessibilityCustomActions "on-demand" and need to make them "persistent" e.g. by being stored in BVC
        pasteGoAction = AccessibleAction(name: NSLocalizedString("Paste & Go", comment: "Paste the URL into the location bar and visit"), handler: { () -> Bool in
            if let pasteboardContents = UIPasteboard.generalPasteboard().string {
                self.urlBar(self.urlBar, didSubmitText: pasteboardContents)
                return true
            }
            return false
        })
        pasteAction = AccessibleAction(name: NSLocalizedString("Paste", comment: "Paste the URL into the location bar"), handler: { () -> Bool in
            if let pasteboardContents = UIPasteboard.generalPasteboard().string {
                // Enter overlay mode and fire the text entered callback to make the search controller appear.
                self.urlBar.enterOverlayMode(pasteboardContents, pasted: true)
                self.urlBar(self.urlBar, didEnterText: pasteboardContents)
                return true
            }
            return false
        })
        copyAddressAction = AccessibleAction(name: NSLocalizedString("Copy Address", comment: "Copy the URL from the location bar"), handler: { () -> Bool in
            if let url = self.urlBar.currentURL {
                UIPasteboard.generalPasteboard().URL = url
            }
            return true
        })


        log.debug("BVC setting up search loader…")
        searchLoader = SearchLoader(profile: profile, urlBar: urlBar)

        footer = UIView()
        self.view.addSubview(footer)
        self.view.addSubview(snackBars)
        snackBars.backgroundColor = UIColor.clearColor()
        self.view.addSubview(findInPageContainer)

        scrollController.urlBar = urlBar
        scrollController.header = header
        scrollController.footer = footer
        scrollController.snackBars = snackBars

        log.debug("BVC updating toolbar state…")
        self.updateToolbarStateForTraitCollection(self.traitCollection)

        log.debug("BVC setting up constraints…")
        setupConstraints()
        log.debug("BVC done.")

        // Cliqz: start listening for user location changes
        if profile.prefs.intForKey(IntroViewControllerSeenProfileKey) != nil {
            LocationManager.sharedInstance.startUpdateingLocation()
        }
        
    }

    private func setupConstraints() {
        urlBar.snp_makeConstraints { make in
            make.edges.equalTo(self.header)
        }

        header.snp_makeConstraints { make in
            scrollController.headerTopConstraint = make.top.equalTo(snp_topLayoutGuideBottom).constraint
            make.height.equalTo(UIConstants.ToolbarHeight)
            make.left.right.equalTo(self.view)
        }

        headerBackdrop.snp_makeConstraints { make in
            make.edges.equalTo(self.header)
        }

        webViewContainerBackdrop.snp_makeConstraints { make in
            make.edges.equalTo(webViewContainer)
        }

        webViewContainerToolbar.snp_makeConstraints { make in
            make.left.right.top.equalTo(webViewContainer)
            make.height.equalTo(0)
        }
    }

    override func viewDidLayoutSubviews() {
        log.debug("BVC viewDidLayoutSubviews…")
        super.viewDidLayoutSubviews()
        statusBarOverlay.snp_remakeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(self.topLayoutGuide.length)
        }
        
        // Cliqz: fix headerTopConstraint for scrollController to work properly during the animation to/from past layer
        fixHeaderConstraint()
        
        log.debug("BVC done.")
    }

    func loadQueuedTabs() {
        log.debug("Loading queued tabs in the background.")

        // Chain off of a trivial deferred in order to run on the background queue.
        succeed().upon() { res in
            self.dequeueQueuedTabs()
        }
    }

    private func dequeueQueuedTabs() {
        assert(!NSThread.currentThread().isMainThread, "This must be called in the background.")
        self.profile.queue.getQueuedTabs() >>== { cursor in

            // This assumes that the DB returns rows in some kind of sane order.
            // It does in practice, so WFM.
            log.debug("Queue. Count: \(cursor.count).")
            if cursor.count <= 0 {
                return
            }

            let urls = cursor.flatMap { $0?.url.asURL }
            if !urls.isEmpty {
                dispatch_async(dispatch_get_main_queue()) {
                    self.tabManager.addTabsForURLs(urls, zombie: false)
                }
            }

            // Clear *after* making an attempt to open. We're making a bet that
            // it's better to run the risk of perhaps opening twice on a crash,
            // rather than losing data.
            self.profile.queue.clearQueuedTabs()
        }
    }

    override func viewWillAppear(animated: Bool) {
        log.debug("BVC viewWillAppear.")
        super.viewWillAppear(animated)
        log.debug("BVC super.viewWillAppear done.")

        // On iPhone, if we are about to show the On-Boarding, blank out the browser so that it does
        // not flash before we present. This change of alpha also participates in the animation when
        // the intro view is dismissed.
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            self.view.alpha = (profile.prefs.intForKey(IntroViewControllerSeenProfileKey) != nil) ? 1.0 : 0.0
        }

        if activeCrashReporter?.previouslyCrashed ?? false {
            log.debug("Previously crashed.")

            // Reset previous crash state
            activeCrashReporter?.resetPreviousCrashState()
            
            // Cliqz disable calling BreakPad crash reporting
            showRestoreTabsAlert()
            /*
            let optedIntoCrashReporting = profile.prefs.boolForKey("crashreports.send.always")
            if optedIntoCrashReporting == nil {
                // Offer a chance to allow the user to opt into crash reporting
                showCrashOptInAlert()
            } else {
                showRestoreTabsAlert()
            }
            */
        } else {
            // Cliqz: create new tab at start
            if (needsNewTab) {
                self.tabManager.addTabAndSelect()
                needsNewTab = false
            }
            /*
            log.debug("Restoring tabs.")
            tabManager.restoreTabs()
            log.debug("Done restoring tabs.")
            */
        }

        log.debug("Updating tab count.")
        updateTabCountUsingTabManager(tabManager, animated: false)
        log.debug("BVC done.")
    }

    private func showCrashOptInAlert() {
        let alert = UIAlertController.crashOptInAlert(
            sendReportCallback: { _ in
                // Turn on uploading but don't save opt-in flag to profile because this is a one time send.
                configureActiveCrashReporter(true)
                self.showRestoreTabsAlert()
            },
            alwaysSendCallback: { _ in
                self.profile.prefs.setBool(true, forKey: "crashreports.send.always")
                configureActiveCrashReporter(true)
                self.showRestoreTabsAlert()
            },
            dontSendCallback: { _ in
                // no-op: Do nothing if we don't want to send it
                self.showRestoreTabsAlert()
            }
        )
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func showRestoreTabsAlert() {
        guard shouldRestoreTabs() else {
            self.tabManager.addTabAndSelect()
            return
        }

        let alert = UIAlertController.restoreTabsAlert(
            okayCallback: { _ in
                self.tabManager.restoreTabs()
                self.updateTabCountUsingTabManager(self.tabManager, animated: false)
            },
            noCallback: { _ in
                self.tabManager.addTabAndSelect()
                self.updateTabCountUsingTabManager(self.tabManager, animated: false)

                // Cliqz: focus on the search bar when selecting not to restore tabs
                self.urlBar.enterOverlayMode("", pasted: false)
            }
        )

        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func shouldRestoreTabs() -> Bool {
        guard let tabsToRestore = TabManager.tabsToRestore() else { return false }
        let onlyNoHistoryTabs = !tabsToRestore.every { $0.sessionData?.urls.count > 1 || !AboutUtils.isAboutHomeURL($0.sessionData?.urls.first) }
        return !onlyNoHistoryTabs && !DebugSettingsBundleOptions.skipSessionRestore
    }

    override func viewDidAppear(animated: Bool) {
        log.debug("BVC viewDidAppear.")
        // Cliqz: Added if statement not to show overlay mode when Intro is presented. Otherwise it should be shown in Overlay mode.
//        presentIntroViewController()
        if (!presentIntroViewController()) {
            switchToSearchModeIfNeeded()
            // Cliqz: ask for news notification permission according to our workflow
            askForNewsNotificationPermissionIfNeeded()
		}
        log.debug("BVC intro presented.")
        self.webViewContainerToolbar.hidden = false

        screenshotHelper.viewIsVisible = true
        log.debug("BVC taking pending screenshots….")
        screenshotHelper.takePendingScreenshots(tabManager.tabs)
        log.debug("BVC done taking screenshots.")

        log.debug("BVC calling super.viewDidAppear.")
        super.viewDidAppear(animated)
        log.debug("BVC done.")
        
        // Cliqz: cold start finished (for telemetry signals)
        self.appDidBecomeResponsive("cold")

		// Cliqz: Added call for initial URL if one exists
		self.loadInitialURL()

        // Cliqz: Prevent the app from opening a new tab at startup to show whats new in FireFox
        /*
        if shouldShowWhatsNewTab() {
            if let whatsNewURL = SupportUtils.URLForTopic("new-ios-40") {
                self.openURLInNewTab(whatsNewURL)
                profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)
            }
        }
        */

        showQueuedAlertIfAvailable()
    }

    private func shouldShowWhatsNewTab() -> Bool {
        guard let latestMajorAppVersion = profile.prefs.stringForKey(LatestAppVersionProfileKey)?.componentsSeparatedByString(".").first else {
            return DeviceInfo.hasConnectivity()
        }

        return latestMajorAppVersion != AppInfo.majorAppVersion && DeviceInfo.hasConnectivity()
    }

    private func showQueuedAlertIfAvailable() {
        if var queuedAlertInfo = tabManager.selectedTab?.dequeueJavascriptAlertPrompt() {
            let alertController = queuedAlertInfo.alertController()
            alertController.delegate = self
            presentViewController(alertController, animated: true, completion: nil)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        screenshotHelper.viewIsVisible = false

        super.viewWillDisappear(animated)
        
        // Cliqz: preserve search state when dimissing view
        preserveSearchState()
    }

    func resetBrowserChrome() {
        // animate and reset transform for browser chrome
        urlBar.updateAlphaForSubviews(1)

        [header,
            footer,
            readerModeBar,
            footerBackdrop,
            headerBackdrop].forEach { view in
                view?.transform = CGAffineTransformIdentity
        }
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        topTouchArea.snp_remakeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(BrowserViewControllerUX.ShowHeaderTapAreaHeight)
        }

        readerModeBar?.snp_remakeConstraints { make in
            make.top.equalTo(self.header.snp_bottom).constraint
            make.height.equalTo(UIConstants.ToolbarHeight)
            make.leading.trailing.equalTo(self.view)
        }

        webViewContainer.snp_remakeConstraints { make in
            make.left.right.equalTo(self.view)

            if let readerModeBarBottom = readerModeBar?.snp_bottom {
                make.top.equalTo(readerModeBarBottom)
            } else {
                make.top.equalTo(self.header.snp_bottom)
            }

            let findInPageHeight = (findInPageBar == nil) ? 0 : UIConstants.ToolbarHeight
            if let toolbar = self.toolbar {
                make.bottom.equalTo(toolbar.snp_top).offset(-findInPageHeight)
            } else {
                make.bottom.equalTo(self.view).offset(-findInPageHeight)
            }
        }

        // Setup the bottom toolbar
        toolbar?.snp_remakeConstraints { make in
            make.edges.equalTo(self.footerBackground!)
            make.height.equalTo(UIConstants.ToolbarHeight)
        }

        footer.snp_remakeConstraints { make in
            scrollController.footerBottomConstraint = make.bottom.equalTo(self.view.snp_bottom).constraint
            make.top.equalTo(self.snackBars.snp_top)
            make.leading.trailing.equalTo(self.view)
        }

        footerBackdrop.snp_remakeConstraints { make in
            make.edges.equalTo(self.footer)
        }

        updateSnackBarConstraints()
        footerBackground?.snp_remakeConstraints { make in
            make.bottom.left.right.equalTo(self.footer)
            make.height.equalTo(UIConstants.ToolbarHeight)
        }
        urlBar.setNeedsUpdateConstraints()

        // Remake constraints even if we're already showing the home controller.
        // The home controller may change sizes if we tap the URL bar while on about:home.
        homePanelController?.view.snp_remakeConstraints { make in
            make.top.equalTo(self.urlBar.snp_bottom)
            make.left.right.equalTo(self.view)
            if self.homePanelIsInline {
                make.bottom.equalTo(self.toolbar?.snp_top ?? self.view.snp_bottom)
            } else {
                make.bottom.equalTo(self.view.snp_bottom)
            }
        }

        findInPageContainer.snp_remakeConstraints { make in
            make.left.right.equalTo(self.view)

            if let keyboardHeight = keyboardState?.intersectionHeightForView(self.view) where keyboardHeight > 0 {
                make.bottom.equalTo(self.view).offset(-keyboardHeight)
            } else if let toolbar = self.toolbar {
                make.bottom.equalTo(toolbar.snp_top)
            } else {
                make.bottom.equalTo(self.view)
            }
        }
    }
    
    // Cliqz: modifed showHomePanelController to show Cliqz index page (SearchViewController) instead of FireFox home page
    private func showHomePanelController(inline inline: Bool) {
        log.debug("BVC showHomePanelController.")
        homePanelIsInline = inline
        
        if homePanelController == nil {
            homePanelController = CliqzSearchViewController(profile: self.profile)
            homePanelController!.delegate = self
            addChildViewController(homePanelController!)
            view.addSubview(homePanelController!.view)
        }
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.homePanelController!.view.alpha = 1
            }, completion: { finished in
                if finished {
                    self.webViewContainer.accessibilityElementsHidden = true
                    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
                }
        })
        view.setNeedsUpdateConstraints()
        log.debug("BVC done with showHomePanelController.")
        
    }
    /*
    private func showHomePanelController(inline inline: Bool) {
        log.debug("BVC showHomePanelController.")
        homePanelIsInline = inline

        if homePanelController == nil {
            homePanelController = HomePanelViewController()
            homePanelController!.profile = profile
            homePanelController!.delegate = self
            homePanelController!.url = tabManager.selectedTab?.displayURL
            homePanelController!.view.alpha = 0

            addChildViewController(homePanelController!)
            view.addSubview(homePanelController!.view)
            homePanelController!.didMoveToParentViewController(self)
        }

        let panelNumber = tabManager.selectedTab?.url?.fragment

        // splitting this out to see if we can get better crash reports when this has a problem
        var newSelectedButtonIndex = 0
        if let numberArray = panelNumber?.componentsSeparatedByString("=") {
            if let last = numberArray.last, lastInt = Int(last) {
                newSelectedButtonIndex = lastInt
            }
        }
        homePanelController?.selectedButtonIndex = newSelectedButtonIndex

        // We have to run this animation, even if the view is already showing because there may be a hide animation running
        // and we want to be sure to override its results.
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.homePanelController!.view.alpha = 1
        }, completion: { finished in
            if finished {
                self.webViewContainer.accessibilityElementsHidden = true
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            }
        })
        view.setNeedsUpdateConstraints()
        log.debug("BVC done with showHomePanelController.")
    }
    */

    private func hideHomePanelController() {
        if let controller = homePanelController {
            UIView.animateWithDuration(0.2, delay: 0, options: .BeginFromCurrentState, animations: { () -> Void in
                controller.view.alpha = 0
            }, completion: { finished in
                if finished {
                    controller.willMoveToParentViewController(nil)
                    controller.view.removeFromSuperview()
                    controller.removeFromParentViewController()
                    self.homePanelController = nil
                    self.webViewContainer.accessibilityElementsHidden = false
                    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)

                    // Refresh the reading view toolbar since the article record may have changed
                    if let readerMode = self.tabManager.selectedTab?.getHelper(name: ReaderMode.name()) as? ReaderMode where readerMode.state == .Active {
                        self.showReaderModeBar(animated: false)
                    }
                }
            })
        }
    }

    private func updateInContentHomePanel(url: NSURL?) {
        if !urlBar.inOverlayMode {
            // Cliqz: Added check to test if url is nul due to changing the method parameter to urlBar.url instead of selectedTab.url inside urlBarDidLeaveOverlayMode
            if url == nil || AboutUtils.isAboutHomeURL(url){
                showHomePanelController(inline: (tabManager.selectedTab?.canGoForward ?? false || tabManager.selectedTab?.canGoBack ?? false))
            } else {
                hideHomePanelController()
            }
        }
    }
    // Cliqz: modified showSearchController to show SearchViewController insead of searchController
    private func showSearchController() {
        if searchController == nil {
            searchController = CliqzSearchViewController(profile: self.profile)
            searchController!.delegate = self
            if let selectedTab = tabManager.selectedTab {
                searchController?.updatePrivateMode(selectedTab.isPrivate)
            }
            
            searchLoader.addListener(searchController!)
            
            addChildViewController(searchController!)
            view.addSubview(searchController!.view)
            searchController!.view.snp_makeConstraints { make in
                make.top.equalTo(self.urlBar.snp_bottom)
                make.left.right.bottom.equalTo(self.view)
                return
            }
        }
        
        homePanelController?.view?.hidden = true
        searchController!.view.hidden = false
        searchController!.didMoveToParentViewController(self)
        
        // Cliqz: reset navigation steps
        navigationStep = 0
        backNavigationStep = 0
        
    }
    /*
    private func showSearchController() {
        if searchController != nil {
            return
        }

        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        searchController = SearchViewController(isPrivate: isPrivate)
        searchController!.searchEngines = profile.searchEngines
        searchController!.searchDelegate = self
        searchController!.profile = self.profile

        searchLoader.addListener(searchController!)

        addChildViewController(searchController!)
        view.addSubview(searchController!.view)
        searchController!.view.snp_makeConstraints { make in
            make.top.equalTo(self.urlBar.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
            return
        }

        homePanelController?.view?.hidden = true

        searchController!.didMoveToParentViewController(self)
    }
    */
    private func hideSearchController() {
        if let searchController = searchController {
            // Cliqz: Modify hiding the search view controller as our behaviour is different than regular search that was exist
            searchController.view.hidden = true
            homePanelController?.view?.hidden = false

            /*
            searchController.willMoveToParentViewController(nil)
            searchController.view.removeFromSuperview()
            searchController.removeFromParentViewController()
            self.searchController = nil
            homePanelController?.view?.hidden = false
            */
        }
    }

    private func finishEditingAndSubmit(url: NSURL, visitType: VisitType) {
        urlBar.currentURL = url
        urlBar.leaveOverlayMode()

        guard let tab = tabManager.selectedTab else {
            return
        }

        if let webView = tab.webView {
            resetSpoofedUserAgentIfRequired(webView, newURL: url)
        }

        if let nav = tab.loadRequest(PrivilegedRequest(URL: url)) {
            self.recordNavigationInTab(tab, navigation: nav, visitType: visitType)
            
            // Cliqz: add webViewOverlay to the wkwebview to hide the old page while navigating to a new page
            showWebViewOverLay(tab)
        }
    }

    func addBookmark(url: String, title: String?) {
		// Cliqz: replaced ShareItem with CliqzShareItem to extend bookmarks behaviour
		let shareItem = CliqzShareItem(url: url, title: title, favicon: nil, bookmarkedDate: NSDate.now())
//        let shareItem = ShareItem(url: url, title: title, favicon: nil)
        profile.bookmarks.shareItem(shareItem)
        // Cliqz: comented Firefox 3D Touch code
//        if #available(iOS 9, *) {
//            var userData = [QuickActions.TabURLKey: shareItem.url]
//            if let title = shareItem.title {
//                userData[QuickActions.TabTitleKey] = title
//            }
//            QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.OpenLastBookmark,
//                withUserData: userData,
//                toApplication: UIApplication.sharedApplication())
//        }

        // Dispatch to the main thread to update the UI
        dispatch_async(dispatch_get_main_queue()) { _ in
            self.animateBookmarkStar()
            self.toolbar?.updateBookmarkStatus(true)
            self.urlBar.updateBookmarkStatus(true)
        }
    }

    private func animateBookmarkStar() {
        // Cliqz: Removed bookmarkButton
        /*
        let offset: CGFloat
        let button: UIButton!

        if let toolbar: BrowserToolbar = self.toolbar {
            offset = BrowserViewControllerUX.BookmarkStarAnimationOffset * -1
            button = toolbar.bookmarkButton
        } else {
            offset = BrowserViewControllerUX.BookmarkStarAnimationOffset
            button = self.urlBar.bookmarkButton
        }

        let offToolbar = CGAffineTransformMakeTranslation(0, offset)

        UIView.animateWithDuration(BrowserViewControllerUX.BookmarkStarAnimationDuration, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 2.0, options: [], animations: { () -> Void in
            button.transform = offToolbar
            let rotation = CABasicAnimation(keyPath: "transform.rotation")
            rotation.toValue = CGFloat(M_PI * 2.0)
            rotation.cumulative = true
            rotation.duration = BrowserViewControllerUX.BookmarkStarAnimationDuration + 0.075
            rotation.repeatCount = 1.0
            rotation.timingFunction = CAMediaTimingFunction(controlPoints: 0.32, 0.70 ,0.18 ,1.00)
            button.imageView?.layer.addAnimation(rotation, forKey: "rotateStar")
        }, completion: { finished in
            UIView.animateWithDuration(BrowserViewControllerUX.BookmarkStarAnimationDuration, delay: 0.15, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [], animations: { () -> Void in
                button.transform = CGAffineTransformIdentity
            }, completion: nil)
        })
        */
    }

    private func removeBookmark(url: String) {
        profile.bookmarks.modelFactory >>== {
            $0.removeByURL(url).uponQueue(dispatch_get_main_queue()) { res in
                if res.isSuccess {
                    self.toolbar?.updateBookmarkStatus(false)
                    self.urlBar.updateBookmarkStatus(false)
                }
            }
        }
    }

	// Cliqz: Changed bookmarkItem to String, because for Cliqz Bookmarks status change notifications only URL is sent
    func SELBookmarkStatusDidChange(notification: NSNotification) {
        if let bookmarkUrl = notification.object as? String {
            if bookmarkUrl == urlBar.currentURL?.absoluteString {
                if let userInfo = notification.userInfo as? Dictionary<String, Bool>{
                    if let added = userInfo["added"]{
                        self.toolbar?.updateBookmarkStatus(added)
                        self.urlBar.updateBookmarkStatus(added)
                    }
                }
            }
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        if urlBar.inOverlayMode {
            urlBar.SELdidClickCancel()
            return true
        } else if let selectedTab = tabManager.selectedTab where selectedTab.canGoBack {
            selectedTab.goBack()
            return true
        }
        return false
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // Cliqz: Replaced forced unwrapping of optional (let webView = object as! WKWebView) with a guard check to avoid crashes
        guard let webView = object as? WKWebView else { return }
        if webView !== tabManager.selectedTab?.webView {
            return
        }
        guard let path = keyPath else { assertionFailure("Unhandled KVO key: \(keyPath)"); return }
        switch path {
        case KVOEstimatedProgress:
            guard let progress = change?[NSKeyValueChangeNewKey] as? Float else { break }
            urlBar.updateProgressBar(progress)
        case KVOLoading:
            guard let loading = change?[NSKeyValueChangeNewKey] as? Bool else { break }
            toolbar?.updateReloadStatus(loading)
            urlBar.updateReloadStatus(loading)
            if (!loading) {
                runScriptsOnWebView(webView)
            }
        case KVOURL:
            guard let tab = tabManager[webView] else { break }

            // To prevent spoofing, only change the URL immediately if the new URL is on
            // the same origin as the current URL. Otherwise, do nothing and wait for
            // didCommitNavigation to confirm the page load.
            if tab.url?.origin == webView.URL?.origin {
                tab.url = webView.URL
                
                if let tab = tabManager.selectedTab {
                        updateUIForReaderHomeStateForTab(tab)
                }
            }
        case KVOCanGoBack:
            guard let canGoBack = change?[NSKeyValueChangeNewKey] as? Bool else { break }
            navigationToolbar.updateBackStatus(canGoBack)
        case KVOCanGoForward:
            guard let canGoForward = change?[NSKeyValueChangeNewKey] as? Bool else { break }
            navigationToolbar.updateForwardStatus(canGoForward)
        default:
            assertionFailure("Unhandled KVO key: \(keyPath)")
        }
    }

    private func runScriptsOnWebView(webView: WKWebView) {
        webView.evaluateJavaScript("__firefox__.favicons.getFavicons()", completionHandler:nil)
    }
    
    private func updateUIForReaderHomeStateForTab(tab: Browser) {
        
        // Cliqz: Added gaurd statement to avoid overridding url when search results are displayed
        guard self.searchController != nil && self.searchController!.view.hidden && tab.url != nil && !tab.url!.absoluteString.contains("/cliqz/") else {
            return
        }
        
        updateURLBarDisplayURL(tab)
        scrollController.showToolbars(animated: false)

        if let url = tab.url {
            if ReaderModeUtils.isReaderModeURL(url) {
                showReaderModeBar(animated: false)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BrowserViewController.SELDynamicFontChanged(_:)), name: NotificationDynamicFontChanged, object: nil)
            } else {
                hideReaderModeBar(animated: false)
                NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
            }

            updateInContentHomePanel(url)
        }
    }

    private func isWhitelistedUrl(url: NSURL) -> Bool {
        for entry in WhiteListedUrls {
            if let _ = url.absoluteString.rangeOfString(entry, options: .RegularExpressionSearch) {
                return UIApplication.sharedApplication().canOpenURL(url)
            }
        }
        return false
    }

    /// Updates the URL bar text and button states.
    /// Call this whenever the page URL changes.
    private func updateURLBarDisplayURL(tab: Browser) {
        urlBar.currentURL = tab.displayURL

        let isPage = tab.displayURL?.isWebPage() ?? false
        navigationToolbar.updatePageStatus(isWebPage: isPage)

        guard let url = tab.displayURL?.absoluteString else {
            return
        }

        profile.bookmarks.modelFactory >>== {
            $0.isBookmarked(url).uponQueue(dispatch_get_main_queue()) { result in
                guard let bookmarked = result.successValue else {
                    log.error("Error getting bookmark status: \(result.failureValue).")
                    return
                }

                self.navigationToolbar.updateBookmarkStatus(bookmarked)
            }
        }
    }
    // Mark: Opening New Tabs

    @available(iOS 9, *)
    func switchToPrivacyMode(isPrivate isPrivate: Bool ){
        applyTheme(isPrivate ? Theme.PrivateMode : Theme.NormalMode)

        let tabTrayController = self.tabTrayController ?? TabTrayController(tabManager: tabManager, profile: profile, tabTrayDelegate: self)
        if tabTrayController.privateMode != isPrivate {
            tabTrayController.changePrivacyMode(isPrivate)
        }
        self.tabTrayController = tabTrayController
    }

    func switchToTabForURLOrOpen(url: NSURL, isPrivate: Bool = false) {
        // Cliqz: preserve search state for the current tab before switching to the new tab
        preserveSearchState()
        popToBVC()
        if let tab = tabManager.getTabForURL(url) {
            tabManager.selectTab(tab)
        } else {
            openURLInNewTab(url, isPrivate: isPrivate)
        }
    }

    func openURLInNewTab(url: NSURL?, isPrivate: Bool = false) {
        let request: NSURLRequest?
        if let url = url {
            request = NSURLRequest(URL: url)
        } else {
            request = nil
        }
        if #available(iOS 9, *) {
            switchToPrivacyMode(isPrivate: isPrivate)
            tabManager.addTabAndSelect(request, isPrivate: isPrivate)
        } else {
            tabManager.addTabAndSelect(request)
        }
    }

    func openBlankNewTabAndFocus(isPrivate isPrivate: Bool = false) {
        popToBVC()
        openURLInNewTab(nil, isPrivate: isPrivate)
        urlBar.browserLocationViewDidTapLocation(urlBar.locationView)
    }

    private func popToBVC() {
        guard let currentViewController = navigationController?.topViewController else {
                return
        }
        if let presentedViewController = currentViewController.presentedViewController {
            presentedViewController.dismissViewControllerAnimated(false, completion: nil)
        }
        if currentViewController != self {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }

    // Mark: User Agent Spoofing

    private func resetSpoofedUserAgentIfRequired(webView: WKWebView, newURL: NSURL) {
        guard #available(iOS 9.0, *) else {
            return
        }

        // Reset the UA when a different domain is being loaded
        if webView.URL?.host != newURL.host {
            webView.customUserAgent = nil
        }
    }

    private func restoreSpoofedUserAgentIfRequired(webView: WKWebView, newRequest: NSURLRequest) {
        guard #available(iOS 9.0, *) else {
            return
        }

        // Restore any non-default UA from the request's header
        let ua = newRequest.valueForHTTPHeaderField("User-Agent")
        webView.customUserAgent = ua != UserAgent.defaultUserAgent() ? ua : nil
    }

    private func presentActivityViewController(url: NSURL, tab: Browser? = nil, sourceView: UIView?, sourceRect: CGRect, arrowDirection: UIPopoverArrowDirection) {
        var activities = [UIActivity]()

		if (YoutubeVideoDownloader.isYoutubeURL(url)) {
			let youtubeDownloader = YoutubeVideoDownloaderActivity() {
				TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("video_downloader", "click", "target_type", "download_page"))

				self.downloadVideoFromURL(url.absoluteString)
			}
			activities.append(youtubeDownloader)
		}

        let findInPageActivity = FindInPageActivity() { [unowned self] in
            self.updateFindInPageVisibility(visible: true)
        }
        activities.append(findInPageActivity)

        if #available(iOS 9.0, *) {
            if let tab = tab where (tab.getHelper(name: ReaderMode.name()) as? ReaderMode)?.state != .Active {
                let requestDesktopSiteActivity = RequestDesktopSiteActivity(requestMobileSite: tab.desktopSite) { [unowned tab] in
                    tab.toggleDesktopSite()
                }
                activities.append(requestDesktopSiteActivity)
            }
        }

        let helper = ShareExtensionHelper(url: url, tab: tab, activities: activities)

        let controller = helper.createActivityViewController({ [unowned self] completed in
            // After dismissing, check to see if there were any prompts we queued up
            self.showQueuedAlertIfAvailable()

            if completed {
                // We don't know what share action the user has chosen so we simply always
                // update the toolbar and reader mode bar to reflect the latest status.
                if let tab = tab {
                    self.updateURLBarDisplayURL(tab)
                }
                self.updateReaderModeBar()
            }
        })

        let setupPopover = { [unowned self] in
            if let popoverPresentationController = controller.popoverPresentationController {
                popoverPresentationController.sourceView = sourceView
                popoverPresentationController.sourceRect = sourceRect
                popoverPresentationController.permittedArrowDirections = arrowDirection
                popoverPresentationController.delegate = self
            }
        }

        setupPopover()

        if controller.popoverPresentationController != nil {
            displayedPopoverController = controller
            updateDisplayedPopoverProperties = setupPopover
        }

        self.presentViewController(controller, animated: true, completion: nil)
    }

    private func updateFindInPageVisibility(visible visible: Bool) {
        if visible {
            if findInPageBar == nil {
                let findInPageBar = FindInPageBar()
                self.findInPageBar = findInPageBar
                findInPageBar.delegate = self
                findInPageContainer.addSubview(findInPageBar)

                findInPageBar.snp_makeConstraints { make in
                    make.edges.equalTo(findInPageContainer)
                    make.height.equalTo(UIConstants.ToolbarHeight)
                }

                updateViewConstraints()

                // We make the find-in-page bar the first responder below, causing the keyboard delegates
                // to fire. This, in turn, will animate the Find in Page container since we use the same
                // delegate to slide the bar up and down with the keyboard. We don't want to animate the
                // constraints added above, however, so force a layout now to prevent these constraints
                // from being lumped in with the keyboard animation.
                findInPageBar.layoutIfNeeded()
            }

            self.findInPageBar?.becomeFirstResponder()
        } else if let findInPageBar = self.findInPageBar {
            findInPageBar.endEditing(true)
            guard let webView = tabManager.selectedTab?.webView else { return }
            webView.evaluateJavaScript("__firefox__.findDone()", completionHandler: nil)
            findInPageBar.removeFromSuperview()
            self.findInPageBar = nil
            updateViewConstraints()
        }
    }

    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        // Make the web view the first responder so that it can show the selection menu.
        return tabManager.selectedTab?.webView?.becomeFirstResponder() ?? false
    }
}

/**
 * History visit management.
 * TODO: this should be expanded to track various visit types; see Bug 1166084.
 */
extension BrowserViewController {
    func ignoreNavigationInTab(tab: Browser, navigation: WKNavigation) {
        self.ignoredNavigation.insert(navigation)
    }

    func recordNavigationInTab(tab: Browser, navigation: WKNavigation, visitType: VisitType) {
        self.typedNavigation[navigation] = visitType
    }

    /**
     * Untrack and do the right thing.
     */
    func getVisitTypeForTab(tab: Browser, navigation: WKNavigation?) -> VisitType? {
        guard let navigation = navigation else {
            // See https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/Cocoa/NavigationState.mm#L390
            return VisitType.Link
        }

        if let _ = self.ignoredNavigation.remove(navigation) {
            return nil
        }

        return self.typedNavigation.removeValueForKey(navigation) ?? VisitType.Link
    }
}

extension BrowserViewController: URLBarDelegate {

    func urlBarDidPressReload(urlBar: URLBarView) {
        tabManager.selectedTab?.reload()
    }

    func urlBarDidPressStop(urlBar: URLBarView) {
        tabManager.selectedTab?.stop()
    }

    func urlBarDidPressTabs(urlBar: URLBarView) {
        self.webViewContainerToolbar.hidden = true
        updateFindInPageVisibility(visible: false)

        let tabTrayController = TabTrayController(tabManager: tabManager, profile: profile, tabTrayDelegate: self)

        // Cliqz: Take screenshot of search view instead of browser view if tabs button is clicked while search is in progress
        if let tab = tabManager.selectedTab {
            if searchController?.view.hidden == false {
                screenshotHelper.takeScreenshot(tab, searchView: searchController!.view)
            } else {
                screenshotHelper.takeScreenshot(tab)
            }
        }
        /*
        if let tab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(tab)
        }
        */
        self.navigationController?.pushViewController(tabTrayController, animated: true)
        self.tabTrayController = tabTrayController
    }

    func urlBarDidPressReaderMode(urlBar: URLBarView) {
        if let tab = tabManager.selectedTab {
            if let readerMode = tab.getHelper(name: "ReaderMode") as? ReaderMode {
                switch readerMode.state {
                case .Available:
                    enableReaderMode()
                case .Active:
                    disableReaderMode()
                case .Unavailable:
                    break
                }
            }
        }
    }

    func urlBarDidLongPressReaderMode(urlBar: URLBarView) -> Bool {
        guard let tab = tabManager.selectedTab,
               url = tab.displayURL,
               result = profile.readingList?.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.currentDevice().name)
            else {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Could not add page to Reading list", comment: "Accessibility message e.g. spoken by VoiceOver after adding current webpage to the Reading List failed."))
                return false
        }

        switch result {
        case .Success:
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Added page to Reading List", comment: "Accessibility message e.g. spoken by VoiceOver after the current page gets added to the Reading List using the Reader View button, e.g. by long-pressing it or by its accessibility custom action."))
            // TODO: https://bugzilla.mozilla.org/show_bug.cgi?id=1158503 provide some form of 'this has been added' visual feedback?
        case .Failure(let error):
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Could not add page to Reading List. Maybe it's already there?", comment: "Accessibility message e.g. spoken by VoiceOver after the user wanted to add current page to the Reading List and this was not done, likely because it already was in the Reading List, but perhaps also because of real failures."))
            log.error("readingList.createRecordWithURL(url: \"\(url.absoluteString)\", ...) failed with error: \(error)")
        }
        return true
    }

    func locationActionsForURLBar(urlBar: URLBarView) -> [AccessibleAction] {
        if UIPasteboard.generalPasteboard().string != nil {
            return [pasteGoAction, pasteAction, copyAddressAction]
        } else {
            return [copyAddressAction]
        }
    }

    func urlBarDisplayTextForURL(url: NSURL?) -> String? {
        // use the initial value for the URL so we can do proper pattern matching with search URLs
        // Cliqz: return search query to display in the case when search results are visible (added for back/forward feature
        if self.searchController != nil && !self.searchController!.view.hidden {
            return self.searchController!.searchQuery
        }
        
        var searchURL = self.tabManager.selectedTab?.currentInitialURL
        if searchURL == nil || ErrorPageHelper.isErrorPageURL(searchURL!) {
            searchURL = url
        }
        return profile.searchEngines.queryForSearchURL(searchURL) ?? url?.absoluteString
    }

    func urlBarDidLongPressLocation(urlBar: URLBarView) {
        let longPressAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        for action in locationActionsForURLBar(urlBar) {
            longPressAlertController.addAction(action.alertAction(style: .Default))
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel alert view"), style: .Cancel, handler: { (alert: UIAlertAction) -> Void in
        })
        longPressAlertController.addAction(cancelAction)

        let setupPopover = { [unowned self] in
            if let popoverPresentationController = longPressAlertController.popoverPresentationController {
                popoverPresentationController.sourceView = urlBar
                popoverPresentationController.sourceRect = urlBar.frame
                popoverPresentationController.permittedArrowDirections = .Any
                popoverPresentationController.delegate = self
            }
        }

        setupPopover()

        if longPressAlertController.popoverPresentationController != nil {
            displayedPopoverController = longPressAlertController
            updateDisplayedPopoverProperties = setupPopover
        }

        self.presentViewController(longPressAlertController, animated: true, completion: nil)
    }

    func urlBarDidPressScrollToTop(urlBar: URLBarView) {
        if let selectedTab = tabManager.selectedTab {
            // Only scroll to top if we are not showing the home view controller
            if homePanelController == nil {
                selectedTab.webView?.scrollView.setContentOffset(CGPointZero, animated: true)
            }
        }
    }

    func urlBarLocationAccessibilityActions(urlBar: URLBarView) -> [UIAccessibilityCustomAction]? {
        return locationActionsForURLBar(urlBar).map { $0.accessibilityCustomAction }
    }

    func urlBar(urlBar: URLBarView, didEnterText text: String) {
        searchLoader.query = text
        // Cliqz: always show search controller even if query was empty
        showSearchController()
        searchController!.searchQuery = text
        /*
        if text.isEmpty {
            hideSearchController()
        } else {
            showSearchController()
            searchController!.searchQuery = text
        }
        */
    }

    func urlBar(urlBar: URLBarView, didSubmitText text: String) {
        // If we can't make a valid URL, do a search query.
        // If we still don't have a valid URL, something is broken. Give up.
        
        var url = URIFixup.getURL(text)
        
        // If we can't make a valid URL, do a search query.
        if url == nil {
            url = profile.searchEngines.defaultEngine.searchURLForQuery(text)
            if url != nil {
                // Cliqz: Support showing search view with query set when going back from search result
                navigateToUrl(url!, searchQuery: text)
            } else {
                // If we still don't have a valid URL, something is broken. Give up.
                log.error("Error handling URL entry: \"\(text)\".")
            }
        } else {
            finishEditingAndSubmit(url!, visitType: VisitType.Typed)
        }
        
        /*
        guard let url = URIFixup.getURL(text) ??
                        profile.searchEngines.defaultEngine.searchURLForQuery(text) else {
            log.error("Error handling URL entry: \"\(text)\".")
            return
        }
        finishEditingAndSubmit(url!, visitType: VisitType.Typed)
        */
    }

    func urlBarDidEnterOverlayMode(urlBar: URLBarView) {
        // Cliqz: disable showing home panel when entering overlay mode
//        showHomePanelController(inline: false)
    }

    func urlBarDidLeaveOverlayMode(urlBar: URLBarView) {
        hideSearchController()
        // Cliqz: update URL bar when leaving overlay
        if let tab = tabManager.selectedTab {
            updateUIForReaderHomeStateForTab(tab)
        }
		// Cliqz: changed method parameter because there is an inconsistency between urlBar.url and selectedTab.url, especially when the app is opened from push notifications
        updateInContentHomePanel(urlBar.currentURL)
//		updateInContentHomePanel(tabManager.selectedTab?.url)
    }
    
    // Cliqz: Added delegate methods implementation for new bar buttons
    func urlBarDidClickSearchHistory() {
        
        transition.transitionDirection = TransitionDirection.Down
        self.presentViewController(searchHistoryContainer!, animated: true, completion: nil)
        
        TelemetryLogger.sharedInstance.logEvent(.LayerChange("present", "past"))
    }
}

extension BrowserViewController: BrowserToolbarDelegate {
    func browserToolbarDidPressBack(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goBack()
    }

    func browserToolbarDidLongPressBack(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
// See 1159373 - Disable long press back/forward for backforward list
//        let controller = BackForwardListViewController()
//        controller.listData = tabManager.selectedTab?.backList
//        controller.tabManager = tabManager
//        presentViewController(controller, animated: true, completion: nil)
    }

    func browserToolbarDidPressReload(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.reload()
    }

    func browserToolbarDidLongPressReload(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        guard #available(iOS 9.0, *) else {
            return
        }

        guard let tab = tabManager.selectedTab where tab.webView?.URL != nil && (tab.getHelper(name: ReaderMode.name()) as? ReaderMode)?.state != .Active else {
            return
        }

        let toggleActionTitle: String
        if tab.desktopSite {
            toggleActionTitle = NSLocalizedString("Request Mobile Site", comment: "Action Sheet Button for Requesting the Mobile Site")
        } else {
            toggleActionTitle = NSLocalizedString("Request Desktop Site", comment: "Action Sheet Button for Requesting the Desktop Site")
        }

        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        controller.addAction(UIAlertAction(title: toggleActionTitle, style: .Default, handler: { _ in tab.toggleDesktopSite() }))
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:"Action Sheet Cancel Button"), style: .Cancel, handler: nil))
        controller.popoverPresentationController?.sourceView = toolbar ?? urlBar
        controller.popoverPresentationController?.sourceRect = button.frame
        presentViewController(controller, animated: true, completion: nil)
    }

    func browserToolbarDidPressStop(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.stop()
    }

    func browserToolbarDidPressForward(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goForward()
    }

    func browserToolbarDidLongPressForward(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
// See 1159373 - Disable long press back/forward for backforward list
//        let controller = BackForwardListViewController()
//        controller.listData = tabManager.selectedTab?.forwardList
//        controller.tabManager = tabManager
//        presentViewController(controller, animated: true, completion: nil)
    }

    func browserToolbarDidPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton) {

        guard let tab = tabManager.selectedTab,
              let url = tab.displayURL?.absoluteString else {
                log.error("Bookmark error: No tab is selected, or no URL in tab.")
                return
        }

        profile.bookmarks.modelFactory >>== {
            $0.isBookmarked(url) >>== { isBookmarked in
                if isBookmarked {
                    self.removeBookmark(url)
                } else {
                    self.addBookmark(url, title: tab.title)
                }
            }
        }
    }

    func browserToolbarDidLongPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
    }

    func browserToolbarDidPressShare(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        if let tab = tabManager.selectedTab, url = tab.displayURL {
            let sourceView = self.navigationToolbar.shareButton
            presentActivityViewController(url, tab: tab, sourceView: sourceView.superview, sourceRect: sourceView.frame, arrowDirection: .Up)
        }
    }
}

extension BrowserViewController: WindowCloseHelperDelegate {
    func windowCloseHelper(helper: WindowCloseHelper, didRequestToCloseBrowser browser: Browser) {
        tabManager.removeTab(browser)
    }
}

extension BrowserViewController: BrowserDelegate {

    func browser(browser: Browser, didCreateWebView webView: WKWebView) {
        webViewContainer.insertSubview(webView, atIndex: 0)
        webView.snp_makeConstraints { make in
            make.top.equalTo(webViewContainerToolbar.snp_bottom)
            make.left.right.bottom.equalTo(self.webViewContainer)
        }

        // Observers that live as long as the tab. Make sure these are all cleared
        // in willDeleteWebView below!
        webView.addObserver(self, forKeyPath: KVOEstimatedProgress, options: .New, context: nil)
        webView.addObserver(self, forKeyPath: KVOLoading, options: .New, context: nil)
        webView.addObserver(self, forKeyPath: KVOCanGoBack, options: .New, context: nil)
        webView.addObserver(self, forKeyPath: KVOCanGoForward, options: .New, context: nil)
        browser.webView?.addObserver(self, forKeyPath: KVOURL, options: .New, context: nil)

        webView.scrollView.addObserver(self.scrollController, forKeyPath: KVOContentSize, options: .New, context: nil)

        webView.UIDelegate = self

        let readerMode = ReaderMode(browser: browser)
        readerMode.delegate = self
        browser.addHelper(readerMode, name: ReaderMode.name())

        let favicons = FaviconManager(browser: browser, profile: profile)
        browser.addHelper(favicons, name: FaviconManager.name())

        // only add the logins helper if the tab is not a private browsing tab
        if !browser.isPrivate {
            let logins = LoginsHelper(browser: browser, profile: profile)
            browser.addHelper(logins, name: LoginsHelper.name())
        }

        let contextMenuHelper = ContextMenuHelper(browser: browser)
        contextMenuHelper.delegate = self
        browser.addHelper(contextMenuHelper, name: ContextMenuHelper.name())

        let errorHelper = ErrorPageHelper()
        browser.addHelper(errorHelper, name: ErrorPageHelper.name())

        let windowCloseHelper = WindowCloseHelper(browser: browser)
        windowCloseHelper.delegate = self
        browser.addHelper(windowCloseHelper, name: WindowCloseHelper.name())

        let findInPageHelper = FindInPageHelper(browser: browser)
        findInPageHelper.delegate = self
        browser.addHelper(findInPageHelper, name: FindInPageHelper.name())

        let printHelper = PrintHelper(browser: browser)
        browser.addHelper(printHelper, name: PrintHelper.name())

        let openURL = {(url: NSURL) -> Void in
            self.switchToTabForURLOrOpen(url)
        }
        let spotlightHelper = SpotlightHelper(browser: browser, openURL: openURL)
        browser.addHelper(spotlightHelper, name: SpotlightHelper.name())
        browser.addHelper(LocalRequestHelper(), name: LocalRequestHelper.name())

        // Cliqz: Add custom user scripts
        addCustomUserScripts(browser)
    }

    func browser(browser: Browser, willDeleteWebView webView: WKWebView) {
        browser.cancelQueuedAlerts()

        webView.removeObserver(self, forKeyPath: KVOEstimatedProgress)
        webView.removeObserver(self, forKeyPath: KVOLoading)
        webView.removeObserver(self, forKeyPath: KVOCanGoBack)
        webView.removeObserver(self, forKeyPath: KVOCanGoForward)
        webView.scrollView.removeObserver(self.scrollController, forKeyPath: KVOContentSize)
        webView.removeObserver(self, forKeyPath: KVOURL)

        webView.UIDelegate = nil
        webView.scrollView.delegate = nil
        webView.removeFromSuperview()
    }

    private func findSnackbar(barToFind: SnackBar) -> Int? {
        let bars = snackBars.subviews
        for (index, bar) in bars.enumerate() {
            if bar === barToFind {
                return index
            }
        }
        return nil
    }

    private func updateSnackBarConstraints() {
        snackBars.snp_remakeConstraints { make in
            make.bottom.equalTo(findInPageContainer.snp_top)

            let bars = self.snackBars.subviews
            if bars.count > 0 {
                let view = bars[bars.count-1]
                make.top.equalTo(view.snp_top)
            } else {
                make.height.equalTo(0)
            }

            if traitCollection.horizontalSizeClass != .Regular {
                make.leading.trailing.equalTo(self.footer)
                self.snackBars.layer.borderWidth = 0
            } else {
                make.centerX.equalTo(self.footer)
                make.width.equalTo(SnackBarUX.MaxWidth)
                self.snackBars.layer.borderColor = UIConstants.BorderColor.CGColor
                self.snackBars.layer.borderWidth = 1
            }
        }
    }

    // This removes the bar from its superview and updates constraints appropriately
    private func finishRemovingBar(bar: SnackBar) {
        // If there was a bar above this one, we need to remake its constraints.
        if let index = findSnackbar(bar) {
            // If the bar being removed isn't on the top of the list
            let bars = snackBars.subviews
            if index < bars.count-1 {
                // Move the bar above this one
                let nextbar = bars[index+1] as! SnackBar
                nextbar.snp_updateConstraints { make in
                    // If this wasn't the bottom bar, attach to the bar below it
                    if index > 0 {
                        let bar = bars[index-1] as! SnackBar
                        nextbar.bottom = make.bottom.equalTo(bar.snp_top).constraint
                    } else {
                        // Otherwise, we attach it to the bottom of the snackbars
                        nextbar.bottom = make.bottom.equalTo(self.snackBars.snp_bottom).constraint
                    }
                }
            }
        }

        // Really remove the bar
        bar.removeFromSuperview()
    }

    private func finishAddingBar(bar: SnackBar) {
        snackBars.addSubview(bar)
        bar.snp_remakeConstraints { make in
            // If there are already bars showing, add this on top of them
            let bars = self.snackBars.subviews

            // Add the bar on top of the stack
            // We're the new top bar in the stack, so make sure we ignore ourself
            if bars.count > 1 {
                let view = bars[bars.count - 2]
                bar.bottom = make.bottom.equalTo(view.snp_top).offset(0).constraint
            } else {
                bar.bottom = make.bottom.equalTo(self.snackBars.snp_bottom).offset(0).constraint
            }
            make.leading.trailing.equalTo(self.snackBars)
        }
    }

    func showBar(bar: SnackBar, animated: Bool) {
        finishAddingBar(bar)
        updateSnackBarConstraints()

        bar.hide()
        view.layoutIfNeeded()
        UIView.animateWithDuration(animated ? 0.25 : 0, animations: { () -> Void in
            bar.show()
            self.view.layoutIfNeeded()
        })
    }

    func removeBar(bar: SnackBar, animated: Bool) {
        if let _ = findSnackbar(bar) {
            UIView.animateWithDuration(animated ? 0.25 : 0, animations: { () -> Void in
                bar.hide()
                self.view.layoutIfNeeded()
            }) { success in
                // Really remove the bar
                self.finishRemovingBar(bar)
                self.updateSnackBarConstraints()
            }
        }
    }

    func removeAllBars() {
        let bars = snackBars.subviews
        for bar in bars {
            if let bar = bar as? SnackBar {
                bar.removeFromSuperview()
            }
        }
        self.updateSnackBarConstraints()
    }

    func browser(browser: Browser, didAddSnackbar bar: SnackBar) {
        showBar(bar, animated: true)
    }

    func browser(browser: Browser, didRemoveSnackbar bar: SnackBar) {
        removeBar(bar, animated: true)
    }

    func browser(browser: Browser, didSelectFindInPageForSelection selection: String) {
        updateFindInPageVisibility(visible: true)
        findInPageBar?.text = selection
    }
}

extension BrowserViewController: HomePanelViewControllerDelegate {
    func homePanelViewController(homePanelViewController: HomePanelViewController, didSelectURL url: NSURL, visitType: VisitType) {
        finishEditingAndSubmit(url, visitType: visitType)
    }

    func homePanelViewController(homePanelViewController: HomePanelViewController, didSelectPanel panel: Int) {
        if AboutUtils.isAboutHomeURL(tabManager.selectedTab?.url) {
            tabManager.selectedTab?.webView?.evaluateJavaScript("history.replaceState({}, '', '#panel=\(panel)')", completionHandler: nil)
        }
    }

    func homePanelViewControllerDidRequestToCreateAccount(homePanelViewController: HomePanelViewController) {
        presentSignInViewController() // TODO UX Right now the flow for sign in and create account is the same
    }

    func homePanelViewControllerDidRequestToSignIn(homePanelViewController: HomePanelViewController) {
        presentSignInViewController() // TODO UX Right now the flow for sign in and create account is the same
    }
}

extension BrowserViewController: SearchViewControllerDelegate {
    func searchViewController(searchViewController: SearchViewController, didSelectURL url: NSURL) {
        finishEditingAndSubmit(url, visitType: VisitType.Typed)
    }

    func presentSearchSettingsController() {
        let settingsNavigationController = SearchSettingsTableViewController()
        settingsNavigationController.model = self.profile.searchEngines

        let navController = UINavigationController(rootViewController: settingsNavigationController)

        self.presentViewController(navController, animated: true, completion: nil)
    }
}

extension BrowserViewController: TabManagerDelegate {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Browser?, previous: Browser?) {
        // Remove the old accessibilityLabel. Since this webview shouldn't be visible, it doesn't need it
        // and having multiple views with the same label confuses tests.
        if let wv = previous?.webView {
            removeOpenInView()
            wv.endEditing(true)
            wv.accessibilityLabel = nil
            wv.accessibilityElementsHidden = true
            wv.accessibilityIdentifier = nil
            // due to screwy handling within iOS, the scrollToTop handling does not work if there are
            // more than one scroll view in the view hierarchy
            // we therefore have to hide all the scrollViews that we are no actually interesting in interacting with
            // to ensure that scrollsToTop actually works
            wv.scrollView.hidden = true
        }

        if let tab = selected, webView = tab.webView {
            // if we have previously hidden this scrollview in order to make scrollsToTop work then
            // we should ensure that it is not hidden now that it is our foreground scrollView
            if webView.scrollView.hidden {
                webView.scrollView.hidden = false
            }

            updateURLBarDisplayURL(tab)

            if tab.isPrivate {
                readerModeCache = MemoryReaderModeCache.sharedInstance
                applyTheme(Theme.PrivateMode)
            } else {
                readerModeCache = DiskReaderModeCache.sharedInstance
                applyTheme(Theme.NormalMode)
            }
            ReaderModeHandlers.readerModeCache = readerModeCache

            scrollController.browser = selected
            webViewContainer.addSubview(webView)
            webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
            webView.accessibilityIdentifier = "contentView"
            webView.accessibilityElementsHidden = false

            addOpenInViewIfNeccessary(webView.URL)

            if let url = webView.URL?.absoluteString {
                // Don't bother fetching bookmark state for about/sessionrestore and about/home.
                if AboutUtils.isAboutURL(webView.URL) {
                    // Indeed, because we don't show the toolbar at all, don't even blank the star.
                } else {
                    profile.bookmarks.modelFactory >>== {
                        $0.isBookmarked(url).uponQueue(dispatch_get_main_queue()) {
                            guard let isBookmarked = $0.successValue else {
                                log.error("Error getting bookmark status: \($0.failureValue).")
                                return
                            }

                            self.toolbar?.updateBookmarkStatus(isBookmarked)
                            self.urlBar.updateBookmarkStatus(isBookmarked)
                        }
                    }
                }
            } else {
                // The web view can go gray if it was zombified due to memory pressure.
                // When this happens, the URL is nil, so try restoring the page upon selection.
                tab.reload()
            }
            //Cliqz: update private mode in search view to notify JavaScript when switching between normal and private mode
            searchController?.updatePrivateMode(tab.isPrivate)
        }

        if let selected = selected, previous = previous where selected.isPrivate != previous.isPrivate {
            updateTabCountUsingTabManager(tabManager)
        }

        removeAllBars()
        if let bars = selected?.bars {
            for bar in bars {
                showBar(bar, animated: true)
            }
        }

        updateFindInPageVisibility(visible: false)

        navigationToolbar.updateReloadStatus(selected?.loading ?? false)
        navigationToolbar.updateBackStatus(selected?.canGoBack ?? false)
        navigationToolbar.updateForwardStatus(selected?.canGoForward ?? false)
        self.urlBar.updateProgressBar(Float(selected?.estimatedProgress ?? 0))

        if let readerMode = selected?.getHelper(name: ReaderMode.name()) as? ReaderMode {
            urlBar.updateReaderModeState(readerMode.state)
            if readerMode.state == .Active {
                showReaderModeBar(animated: false)
            } else {
                hideReaderModeBar(animated: false)
            }
        } else {
            urlBar.updateReaderModeState(ReaderModeState.Unavailable)
        }

        updateInContentHomePanel(selected?.url)
    }

    func tabManager(tabManager: TabManager, didCreateTab tab: Browser) {
    }

    func tabManager(tabManager: TabManager, didAddTab tab: Browser) {
        // If we are restoring tabs then we update the count once at the end
        if !tabManager.isRestoring {
            updateTabCountUsingTabManager(tabManager)
        }
        tab.browserDelegate = self
    }

    func tabManager(tabManager: TabManager, didRemoveTab tab: Browser) {
        updateTabCountUsingTabManager(tabManager)
        // browserDelegate is a weak ref (and the tab's webView may not be destroyed yet)
        // so we don't expcitly unset it.
    }

    func tabManagerDidAddTabs(tabManager: TabManager) {
        updateTabCountUsingTabManager(tabManager)
    }

    func tabManagerDidRestoreTabs(tabManager: TabManager) {
        updateTabCountUsingTabManager(tabManager)
    }

    private func updateTabCountUsingTabManager(tabManager: TabManager, animated: Bool = true) {
        if let selectedTab = tabManager.selectedTab {
            let count = selectedTab.isPrivate ? tabManager.privateTabs.count : tabManager.normalTabs.count
            urlBar.updateTabCount(max(count, 1), animated: animated)
        }
    }
}

extension BrowserViewController: WKNavigationDelegate {
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if tabManager.selectedTab?.webView !== webView {
            return
        }

        updateFindInPageVisibility(visible: false)

        // If we are going to navigate to a new page, hide the reader mode button. Unless we
        // are going to a about:reader page. Then we keep it on screen: it will change status
        // (orange color) as soon as the page has loaded.
        if let url = webView.URL {
            if !ReaderModeUtils.isReaderModeURL(url) {
                urlBar.updateReaderModeState(ReaderModeState.Unavailable)
                hideReaderModeBar(animated: false)
            }

            // remove the open in overlay view if it is present
            removeOpenInView()
        }
    }
    
    // Recognize an Apple Maps URL. This will trigger the native app. But only if a search query is present. Otherwise
    // it could just be a visit to a regular page on maps.apple.com.
    private func isAppleMapsURL(url: NSURL) -> Bool {
        if url.scheme == "http" || url.scheme == "https" {
            if url.host == "maps.apple.com" && url.query != nil {
                return true
            }
        }
        return false
    }
    
    // Recognize a iTunes Store URL. These all trigger the native apps. Note that appstore.com and phobos.apple.com
    // used to be in this list. I have removed them because they now redirect to itunes.apple.com. If we special case
    // them then iOS will actually first open Safari, which then redirects to the app store. This works but it will
    // leave a 'Back to Safari' button in the status bar, which we do not want.
    private func isStoreURL(url: NSURL) -> Bool {
        if url.scheme == "http" || url.scheme == "https" {
            if url.host == "itunes.apple.com" {
                return true
            }
        }
        return false
    }

    // This is the place where we decide what to do with a new navigation action. There are a number of special schemes
    // and http(s) urls that need to be handled in a different way. All the logic for that is inside this delegate
    // method.

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.URL else {
            decisionHandler(WKNavigationActionPolicy.Cancel)
            return
        }
        // Fixes 1261457 - Rich text editor fails because requests to about:blank are blocked
        if url.scheme == "about" && url.resourceSpecifier == "blank" {
            decisionHandler(WKNavigationActionPolicy.Allow)
            return
        }
        
        if !navigationAction.isAllowed {
            log.warning("Denying unprivileged request: \(navigationAction.request)")
            decisionHandler(WKNavigationActionPolicy.Cancel)
            return
        }
        
        // Cliqz: Check if url is an ad server block it
        if adBlocker.isAdServer(url) {
            decisionHandler(WKNavigationActionPolicy.Cancel)
            return
        }
        
        //Cliqz: Navigation telemetry signal
        if url.absoluteString.rangeOfString("localhost") == nil {
            startNavigation(webView, navigationAction: navigationAction)
        }
        
        // First special case are some schemes that are about Calling. We prompt the user to confirm this action. This
        // gives us the exact same behaviour as Safari. The only thing we do not do is nicely format the phone number,
        // instead we present it as it was put in the URL.
        
        if url.scheme == "tel" || url.scheme == "facetime" || url.scheme == "facetime-audio" {
            if let phoneNumber = url.resourceSpecifier.stringByRemovingPercentEncoding {
                let alert = UIAlertController(title: phoneNumber, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:"Alert Cancel Button"), style: UIAlertActionStyle.Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Call", comment:"Alert Call Button"), style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
                    UIApplication.sharedApplication().openURL(url)
                }))
                presentViewController(alert, animated: true, completion: nil)
            }
            decisionHandler(WKNavigationActionPolicy.Cancel)
            return
        }
        
        // Second special case are a set of URLs that look like regular http links, but should be handed over to iOS
        // instead of being loaded in the webview. Note that there is no point in calling canOpenURL() here, because
        // iOS will always say yes. TODO Is this the same as isWhitelisted?
        
        if isAppleMapsURL(url) || isStoreURL(url) {
            UIApplication.sharedApplication().openURL(url)
            decisionHandler(WKNavigationActionPolicy.Cancel)
            return
        }
        
        // This is the normal case, opening a http or https url, which we handle by loading them in this WKWebView. We
        // always allow this.

        if url.scheme == "http" || url.scheme == "https" {
            print(url.absoluteString)
            // Cliqz: Added handling for back/forward functionality
            if url.absoluteString.contains("cliqz/goto.html") {
                if let q = url.query {
                    let comp = q.componentsSeparatedByString("=")
                    if comp.count == 2 {
                        webView.goBack()
                        let query = comp[1].stringByRemovingPercentEncoding!
                        self.urlBar.locationView.urlTextField.text = query
                        self.urlBar(self.urlBar, didEnterText: query)
                    }
                }
                decisionHandler(WKNavigationActionPolicy.Cancel)
            } else if navigationAction.navigationType == .LinkActivated {
                resetSpoofedUserAgentIfRequired(webView, newURL: url)
            } else if navigationAction.navigationType == .BackForward {
                restoreSpoofedUserAgentIfRequired(webView, newRequest: navigationAction.request)
            }
            decisionHandler(WKNavigationActionPolicy.Allow)
            return
        }
        
        // Default to calling openURL(). What this does depends on the iOS version. On iOS 8, it will just work without
        // prompting. On iOS9, depending on the scheme, iOS will prompt: "Firefox" wants to open "Twitter". It will ask
        // every time. There is no way around this prompt. (TODO Confirm this is true by adding them to the Info.plist)
        
        UIApplication.sharedApplication().openURL(url)
        decisionHandler(WKNavigationActionPolicy.Cancel)
    }

    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

        // If this is a certificate challenge, see if the certificate has previously been
        // accepted by the user.
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust,
           let cert = SecTrustGetCertificateAtIndex(trust, 0) where profile.certStore.containsCertificate(cert) {
            completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: trust))
            return
        }

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest ||
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM,
              let tab = tabManager[webView] else {
            completionHandler(NSURLSessionAuthChallengeDisposition.PerformDefaultHandling, nil)
            return
        }

        // The challenge may come from a background tab, so ensure it's the one visible.
        tabManager.selectTab(tab)

        let loginsHelper = tab.getHelper(name: LoginsHelper.name()) as? LoginsHelper
        Authenticator.handleAuthRequest(self, challenge: challenge, loginsHelper: loginsHelper).uponQueue(dispatch_get_main_queue()) { res in
            if let credentials = res.successValue {
                completionHandler(.UseCredential, credentials.credentials)
            } else {
                completionHandler(NSURLSessionAuthChallengeDisposition.RejectProtectionSpace, nil)
            }
        }
    }

    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        guard let tab = tabManager[webView] else { return }

        tab.url = webView.URL

        if tabManager.selectedTab === tab {
            updateUIForReaderHomeStateForTab(tab)
        }
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        let tab: Browser! = tabManager[webView]
        tabManager.expireSnackbars()

        if let url = webView.URL where !ErrorPageHelper.isErrorPageURL(url) && !AboutUtils.isAboutHomeURL(url) {
            tab.lastExecutedTime = NSDate.now()

            if navigation == nil {
                log.warning("Implicitly unwrapped optional navigation was nil.")
            }
            // Cliqz: prevented adding all 4XX & 5XX urls to local history
//            postLocationChangeNotificationForTab(tab, navigation: navigation)
            if currentResponseStatusCode < 400 {
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
        } else {
            screenshotHelper.takeDelayedScreenshot(tab)
        }

        addOpenInViewIfNeccessary(webView.URL)

        // Cliqz: hide the webViewOverlay when finis navigating to a url
        hideWebViewOverlay()

        //Cliqz: Navigation telemetry signal
        if webView.URL?.absoluteString.rangeOfString("localhost") == nil {
            finishNavigation(webView)
        }

        // Cliqz: save last visited website for 3D touch action
        saveLastVisitedWebSite()
        
        // Remember whether or not a desktop site was requested
        if #available(iOS 9.0, *) {
            tab.desktopSite = webView.customUserAgent?.isEmpty == false
        }
    }

    private func addOpenInViewIfNeccessary(url: NSURL?) {
        guard let url = url, let openInHelper = OpenInHelperFactory.helperForURL(url) else { return }
        let view = openInHelper.openInView
        webViewContainerToolbar.addSubview(view)
        webViewContainerToolbar.snp_updateConstraints { make in
            make.height.equalTo(OpenInViewUX.ViewHeight)
        }
        view.snp_makeConstraints { make in
            make.edges.equalTo(webViewContainerToolbar)
        }

        self.openInHelper = openInHelper
    }

    private func removeOpenInView() {
        guard let _ = self.openInHelper else { return }
        webViewContainerToolbar.subviews.forEach { $0.removeFromSuperview() }

        webViewContainerToolbar.snp_updateConstraints { make in
            make.height.equalTo(0)
        }

        self.openInHelper = nil
    }

    private func postLocationChangeNotificationForTab(tab: Browser, navigation: WKNavigation?) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        var info = [NSObject: AnyObject]()
        info["url"] = tab.displayURL
        info["title"] = tab.title
        if let visitType = self.getVisitTypeForTab(tab, navigation: navigation)?.rawValue {
            info["visitType"] = visitType
        }
        info["isPrivate"] = tab.isPrivate
        notificationCenter.postNotificationName(NotificationOnLocationChange, object: self, userInfo: info)
    }
}

/// List of schemes that are allowed to open a popup window
private let SchemesAllowedToOpenPopups = ["http", "https", "javascript", "data"]

extension BrowserViewController: WKUIDelegate {
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let currentTab = tabManager.selectedTab else { return nil }

        if !navigationAction.isAllowed {
            log.warning("Denying unprivileged request: \(navigationAction.request)")
            return nil
        }

        screenshotHelper.takeScreenshot(currentTab)

        // If the page uses window.open() or target="_blank", open the page in a new tab.
        // TODO: This doesn't work for window.open() without user action (bug 1124942).
        let newTab: Browser
        if #available(iOS 9, *) {
            newTab = tabManager.addTab(navigationAction.request, configuration: configuration, isPrivate: currentTab.isPrivate)
        } else {
            newTab = tabManager.addTab(navigationAction.request, configuration: configuration)
        }

        // Cliqz: preserve search state before switching to the newly created tab
        preserveSearchState()
        
        tabManager.selectTab(newTab)
        
        // If the page we just opened has a bad scheme, we return nil here so that JavaScript does not
        // get a reference to it which it can return from window.open() - this will end up as a
        // CFErrorHTTPBadURL being presented.
        guard let scheme = navigationAction.request.URL?.scheme.lowercaseString where SchemesAllowedToOpenPopups.contains(scheme) else {
            return nil
        }
        
        return newTab.webView
    }

    private func canDisplayJSAlertForWebView(webView: WKWebView) -> Bool {
        // Only display a JS Alert if we are selected and there isn't anything being shown
        return (tabManager.selectedTab?.webView == webView ?? false) && (self.presentedViewController == nil)
    }

    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        var messageAlert = MessageAlert(message: message, frame: frame, completionHandler: completionHandler)
        if canDisplayJSAlertForWebView(webView) {
            presentViewController(messageAlert.alertController(), animated: true, completion: nil)
        } else if let promptingTab = tabManager[webView] {
            promptingTab.queueJavascriptAlertPrompt(messageAlert)
        } else {
            // This should never happen since an alert needs to come from a web view but just in case call the handler
            // since not calling it will result in a runtime exception.
            completionHandler()
        }
    }

    func webView(webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (Bool) -> Void) {
        var confirmAlert = ConfirmPanelAlert(message: message, frame: frame, completionHandler: completionHandler)
        if canDisplayJSAlertForWebView(webView) {
            presentViewController(confirmAlert.alertController(), animated: true, completion: nil)
        } else if let promptingTab = tabManager[webView] {
            promptingTab.queueJavascriptAlertPrompt(confirmAlert)
        } else {
            completionHandler(false)
        }
    }

    func webView(webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String?) -> Void) {
        var textInputAlert = TextInputAlert(message: prompt, frame: frame, completionHandler: completionHandler, defaultText: defaultText)
        if canDisplayJSAlertForWebView(webView) {
            presentViewController(textInputAlert.alertController(), animated: true, completion: nil)
        } else if let promptingTab = tabManager[webView] {
            promptingTab.queueJavascriptAlertPrompt(textInputAlert)
        } else {
            completionHandler(nil)
        }
    }

    /// Invoked when an error occurs while starting to load data for the main frame.
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        // Ignore the "Frame load interrupted" error that is triggered when we cancel a request
        // to open an external application and hand it over to UIApplication.openURL(). The result
        // will be that we switch to the external app, for example the app store, while keeping the
        // original web page in the tab instead of replacing it with an error page.
        if error.domain == "WebKitErrorDomain" && error.code == 102 {
            return
        }

        if checkIfWebContentProcessHasCrashed(webView, error: error) {
            return
        }

        if error.code == Int(CFNetworkErrors.CFURLErrorCancelled.rawValue) {
            if let browser = tabManager[webView] where browser === tabManager.selectedTab {
                urlBar.currentURL = browser.displayURL
            }
            return
        }

        if let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? NSURL {
            ErrorPageHelper().showPage(error, forUrl: url, inWebView: webView)
        }
    }

    private func checkIfWebContentProcessHasCrashed(webView: WKWebView, error: NSError) -> Bool {
        if error.code == WKErrorCode.WebContentProcessTerminated.rawValue && error.domain == "WebKitErrorDomain" {
            log.debug("WebContent process has crashed. Trying to reloadFromOrigin to restart it.")
            webView.reloadFromOrigin()
            return true
        }

        return false
    }

    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        // Cliqz: get the response code of the current response from the navigationResponse
        if let response = navigationResponse.response as? NSHTTPURLResponse {
            currentResponseStatusCode = response.statusCode
        }
        
        // Cliqz: hide overlay after webview delay as some links does not call didFinishNavigation
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.hideWebViewOverlay()
        }
        
        if navigationResponse.canShowMIMEType {
            decisionHandler(WKNavigationResponsePolicy.Allow)
            return
        }

        let error = NSError(domain: ErrorPageHelper.MozDomain, code: Int(ErrorPageHelper.MozErrorDownloadsNotEnabled), userInfo: [NSLocalizedDescriptionKey: "Downloads aren't supported in CLIQZ yet (but we're working on it)."])
        ErrorPageHelper().showPage(error, forUrl: navigationResponse.response.URL!, inWebView: webView)
        decisionHandler(WKNavigationResponsePolicy.Allow)
    }
}

extension BrowserViewController: ReaderModeDelegate {
    func readerMode(readerMode: ReaderMode, didChangeReaderModeState state: ReaderModeState, forBrowser browser: Browser) {
        // If this reader mode availability state change is for the tab that we currently show, then update
        // the button. Otherwise do nothing and the button will be updated when the tab is made active.
        if tabManager.selectedTab === browser {
            urlBar.updateReaderModeState(state)
        }
    }

    func readerMode(readerMode: ReaderMode, didDisplayReaderizedContentForBrowser browser: Browser) {
        self.showReaderModeBar(animated: true)
        browser.showContent(true)
    }

    // Returning None here makes sure that the Popover is actually presented as a Popover and
    // not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension BrowserViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        displayedPopoverController = nil
        updateDisplayedPopoverProperties = nil
    }
}

// MARK: - ReaderModeStyleViewControllerDelegate

extension BrowserViewController: ReaderModeStyleViewControllerDelegate {
    func readerModeStyleViewController(readerModeStyleViewController: ReaderModeStyleViewController, didConfigureStyle style: ReaderModeStyle) {
        // Persist the new style to the profile
        let encodedStyle: [String:AnyObject] = style.encode()
        profile.prefs.setObject(encodedStyle, forKey: ReaderModeProfileKeyStyle)
        // Change the reader mode style on all tabs that have reader mode active
        for tabIndex in 0..<tabManager.count {
            if let tab = tabManager[tabIndex] {
                if let readerMode = tab.getHelper(name: "ReaderMode") as? ReaderMode {
                    if readerMode.state == ReaderModeState.Active {
                        readerMode.style = style
                    }
                }
            }
        }
    }
}

extension BrowserViewController {
    func updateReaderModeBar() {
        if let readerModeBar = readerModeBar {
            if let tab = self.tabManager.selectedTab where tab.isPrivate {
                readerModeBar.applyTheme(Theme.PrivateMode)
            } else {
                readerModeBar.applyTheme(Theme.NormalMode)
            }
            if let url = self.tabManager.selectedTab?.displayURL?.absoluteString, result = profile.readingList?.getRecordWithURL(url) {
                if let successValue = result.successValue, record = successValue {
                    readerModeBar.unread = record.unread
                    readerModeBar.added = true
                } else {
                    readerModeBar.unread = true
                    readerModeBar.added = false
                }
            } else {
                readerModeBar.unread = true
                readerModeBar.added = false
            }
        }
    }

    func showReaderModeBar(animated animated: Bool) {
        if self.readerModeBar == nil {
            let readerModeBar = ReaderModeBarView(frame: CGRectZero)
            readerModeBar.delegate = self
            view.insertSubview(readerModeBar, belowSubview: header)
            self.readerModeBar = readerModeBar
        }

        updateReaderModeBar()

        self.updateViewConstraints()
    }

    func hideReaderModeBar(animated animated: Bool) {
        if let readerModeBar = self.readerModeBar {
            readerModeBar.removeFromSuperview()
            self.readerModeBar = nil
            self.updateViewConstraints()
        }
    }

    /// There are two ways we can enable reader mode. In the simplest case we open a URL to our internal reader mode
    /// and be done with it. In the more complicated case, reader mode was already open for this page and we simply
    /// navigated away from it. So we look to the left and right in the BackForwardList to see if a readerized version
    /// of the current page is there. And if so, we go there.

    func enableReaderMode() {
        guard let tab = tabManager.selectedTab, webView = tab.webView else { return }

        let backList = webView.backForwardList.backList
        let forwardList = webView.backForwardList.forwardList

        guard let currentURL = webView.backForwardList.currentItem?.URL, let readerModeURL = ReaderModeUtils.encodeURL(currentURL) else { return }

        if backList.count > 1 && backList.last?.URL == readerModeURL {
            webView.goToBackForwardListItem(backList.last!)
        } else if forwardList.count > 0 && forwardList.first?.URL == readerModeURL {
            webView.goToBackForwardListItem(forwardList.first!)
        } else {
            // Store the readability result in the cache and load it. This will later move to the ReadabilityHelper.
            webView.evaluateJavaScript("\(ReaderModeNamespace).readerize()", completionHandler: { (object, error) -> Void in
                if let readabilityResult = ReadabilityResult(object: object) {
                    do {
                        try self.readerModeCache.put(currentURL, readabilityResult)
                    } catch _ {
                    }
                    if let nav = webView.loadRequest(PrivilegedRequest(URL: readerModeURL)) {
                        self.ignoreNavigationInTab(tab, navigation: nav)
                    }
                }
            })
        }
    }

    /// Disabling reader mode can mean two things. In the simplest case we were opened from the reading list, which
    /// means that there is nothing in the BackForwardList except the internal url for the reader mode page. In that
    /// case we simply open a new page with the original url. In the more complicated page, the non-readerized version
    /// of the page is either to the left or right in the BackForwardList. If that is the case, we navigate there.

    func disableReaderMode() {
        if let tab = tabManager.selectedTab,
            let webView = tab.webView {
            let backList = webView.backForwardList.backList
            let forwardList = webView.backForwardList.forwardList

            if let currentURL = webView.backForwardList.currentItem?.URL {
                if let originalURL = ReaderModeUtils.decodeURL(currentURL) {
                    if backList.count > 1 && backList.last?.URL == originalURL {
                        webView.goToBackForwardListItem(backList.last!)
                    } else if forwardList.count > 0 && forwardList.first?.URL == originalURL {
                        webView.goToBackForwardListItem(forwardList.first!)
                    } else {
                        if let nav = webView.loadRequest(NSURLRequest(URL: originalURL)) {
                            self.ignoreNavigationInTab(tab, navigation: nav)
                        }
                    }
                }
            }
        }
    }

    func SELDynamicFontChanged(notification: NSNotification) {
        guard notification.name == NotificationDynamicFontChanged else { return }

        var readerModeStyle = DefaultReaderModeStyle
        if let dict = profile.prefs.dictionaryForKey(ReaderModeProfileKeyStyle) {
            if let style = ReaderModeStyle(dict: dict) {
                readerModeStyle = style
            }
        }
        readerModeStyle.fontSize = ReaderModeFontSize.defaultSize
        self.readerModeStyleViewController(ReaderModeStyleViewController(), didConfigureStyle: readerModeStyle)
    }
}

extension BrowserViewController: ReaderModeBarViewDelegate {
    func readerModeBar(readerModeBar: ReaderModeBarView, didSelectButton buttonType: ReaderModeBarButtonType) {
        switch buttonType {
        case .Settings:
            if let readerMode = tabManager.selectedTab?.getHelper(name: "ReaderMode") as? ReaderMode where readerMode.state == ReaderModeState.Active {
                var readerModeStyle = DefaultReaderModeStyle
                if let dict = profile.prefs.dictionaryForKey(ReaderModeProfileKeyStyle) {
                    if let style = ReaderModeStyle(dict: dict) {
                        readerModeStyle = style
                    }
                }

                let readerModeStyleViewController = ReaderModeStyleViewController()
                readerModeStyleViewController.delegate = self
                readerModeStyleViewController.readerModeStyle = readerModeStyle
                readerModeStyleViewController.modalPresentationStyle = UIModalPresentationStyle.Popover

                let setupPopover = { [unowned self] in
                    if let popoverPresentationController = readerModeStyleViewController.popoverPresentationController {
                        popoverPresentationController.backgroundColor = UIColor.whiteColor()
                        popoverPresentationController.delegate = self
                        popoverPresentationController.sourceView = readerModeBar
                        popoverPresentationController.sourceRect = CGRect(x: readerModeBar.frame.width/2, y: UIConstants.ToolbarHeight, width: 1, height: 1)
                        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection.Up
                    }
                }

                setupPopover()

                if readerModeStyleViewController.popoverPresentationController != nil {
                    displayedPopoverController = readerModeStyleViewController
                    updateDisplayedPopoverProperties = setupPopover
                }

                self.presentViewController(readerModeStyleViewController, animated: true, completion: nil)
            }

        case .MarkAsRead:
            if let url = self.tabManager.selectedTab?.displayURL?.absoluteString, result = profile.readingList?.getRecordWithURL(url) {
                if let successValue = result.successValue, record = successValue {
                    profile.readingList?.updateRecord(record, unread: false) // TODO Check result, can this fail?
                    readerModeBar.unread = false
                }
            }

        case .MarkAsUnread:
            if let url = self.tabManager.selectedTab?.displayURL?.absoluteString, result = profile.readingList?.getRecordWithURL(url) {
                if let successValue = result.successValue, record = successValue {
                    profile.readingList?.updateRecord(record, unread: true) // TODO Check result, can this fail?
                    readerModeBar.unread = true
                }
            }

        case .AddToReadingList:
            if let tab = tabManager.selectedTab,
               let url = tab.url where ReaderModeUtils.isReaderModeURL(url) {
                if let url = ReaderModeUtils.decodeURL(url) {
                    profile.readingList?.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.currentDevice().name) // TODO Check result, can this fail?
                    readerModeBar.added = true
                    readerModeBar.unread = true
                }
            }

        case .RemoveFromReadingList:
            if let url = self.tabManager.selectedTab?.displayURL?.absoluteString, result = profile.readingList?.getRecordWithURL(url) {
                if let successValue = result.successValue, record = successValue {
                    profile.readingList?.deleteRecord(record) // TODO Check result, can this fail?
                    readerModeBar.added = false
                    readerModeBar.unread = false
                }
            }
        }
    }
}

extension BrowserViewController: IntroViewControllerDelegate {
    func presentIntroViewController(force: Bool = false) -> Bool{
        if force || profile.prefs.intForKey(IntroViewControllerSeenProfileKey) == nil {
            let introViewController = IntroViewController()
            introViewController.delegate = self
            // On iPad we present it modally in a controller
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                introViewController.preferredContentSize = CGSize(width: IntroViewControllerUX.Width, height: IntroViewControllerUX.Height)
                introViewController.modalPresentationStyle = UIModalPresentationStyle.FormSheet
            }
            // Cliqz: if there is a ViewController already presented, dismiss it first before presenting the IntroView
            if let presentedViewController = self.presentedViewController {
                presentedViewController.dismissViewControllerAnimated(false, completion: {
                    self.presentViewController(introViewController, animated: true) {
                        self.profile.prefs.setInt(1, forKey: IntroViewControllerSeenProfileKey)
                    }
                })
            } else {
                presentViewController(introViewController, animated: true) {
                    self.profile.prefs.setInt(1, forKey: IntroViewControllerSeenProfileKey)
                }
            }
            /*
            presentViewController(introViewController, animated: true) {
                self.profile.prefs.setInt(1, forKey: IntroViewControllerSeenProfileKey)
            }
            */

            return true
        }

        return false
    }

    func introViewControllerDidFinish(introViewController: IntroViewController) {
        introViewController.dismissViewControllerAnimated(true) { finished in
            if self.navigationController?.viewControllers.count > 1 {
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
        }
        // Cliqz: focus on the search bar after dimissing on-boarding if it is on home view
        if urlBar.currentURL == nil || AboutUtils.isAboutHomeURL(urlBar.currentURL) {
            self.urlBar.enterOverlayMode("", pasted: false)
        }
    }

    func presentSignInViewController() {
        // Show the settings page if we have already signed in. If we haven't then show the signin page
        let vcToPresent: UIViewController
        if profile.hasAccount() {
            let settingsTableViewController = AppSettingsTableViewController()
            settingsTableViewController.profile = profile
            settingsTableViewController.tabManager = tabManager
            vcToPresent = settingsTableViewController
        } else {
            let signInVC = FxAContentViewController()
            signInVC.delegate = self
            signInVC.url = profile.accountConfiguration.signInURL
            signInVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(BrowserViewController.dismissSignInViewController))
            vcToPresent = signInVC
        }

        let settingsNavigationController = SettingsNavigationController(rootViewController: vcToPresent)
		settingsNavigationController.modalPresentationStyle = .FormSheet
        self.presentViewController(settingsNavigationController, animated: true, completion: nil)
    }

    func dismissSignInViewController() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func introViewControllerDidRequestToLogin(introViewController: IntroViewController) {
        introViewController.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.presentSignInViewController()
        })
    }
}

extension BrowserViewController: FxAContentViewControllerDelegate {
    func contentViewControllerDidSignIn(viewController: FxAContentViewController, data: JSON) -> Void {
        if data["keyFetchToken"].asString == nil || data["unwrapBKey"].asString == nil {
            // The /settings endpoint sends a partial "login"; ignore it entirely.
            log.debug("Ignoring didSignIn with keyFetchToken or unwrapBKey missing.")
            return
        }

        // TODO: Error handling.
        let account = FirefoxAccount.fromConfigurationAndJSON(profile.accountConfiguration, data: data)!
        profile.setAccount(account)
        if let account = self.profile.getAccount() {
            account.advance()
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func contentViewControllerDidCancel(viewController: FxAContentViewController) {
        log.info("Did cancel out of FxA signin")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension BrowserViewController: ContextMenuHelperDelegate {
    func contextMenuHelper(contextMenuHelper: ContextMenuHelper, didLongPressElements elements: ContextMenuHelper.Elements, gestureRecognizer: UILongPressGestureRecognizer) {
        // locationInView can return (0, 0) when the long press is triggered in an invalid page
        // state (e.g., long pressing a link before the document changes, then releasing after a
        // different page loads).
        let touchPoint = gestureRecognizer.locationInView(view)
        guard touchPoint != CGPointZero else { return }

        let touchSize = CGSizeMake(0, 16)

        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        var dialogTitle: String?

        if let url = elements.link, currentTab = tabManager.selectedTab {
            dialogTitle = url.absoluteString
            let isPrivate = currentTab.isPrivate
            if !isPrivate {
                let newTabTitle = NSLocalizedString("Open In New Tab", comment: "Context menu item for opening a link in a new tab")
                let openNewTabAction =  UIAlertAction(title: newTabTitle, style: UIAlertActionStyle.Default) { (action: UIAlertAction) in
                    self.scrollController.showToolbars(animated: !self.scrollController.toolbarsShowing, completion: { _ in
                        self.tabManager.addTab(NSURLRequest(URL: url))
                    })
                }
                actionSheetController.addAction(openNewTabAction)
            }

			if YoutubeVideoDownloader.isYoutubeURL(url) {
				let downloadVideoTitle = NSLocalizedString("Download youtube video", tableName: "Cliqz", comment: "Context menu item for opening a link in a new tab")
				let downloadVideo =  UIAlertAction(title: downloadVideoTitle, style: UIAlertActionStyle.Default) { (action: UIAlertAction) in
					self.downloadVideoFromURL(dialogTitle!)
					TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("video_downloader", "click", "target_type", "download_link"))
				}
				actionSheetController.addAction(downloadVideo)
			}

            if #available(iOS 9, *) {
                let openNewPrivateTabTitle = NSLocalizedString("Open In New Private Tab", tableName: "PrivateBrowsing", comment: "Context menu option for opening a link in a new private tab")
                let openNewPrivateTabAction =  UIAlertAction(title: openNewPrivateTabTitle, style: UIAlertActionStyle.Default) { (action: UIAlertAction) in
                    self.scrollController.showToolbars(animated: !self.scrollController.toolbarsShowing, completion: { _ in
                        self.tabManager.addTab(NSURLRequest(URL: url), isPrivate: true)
                    })
                }
                actionSheetController.addAction(openNewPrivateTabAction)
            }

            let copyTitle = NSLocalizedString("Copy Link", comment: "Context menu item for copying a link URL to the clipboard")
            let copyAction = UIAlertAction(title: copyTitle, style: UIAlertActionStyle.Default) { (action: UIAlertAction) -> Void in
                let pasteBoard = UIPasteboard.generalPasteboard()
                pasteBoard.URL = url
            }
            actionSheetController.addAction(copyAction)

            let shareTitle = NSLocalizedString("Share Link", comment: "Context menu item for sharing a link URL")
            let shareAction = UIAlertAction(title: shareTitle, style: UIAlertActionStyle.Default) { _ in
                self.presentActivityViewController(url, sourceView: self.view, sourceRect: CGRect(origin: touchPoint, size: touchSize), arrowDirection: .Any)
            }
            actionSheetController.addAction(shareAction)
        }

        if let url = elements.image {
            if dialogTitle == nil {
                dialogTitle = url.absoluteString
            }

            let photoAuthorizeStatus = PHPhotoLibrary.authorizationStatus()
            let saveImageTitle = NSLocalizedString("Save Image", comment: "Context menu item for saving an image")
            let saveImageAction = UIAlertAction(title: saveImageTitle, style: UIAlertActionStyle.Default) { (action: UIAlertAction) -> Void in
                if photoAuthorizeStatus == PHAuthorizationStatus.Authorized || photoAuthorizeStatus == PHAuthorizationStatus.NotDetermined {
                    self.getImage(url) { UIImageWriteToSavedPhotosAlbum($0, nil, nil, nil) }
                } else {
                    let accessDenied = UIAlertController(title: NSLocalizedString("Firefox would like to access your Photos", comment: "See http://mzl.la/1G7uHo7"), message: NSLocalizedString("This allows you to save the image to your Camera Roll.", comment: "See http://mzl.la/1G7uHo7"), preferredStyle: UIAlertControllerStyle.Alert)
                    let dismissAction = UIAlertAction(title: UIConstants.CancelString, style: UIAlertActionStyle.Default, handler: nil)
                    accessDenied.addAction(dismissAction)
                    let settingsAction = UIAlertAction(title: NSLocalizedString("Open Settings", comment: "See http://mzl.la/1G7uHo7"), style: UIAlertActionStyle.Default ) { (action: UIAlertAction!) -> Void in
                        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                    }
                    accessDenied.addAction(settingsAction)
                    self.presentViewController(accessDenied, animated: true, completion: nil)

                }
            }
            actionSheetController.addAction(saveImageAction)

            let copyImageTitle = NSLocalizedString("Copy Image", comment: "Context menu item for copying an image to the clipboard")
            let copyAction = UIAlertAction(title: copyImageTitle, style: UIAlertActionStyle.Default) { (action: UIAlertAction) -> Void in
                // put the actual image on the clipboard
                // do this asynchronously just in case we're in a low bandwidth situation
                let pasteboard = UIPasteboard.generalPasteboard()
                pasteboard.URL = url
                let changeCount = pasteboard.changeCount
                let application = UIApplication.sharedApplication()
                var taskId: UIBackgroundTaskIdentifier = 0
                taskId = application.beginBackgroundTaskWithExpirationHandler { _ in
                    application.endBackgroundTask(taskId)
                }

                Alamofire.request(.GET, url)
                    .validate(statusCode: 200..<300)
                    .response { responseRequest, responseResponse, responseData, responseError in
                        // Only set the image onto the pasteboard if the pasteboard hasn't changed since
                        // fetching the image; otherwise, in low-bandwidth situations,
                        // we might be overwriting something that the user has subsequently added.
                        if changeCount == pasteboard.changeCount, let imageData = responseData where responseError == nil {
                            pasteboard.addImageWithData(imageData, forURL: url)
                        }

                        application.endBackgroundTask(taskId)
                }
            }
            actionSheetController.addAction(copyAction)
        }

        // If we're showing an arrow popup, set the anchor to the long press location.
        if let popoverPresentationController = actionSheetController.popoverPresentationController {
            popoverPresentationController.sourceView = view
            popoverPresentationController.sourceRect = CGRect(origin: touchPoint, size: touchSize)
            popoverPresentationController.permittedArrowDirections = .Any
        }

        actionSheetController.title = dialogTitle?.ellipsize(maxLength: ActionSheetTitleMaxLength)
        let cancelAction = UIAlertAction(title: UIConstants.CancelString, style: UIAlertActionStyle.Cancel, handler: nil)
        actionSheetController.addAction(cancelAction)
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }

    private func getImage(url: NSURL, success: UIImage -> ()) {
        Alamofire.request(.GET, url)
            .validate(statusCode: 200..<300)
            .response { _, _, data, _ in
                if let data = data,
                   let image = UIImage.dataIsGIF(data) ? UIImage.imageFromGIFDataThreadSafe(data) : UIImage.imageFromDataThreadSafe(data) {
                    success(image)
                }
            }
    }
}

extension BrowserViewController: KeyboardHelperDelegate {
    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        keyboardState = state
        updateViewConstraints()

        UIView.animateWithDuration(state.animationDuration) {
            UIView.setAnimationCurve(state.animationCurve)
            self.findInPageContainer.layoutIfNeeded()
            self.snackBars.layoutIfNeeded()
        }
    }

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
    }

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        keyboardState = nil
        updateViewConstraints()

        UIView.animateWithDuration(state.animationDuration) {
            UIView.setAnimationCurve(state.animationCurve)
            self.findInPageContainer.layoutIfNeeded()
            self.snackBars.layoutIfNeeded()
        }
    }
}

extension BrowserViewController: TabTrayDelegate {
    // This function animates and resets the browser chrome transforms when
    // the tab tray dismisses.
    func tabTrayDidDismiss(tabTray: TabTrayController) {
        resetBrowserChrome()
    }

    func tabTrayDidAddBookmark(tab: Browser) {
        guard let url = tab.url?.absoluteString where url.characters.count > 0 else { return }
        self.addBookmark(url, title: tab.title)
    }


    func tabTrayDidAddToReadingList(tab: Browser) -> ReadingListClientRecord? {
        guard let url = tab.url?.absoluteString where url.characters.count > 0 else { return nil }
        return profile.readingList?.createRecordWithURL(url, title: tab.title ?? url, addedBy: UIDevice.currentDevice().name).successValue
    }

    func tabTrayRequestsPresentationOf(viewController viewController: UIViewController) {
        self.presentViewController(viewController, animated: false, completion: nil)
    }
}

// MARK: Browser Chrome Theming
extension BrowserViewController: Themeable {

    func applyTheme(themeName: String) {
        urlBar.applyTheme(themeName)
        toolbar?.applyTheme(themeName)
        readerModeBar?.applyTheme(themeName)

        switch(themeName) {
        case Theme.NormalMode:
            // Cliqz: Commented because header is now UIView which doesn't have style
//            header.blurStyle = .ExtraLight
            footerBackground?.blurStyle = .ExtraLight
        case Theme.PrivateMode:
            // Cliqz: Commented because header is now UIView which doesn't have style
//            header.blurStyle = .Dark
            // Cliqz: Use same blurStyle for both normal and private modes
//            footerBackground?.blurStyle = .Dark
            footerBackground?.blurStyle = .ExtraLight
        default:
            log.debug("Unknown Theme \(themeName)")
        }
    }
}

// A small convienent class for wrapping a view with a blur background that can be modified
class BlurWrapper: UIView {
    var blurStyle: UIBlurEffectStyle = .ExtraLight {
        didSet {
            let newEffect = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
            effectView.removeFromSuperview()
            effectView = newEffect
            insertSubview(effectView, belowSubview: wrappedView)
            effectView.snp_remakeConstraints { make in
                make.edges.equalTo(self)
            }
        }
    }

    private var effectView: UIVisualEffectView
    private var wrappedView: UIView

    init(view: UIView) {
        wrappedView = view
        effectView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        super.init(frame: CGRectZero)

        addSubview(effectView)
        addSubview(wrappedView)

        effectView.snp_makeConstraints { make in
            make.edges.equalTo(self)
        }

        wrappedView.snp_makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol Themeable {
    func applyTheme(themeName: String)
}

extension BrowserViewController: FindInPageBarDelegate, FindInPageHelperDelegate {
    func findInPage(findInPage: FindInPageBar, didTextChange text: String) {
        find(text, function: "find")
    }

    func findInPage(findInPage: FindInPageBar, didFindNextWithText text: String) {
        findInPageBar?.endEditing(true)
        find(text, function: "findNext")
    }

    func findInPage(findInPage: FindInPageBar, didFindPreviousWithText text: String) {
        findInPageBar?.endEditing(true)
        find(text, function: "findPrevious")
    }

    func findInPageDidPressClose(findInPage: FindInPageBar) {
        updateFindInPageVisibility(visible: false)
    }

    private func find(text: String, function: String) {
        guard let webView = tabManager.selectedTab?.webView else { return }

        let escaped = text.stringByReplacingOccurrencesOfString("\\", withString: "\\\\")
                          .stringByReplacingOccurrencesOfString("\"", withString: "\\\"")

        webView.evaluateJavaScript("__firefox__.\(function)(\"\(escaped)\")", completionHandler: nil)
    }

    func findInPageHelper(findInPageHelper: FindInPageHelper, didUpdateCurrentResult currentResult: Int) {
        findInPageBar?.currentResult = currentResult
    }

    func findInPageHelper(findInPageHelper: FindInPageHelper, didUpdateTotalResults totalResults: Int) {
        findInPageBar?.totalResults = totalResults
    }
}

extension BrowserViewController: JSPromptAlertControllerDelegate {
    func promptAlertControllerDidDismiss(alertController: JSPromptAlertController) {
        showQueuedAlertIfAvailable()
    }
}
    
private extension WKNavigationAction {
    /// Allow local requests only if the request is privileged.
    private var isAllowed: Bool {
        return !(request.URL?.isLocal ?? false) || request.isPrivileged
    }
}


// CLiqz: Added extension for HomePanelDelegate to react for didSelectURL from SearchHistoryViewController
extension BrowserViewController: HomePanelDelegate {
    
    func homePanelDidRequestToSignIn(homePanel: HomePanel) {
        
    }
    func homePanelDidRequestToCreateAccount(homePanel: HomePanel) {
        
    }
    func homePanel(homePanel: HomePanel, didSelectURL url: NSURL, visitType: VisitType) {
        // Delegate method for History panel
        finishEditingAndSubmit(url, visitType: VisitType.Typed)
    }
    
    func homePanel(homePanel: HomePanel, didSelectURLString url: String, visitType: VisitType) {
        
    }
}

// Cliqz: Added TransitioningDelegate to maintain layers change animations
extension BrowserViewController: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = true
        return transition
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = false
        return transition
    }
}

// Cliqz: compined the two extensions for SearchViewDelegate, RecommendationsViewControllerDelegate, and SearchHistoryViewControllerDelegate into one extension
extension BrowserViewController: SearchViewDelegate, RecommendationsViewControllerDelegate, SearchHistoryViewControllerDelegate {
    
    func didSelectURL(url: NSURL, searchQuery: String?) {
        navigateToUrl(url, searchQuery: searchQuery)
    }
    
    func didSelectURL(url: NSURL) {
        finishEditingAndSubmit(url, visitType: .Link)
    }
    
    func searchForQuery(query: String) {
        self.urlBar.enterOverlayMode(query, pasted: true)
    }
    
    func autoCompeleteQuery(autoCompleteText: String) {
        urlBar.setAutocompleteSuggestion(autoCompleteText)
    }
    func dismissKeyboard() {
        urlBar.resignFirstResponder()
    }
    private func navigateToUrl(url: NSURL, searchQuery: String?) {
        let query = (searchQuery != nil) ? searchQuery! : ""
        let forwardUrl = NSURL(string: "\(WebServer.sharedInstance.base)/cliqz/trampolineForward.html?url=\(url.absoluteString.encodeURL())&q=\(query.encodeURL())")
        if let tab = tabManager.selectedTab,
            let u = forwardUrl, let nav = tab.loadRequest(PrivilegedRequest(URL: u)) {
            self.recordNavigationInTab(tab, navigation: nav, visitType: .Link)
            showWebViewOverLay(tab)
        }
        urlBar.currentURL = url
        urlBar.leaveOverlayMode()
    }
    
}

// Cliqz: Extension for BrowserViewController to put addes methods
extension BrowserViewController {
    
    // Cliqz: preserve search state when dimissing view
    private func preserveSearchState() {
        guard let selectedTab = self.tabManager.selectedTab else {
            return
        }
        
        if self.searchController?.view.hidden == false {
            urlBar.leaveOverlayMode()
            selectedTab.lastSearchQuery = searchController?.searchQuery ?? ""
            selectedTab.inSearchMode = true
        } else {
            selectedTab.inSearchMode = false
        }
    }
    
    // reset App state when session expire
    private func resetState() {
        
        // remove all tabs except the first tab
        let lastIndex = tabManager.tabs.count-1
        for index in lastIndex.stride(to: 0, by: -1) {
            let tab = tabManager.tabs[index]
            tabManager.removeTab(tab)
        }
        
        if let selectedTab = tabManager.selectedTab,
            let searchController = self.searchController {
            
            selectedTab.inSearchMode = true
            selectedTab.lastSearchQuery = ""
            
            switchToSearchModeIfNeeded()
            
            // added delay before calling resetState to ensure that it is called after calling search with empty string
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
            dispatch_after(time, dispatch_get_main_queue(), {
                searchController.resetState()
                
            })
            
        }
        
        
    }
    // Cliqz: Added method to show search view if needed
    private func switchToSearchModeIfNeeded() {
        if let selectedTab = self.tabManager.selectedTab {
            if (selectedTab.inSearchMode) {
                self.urlBar.enterOverlayMode(selectedTab.lastSearchQuery, pasted: true)
                selectedTab.lastSearchQuery = ""
                scrollController.showToolbars(animated: false)
            }
        }
        
    }
    
    // Cliqz: Added extension for logging the Navigation Telemetry signals
    private func startNavigation(webView: WKWebView, navigationAction: WKNavigationAction) {
        // determine if the navigation is back navigation
        if navigationAction.navigationType == .BackForward && backListSize >= webView.backForwardList.backList.count {
            isBackNavigation = true
        } else {
            isBackNavigation = false
        }
        backListSize = webView.backForwardList.backList.count
    }
    
    private func finishNavigation(webView: WKWebView) {
        // calculate times
        let currentTime = NSDate.getCurrentMillis()
        let displayTime = currentTime - navigationEndTime
        navigationEndTime = currentTime
        
        // calculate the url length
        let urlLength = webView.URL?.absoluteString.characters.count
        
        
        // check if back navigation
        if isBackNavigation {
            backNavigationStep++
            logNavigationEvent("back", step: backNavigationStep, urlLength: urlLength!, displayTime: displayTime)
        } else {
            // discard the first navigation (result navigation is not included)
            if navigationStep != 0 {
                logNavigationEvent("location_change", step: navigationStep, urlLength: urlLength!, displayTime: displayTime)
            }
            navigationStep++
            backNavigationStep = 0
        }
    }
    
    private func logNavigationEvent(action: String, step: Int, urlLength: Int, displayTime: Double) {
        TelemetryLogger.sharedInstance.logEvent(.Navigation(action, step, urlLength, displayTime))
    }
    
    
    // Cliqz: Add an overlay to the WKWebView to hide the old page while navigating to the new search result
    private func showWebViewOverLay(selectedTab: Browser) {
        if self.webViewOverlay == nil {
            webViewOverlay = UIView(frame: (selectedTab.webView?.bounds)!)
            webViewOverlay!.backgroundColor = UIColor.whiteColor()
            selectedTab.webView?.addSubview(webViewOverlay!)
        }
    }
    
    private func hideWebViewOverlay() {
        if webViewOverlay != nil {
            webViewOverlay!.removeFromSuperview()
            webViewOverlay = nil
        }
    }
    
    // Cliqz: Added to diffrentiate between navigating a website or searching for something when app goes to background
    func SELappDidEnterBackgroundNotification() {
        
        displayedPopoverController?.dismissViewControllerAnimated(false, completion: nil)
        
        isAppResponsive = false
        
        if self.tabManager.selectedTab?.isPrivate == false {
            if searchController?.view.hidden == true {
                let webView = self.tabManager.selectedTab?.webView
                searchController?.appDidEnterBackground(webView?.URL, lastTitle:webView?.title)
            } else {
                searchController?.appDidEnterBackground()
            }
        }
        
        saveLastVisitedWebSite()
    }
    
    private func saveLastVisitedWebSite() {
        if let selectedTab = self.tabManager.selectedTab,
            let lastVisitedWebsite = selectedTab.webView?.URL?.absoluteString
            where selectedTab.isPrivate == false && !lastVisitedWebsite.hasPrefix("http://localhost") {
            // Cliqz: store the last visited website
            LocalDataStore.setObject(lastVisitedWebsite, forKey: lastVisitedWebsiteKey)
        }
    }
    // Cliqz: added to mark the app being responsive (mainly send telemetry signal)
    func appDidBecomeResponsive(startupType: String) {
        if isAppResponsive == false {
            isAppResponsive = true
            AppStatus.sharedInstance.appDidBecomeResponsive(startupType)
        }
    }
    
    // Cliqz: Added to navigate to the last visited website (3D quick home actions)
    func navigateToLastWebsite() {
        if let lastVisitedWebsite = LocalDataStore.objectForKey(self.lastVisitedWebsiteKey) as? String {
            self.initialURL = lastVisitedWebsite
        }
    }
    
    // Cliqz: Added to navigate to url (3D quick home actions)
    func navigateToURL(url: NSURL) {
        finishEditingAndSubmit(url, visitType: .Link)
		self.initialURL = nil
    }
    
    // Cliqz: fix headerTopConstraint for scrollController to work properly during the animation to/from past layer
    private func fixHeaderConstraint(){
        let currentDevice = UIDevice.currentDevice()
        let iphoneLandscape = currentDevice.orientation.isLandscape && (currentDevice.userInterfaceIdiom == .Phone)
        if transition.isAnimating && !iphoneLandscape {
            headerConstraintUpdated = true
            
            scrollController.headerTopConstraint?.updateOffset(20)
            
            statusBarOverlay.snp_remakeConstraints { make in
                make.top.left.right.equalTo(self.view)
                make.height.equalTo(20)
            }
            
        } else if(headerConstraintUpdated) {
            headerConstraintUpdated = false
            scrollController.headerTopConstraint?.updateOffset(0)
        }
        
    }
    
    // Cliqz: Add custom user scripts
    func addCustomUserScripts(browser: Browser) {
        // Wikipedia scripts to clear expanded sections from local storage
        if let path = NSBundle.mainBundle().pathForResource("wikipediaUserScript", ofType: "js"), source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
            let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: false)
            browser.webView!.configuration.userContentController.addUserScript(userScript)
        }
        
    }
}
