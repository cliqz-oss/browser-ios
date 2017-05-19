/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import AVFoundation
import XCGLogger
import MessageUI
import Fabric
import Crashlytics
import WebImage
import SwiftKeychainWrapper
import LocalAuthentication

import React

private let log = Logger.browserLogger

let LatestAppVersionProfileKey = "latestAppVersion"
let AllowThirdPartyKeyboardsKey = "settings.allowThirdPartyKeyboards"
private let InitialPingSentKey = "initialPingSent"

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var browserViewController: BrowserViewController!
    var rootViewController: UINavigationController!
    weak var profile: BrowserProfile?
    var tabManager: TabManager!
    var adjustIntegration: AdjustIntegration?
    var foregroundStartTime = 0

    weak var application: UIApplication?
    var launchOptions: [NSObject: AnyObject]?

    let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String

    var openInFirefoxParams: LaunchParams? = nil

    var appStateStore: AppStateStore!

    var systemBrightness: CGFloat = UIScreen.mainScreen().brightness
    
    //Cliqz: capacity limits for URLCache
    let CacheMemoryCapacity = 8 * 1024 * 1024
    let CacheDiskCapacity   = 50 * 1024 * 1024
    

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        AppStatus.sharedInstance.appWillFinishLaunching()
        
        //Cliqz: Configure URL Cache; set memoryCapacity to 8MB, and diskCapacity to 50MB
        let URLCache = NSURLCache(memoryCapacity: CacheMemoryCapacity, diskCapacity: CacheDiskCapacity, diskPath: nil)
        NSURLCache.setSharedURLCache(URLCache)

        
        // Hold references to willFinishLaunching parameters for delayed app launch
        self.application = application
        self.launchOptions = launchOptions

        log.debug("Configuring window…")

        self.window = CliqzMainWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = UIConstants.AppBackgroundColor
		
		AWSSNSManager.configureCongnitoPool()

        // Short c ircuit the app if we want to email logs from the debug menu
        if DebugSettingsBundleOptions.launchIntoEmailComposer {
            self.window?.rootViewController = UIViewController()
            presentEmailComposerWithLogs()
            return true
        } else {
            return startApplication(application, withLaunchOptions: launchOptions)
        }
		
    }

	func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
		let deviceTokenString = "\(deviceToken)"
			.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString:"<>"))
			.stringByReplacingOccurrencesOfString(" ", withString: "")
		AWSSNSManager.createPlatformEndpoint(deviceTokenString)
	}

	func application(application: UIApplication,didFailToRegisterForRemoteNotificationsWithError error: NSError) {
		print("Register for Notifications is failed with error: \(error)")
	}

    private func startApplication(application: UIApplication,  withLaunchOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        log.debug("Setting UA…")
        // Set the Firefox UA for browsing.
        setUserAgent()

        log.debug("Starting keyboard helper…")
        // Start the keyboard helper to monitor and cache keyboard state.
        KeyboardHelper.defaultHelper.startObserving()
        
        log.debug("Starting dynamic font helper…")
        DynamicFontHelper.defaultHelper.startObserving()
        
        log.debug("Setting custom menu items…")
        MenuHelper.defaultHelper.setItems()
        
        // Cliqz: Removed logger inisialization because of performance considerations and also we don't need FF logger.
//        log.debug("Creating Sync log file…")
//        let logDate = NSDate()
//        // Create a new sync log file on cold app launch. Note that this doesn't roll old logs.
//        Logger.syncLogger.newLogWithDate(logDate)
//        
//        log.debug("Creating corrupt DB logger…")
//        Logger.corruptLogger.newLogWithDate(logDate)
//        
//        log.debug("Creating Browser log file…")
//        Logger.browserLogger.newLogWithDate(logDate)
        
        log.debug("Getting profile…")
        let profile = getProfile(application)
        appStateStore = AppStateStore(prefs: profile.prefs)

        log.debug("Initializing telemetry…")
        Telemetry.initWithPrefs(profile.prefs)

        if !DebugSettingsBundleOptions.disableLocalWebServer {
            log.debug("Starting web server…")
            // Set up a web server that serves us static content. Do this early so that it is ready when the UI is presented.
            setUpWebServer(profile)
        }

        log.debug("Setting AVAudioSession category…")
        do {
            // for aural progress bar: play even with silent switch on, and do not stop audio from other apps (like music)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
        } catch _ {
            log.error("Failed to assign AVAudioSession category to allow playing with silent switch on for aural progress bar")
        }

        let imageStore = DiskImageStore(files: profile.files, namespace: "TabManagerScreenshots", quality: UIConstants.ScreenshotQuality)

        log.debug("Configuring tabManager…")
        self.tabManager = TabManager(prefs: profile.prefs, imageStore: imageStore)
        self.tabManager.stateDelegate = self

        // Add restoration class, the factory that will return the ViewController we
        // will restore with.
        log.debug("Initing BVC…")

        browserViewController = BrowserViewController(profile: self.profile!, tabManager: self.tabManager)
        browserViewController.restorationIdentifier = NSStringFromClass(BrowserViewController.self)
        browserViewController.restorationClass = AppDelegate.self

//		 REACT ----
		let viewController = UIViewController()
		
		viewController.view = Engine.sharedInstance.rootView

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.delegate = self
        navigationController.navigationBarHidden = true

        //if AppConstants.MOZ_STATUS_BAR_NOTIFICATION {
          //  rootViewController = NotificationRootViewController(rootViewController: navigationController)
        //} else {
            rootViewController = navigationController
        //}

        self.window!.rootViewController = rootViewController
		
		
        // Cliqz: disable crash reporting
//        do {
//            log.debug("Configuring Crash Reporting...")
//            try PLCrashReporter.sharedReporter().enableCrashReporterAndReturnError()
//        } catch let error as NSError {
//            log.error("Failed to enable PLCrashReporter - \(error.description)")
//        }

        log.debug("Adding observers…")
        NSNotificationCenter.defaultCenter().addObserverForName(FSReadingListAddReadingListItemNotification, object: nil, queue: nil) { (notification) -> Void in
            if let userInfo = notification.userInfo, url = userInfo["URL"] as? NSURL {
                let title = (userInfo["Title"] as? String) ?? ""
                profile.readingList?.createRecordWithURL(url.absoluteString!, title: title, addedBy: UIDevice.currentDevice().name)
            }
        }

        // check to see if we started 'cos someone tapped on a notification.
        if let localNotification = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
            viewURLInNewTab(localNotification)
        }
        
        adjustIntegration = AdjustIntegration(profile: profile)

        // We need to check if the app is a clean install to use for
        // preventing the What's New URL from appearing.
        if getProfile(application).prefs.intForKey(IntroViewControllerSeenProfileKey) == nil {
            getProfile(application).prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)
        }

        log.debug("Updating authentication keychain state to reflect system state")
        self.updateAuthenticationInfo()
        SystemUtils.onFirstRun()

        resetForegroundStartTime()
        if !(profile.prefs.boolForKey(InitialPingSentKey) ?? false) {
            // Try to send an initial core ping when the user first opens the app so that they're
            // "on the map". This lets us know they exist if they try the app once, crash, then uninstall.
            // sendCorePing() only sends the ping if the user is offline, so if the first ping doesn't
            // go through *and* the user crashes then uninstalls on the first run, then we're outta luck.
            profile.prefs.setBool(true, forKey: InitialPingSentKey)
            sendCorePing()
        }

        sendCorePing()
        
        //self.syncHistory(profile)
		
        log.debug("Done with setting up the application.")

        return true
    }
	
	func openUrlInWebView(url: NSURL) {
		dispatch_async(dispatch_get_main_queue()) {
			self.rootViewController.pushViewController(self.browserViewController, animated: false)
			let delayTime = dispatch_time(DISPATCH_TIME_NOW,
			                              Int64(0.3 * Double(NSEC_PER_SEC)))
			dispatch_after(delayTime, dispatch_get_main_queue(), {
				self.browserViewController.switchToTabForURLOrOpen(url)
			})
		}
	}
    
    func searchInWebView(text: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.rootViewController.pushViewController(self.browserViewController, animated: false)
            let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                                          Int64(0.15 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue(), {
				self.browserViewController.newTab()
				self.browserViewController.searchForQuery(text)
            })
        }
    }
    
//    func syncHistory(profile: Profile) {
//        let historySyncedKey = "newHistorySyncedLocal"
//        let isHistorySynced = LocalDataStore.objectForKey(historySyncedKey) as? NSNumber
//        if isHistorySynced == nil || !isHistorySynced!.boolValue {
//            profile.history.getHistoryVisits(0, limit: 100).uponQueue(dispatch_get_main_queue()) { result in
//                if let sites = result.successValue {
//                    ConversationalHistoryAPI.pushAllHistory(sites, completionHandler: {
//                        (error) in
//                        if error == nil {
//                            LocalDataStore.setObject(NSNumber(bool: true), forKey: historySyncedKey)
//                        }
//                    })
//                }
//            }
//        }
//    }

	
	func navigateToWebView(url: String) {
		
	}
    
    func applicationWillTerminate(application: UIApplication) {
        log.debug("Application will terminate.")
		
		// We have only five seconds here, so let's hope this doesn't take too long.
        self.profile?.shutdown()

        // Allow deinitializers to close our database connections.
        self.profile = nil
        self.tabManager = nil
        self.browserViewController = nil
        self.rootViewController = nil

        AppStatus.sharedInstance.appWillTerminate()

    }

    /**
     * We maintain a weak reference to the profile so that we can pause timed
     * syncs when we're backgrounded.
     *
     * The long-lasting ref to the profile lives in BrowserViewController,
     * which we set in application:willFinishLaunchingWithOptions:.
     *
     * If that ever disappears, we won't be able to grab the profile to stop
     * syncing... but in that case the profile's deinit will take care of things.
     */
    func getProfile(application: UIApplication) -> Profile {
        if let profile = self.profile {
            return profile
        }
        let p = BrowserProfile(localName: "profile", app: application)
        self.profile = p
        return p
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        AppStatus.sharedInstance.appDidFinishLaunching()

        // Override point for customization after application launch.
        let shouldPerformAdditionalDelegateHandling = true

        log.debug("Did finish launching.")
        
        log.debug("Setting up Adjust")
        self.adjustIntegration?.triggerApplicationDidFinishLaunchingWithOptions(launchOptions)
        
        log.debug("Making window key and visible…")
        self.window!.makeKeyAndVisible()
        
        // Cliqz: changed the tint color of window (ActionSheets, AlertViews, NavigationBar)
        self.window!.tintColor = UIConstants.CliqzThemeColor

        // Now roll logs.
        log.debug("Triggering log roll.")

        // Cliqz: disabled calling to syncLogger
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
//            Logger.syncLogger.deleteOldLogsDownToSizeLimit()
//            Logger.browserLogger.deleteOldLogsDownToSizeLimit()
//        }

        // Cliqz: Start Crashlytics
        Crashlytics.sharedInstance().delegate = self.browserViewController
        Fabric.with([Crashlytics.self])
        
        // Cliqz: comented Firefox 3D Touch code
//        if #available(iOS 9, *) {
//            // If a shortcut was launched, display its information and take the appropriate action
//            if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
//                
//                QuickActions.sharedInstance.launchedShortcutItem = shortcutItem
//                // This will block "performActionForShortcutItem:completionHandler" from being called.
//                shouldPerformAdditionalDelegateHandling = false
//            }
//        }

        
        // Cliqz: Added Lookback integration
#if BETA
//		Lookback.setupWithAppToken("HWiD4ErSbeNy9JcRg")
//		Lookback.sharedLookback().shakeToRecord = true
//		Lookback.sharedLookback() = false
#endif
        // Configure AntiTracking/AdBlocking Module
        AntiTrackingModule.sharedInstance.initModule()
        AdblockingModule.sharedInstance.initModule()
        
        log.debug("Done with applicationDidFinishLaunching.")
        
        return shouldPerformAdditionalDelegateHandling
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        guard let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) else {
            return false
        }
        guard let urlTypes = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleURLTypes") as? [AnyObject],
                urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String] else {
            // Something very strange has happened; org.mozilla.Client should be the zeroeth URL type.
            log.error("Custom URL schemes not available for validating")
            return false
        }

        guard let scheme = components.scheme where urlSchemes.contains(scheme) else {
            log.warning("Cannot handle \(components.scheme) URL scheme")
            return false
        }

        var url: String?
        var isPrivate: Bool = false
        for item in (components.queryItems ?? []) as [NSURLQueryItem] {
            switch item.name {
            case "url":
                url = item.value
            case "private":
                isPrivate = NSString(string: item.value ?? "false").boolValue
            default: ()
            }
        }

        let params: LaunchParams

        if let url = url, newURL = NSURL(string: url) {
            params = LaunchParams(url: newURL, isPrivate: isPrivate)
        } else {
            params = LaunchParams(url: nil, isPrivate: isPrivate)
        }

        if application.applicationState == .Active {
            // If we are active then we can ask the BVC to open the new tab right away. 
            // Otherwise, we remember the URL and we open it in applicationDidBecomeActive.
            launchFromURL(params)
        } else {
            openInFirefoxParams = params
        }

        return true
    }

    func launchFromURL(params: LaunchParams) {
        let isPrivate = params.isPrivate ?? false
        if let newURL = params.url {
            self.browserViewController.switchToTabForURLOrOpen(newURL, isPrivate: isPrivate)
        } else {
            self.browserViewController.openBlankNewTabAndFocus(isPrivate: isPrivate)
        }
    }

    func application(application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: String) -> Bool {
		// Cliqz: Commented third party keyboard handler. We shouldn't allow any third party keyboard.
		/*
        if let thirdPartyKeyboardSettingBool = getProfile(application).prefs.boolForKey(AllowThirdPartyKeyboardsKey) where extensionPointIdentifier == UIApplicationKeyboardExtensionPointIdentifier {
            return thirdPartyKeyboardSettingBool
        }

        return true
         */
		return false
    }

    // We sync in the foreground only, to avoid the possibility of runaway resource usage.
    // Eventually we'll sync in response to notifications.
    func applicationDidBecomeActive(application: UIApplication) {
        
        AppStatus.sharedInstance.appDidBecomeActive(self.profile!)

        guard !DebugSettingsBundleOptions.launchIntoEmailComposer else {
            return
        }

        NightModeHelper.restoreNightModeBrightness((self.profile?.prefs)!, toForeground: true)
        self.profile?.syncManager.applicationDidBecomeActive()

        //Cliqz: disable loading queued tables
        // We could load these here, but then we have to futz with the tab counter
        // and making NSURLRequests.
//        self.browserViewController.loadQueuedTabs()

        // handle quick actions is available
        if #available(iOS 9, *) {
            let quickActions = QuickActions.sharedInstance
            if let shortcut = quickActions.launchedShortcutItem {
                // dispatch asynchronously so that BVC is all set up for handling new tabs
                // when we try and open them
                quickActions.handleShortCutItem(shortcut, withBrowserViewController: browserViewController)
                quickActions.launchedShortcutItem = nil
            }

            // we've removed the Last Tab option, so we should remove any quick actions that we already have that are last tabs
            // we do this after we've handled any quick actions that have been used to open the app so that we don't b0rk if
            // the user has opened the app for the first time after upgrade with a Last Tab quick action
            QuickActions.sharedInstance.removeDynamicApplicationShortcutItemOfType(ShortcutType.OpenLastTab, fromApplication: application)
        }

        // Check if we have a URL from an external app or extension waiting to launch,
        // then launch it on the main thread.
        if let params = openInFirefoxParams {
            openInFirefoxParams = nil
            dispatch_async(dispatch_get_main_queue()) {
                self.launchFromURL(params)
            }
        }
        
        // Cliqz: Added to confire home shortcuts
        if #available(iOS 9.0, *) {
            self.configureHomeShortCuts()
        }
    }

    func applicationDidEnterBackground(application: UIApplication) {

        // Cliq: notify the AppStatus that the app entered background
        AppStatus.sharedInstance.appDidEnterBackground()
        
        // Workaround for crashing in the background when <select> popovers are visible (rdar://24571325).
        let jsBlurSelect = "if (document.activeElement && document.activeElement.tagName === 'SELECT') { document.activeElement.blur(); }"
        tabManager.selectedTab?.webView?.evaluateJavaScript(jsBlurSelect, completionHandler: nil)
        syncOnDidEnterBackground(application: application)

        let elapsed = Int(NSDate().timeIntervalSince1970) - foregroundStartTime
        Telemetry.recordEvent(UsageTelemetry.makeEvent(elapsed))
        sendCorePing()
        
        // Cliqz: Clear cache whenever the app goes to background
        var taskId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        taskId = application.beginBackgroundTaskWithExpirationHandler { _ in
            application.endBackgroundTask(taskId)
        }
        self.clearCache()
        application.endBackgroundTask(taskId)
    }
    
    // Cliqz: clear cache if the cache size exceed predified limits
    private func clearCache() {

        let currentMemoryUsage = NSURLCache.sharedURLCache().currentMemoryUsage
        let currentDiskUsage = NSURLCache.sharedURLCache().currentDiskUsage
        
        if currentMemoryUsage > CacheMemoryCapacity || currentDiskUsage > CacheDiskCapacity {
            let cacheClearable = CacheClearable(tabManager: self.tabManager)
            cacheClearable.clear()
        }
    }

    private func syncOnDidEnterBackground(application application: UIApplication) {
        // Short circuit and don't sync if we don't have a syncable account.
        guard self.profile?.hasSyncableAccount() ?? false else {
            return
        }

        self.profile?.syncManager.applicationDidEnterBackground()

        var taskId: UIBackgroundTaskIdentifier = 0
        taskId = application.beginBackgroundTaskWithExpirationHandler { _ in
            log.warning("Running out of background time, but we have a profile shutdown pending.")
            self.profile?.shutdown()
            application.endBackgroundTask(taskId)
        }

        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        self.profile?.syncManager.syncEverything().uponQueue(backgroundQueue) { _ in
            self.profile?.shutdown()
            application.endBackgroundTask(taskId)
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        NightModeHelper.restoreNightModeBrightness((self.profile?.prefs)!, toForeground: false)
        // Cliqz: notify AppStatus that the app will resign active
        AppStatus.sharedInstance.appWillResignActive()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // The reason we need to call this method here instead of `applicationDidBecomeActive`
        // is that this method is only invoked whenever the application is entering the foreground where as 
        // `applicationDidBecomeActive` will get called whenever the Touch ID authentication overlay disappears.
        self.updateAuthenticationInfo()

        // Cliqz: call AppStatus
        AppStatus.sharedInstance.appWillEnterForeground()

        resetForegroundStartTime()

        profile?.reopen()
    }

    private func resetForegroundStartTime() {
        foregroundStartTime = Int(NSDate().timeIntervalSince1970)
    }

    /// Send a telemetry ping if the user hasn't disabled reporting.
    /// We still create and log the ping for non-release channels, but we don't submit it.
    private func sendCorePing() {
        guard let profile = profile where (profile.prefs.boolForKey("settings.sendUsageData") ?? true) else {
            log.debug("Usage sending is disabled. Not creating core telemetry ping.")
            return
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            // The core ping resets data counts when the ping is built, meaning we'll lose
            // the data if the ping doesn't go through. To minimize loss, we only send the
            // core ping if we have an active connection. Until we implement a fault-handling
            // telemetry layer that can resend pings, this is the best we can do.
            guard DeviceInfo.hasConnectivity() else {
                log.debug("No connectivity. Not creating core telemetry ping.")
                return
            }

            let ping = CorePing(profile: profile)
            Telemetry.sendPing(ping)
        }
    }

    private func updateAuthenticationInfo() {
        if let authInfo = KeychainWrapper.authenticationInfo() {
            if !LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
                authInfo.useTouchID = false
                KeychainWrapper.setAuthenticationInfo(authInfo)
            }
        }
    }

    private func setUpWebServer(profile: Profile) {
        let server = WebServer.sharedInstance
        ReaderModeHandlers.register(server, profile: profile)
        ErrorPageHelper.register(server, certStore: profile.certStore)
        AboutHomeHandler.register(server)
        AboutLicenseHandler.register(server)
        SessionRestoreHandler.register(server)

        // Cliqz: Registered trampolineForward to be able to load it via URLRequest
        server.registerMainBundleResource("trampolineForward.html", module: "cliqz")
        
        // Cliqz: starting the navigation extension
        NavigationExtension.start()
        
        // Bug 1223009 was an issue whereby CGDWebserver crashed when moving to a background task
        // catching and handling the error seemed to fix things, but we're not sure why.
        // Either way, not implicitly unwrapping a try is not a great way of doing things
        // so this is better anyway.
        do {
            try server.start()
        } catch let err as NSError {
            log.error("Unable to start WebServer \(err)")
        }
    }

    private func setUserAgent() {
        let firefoxUA = UserAgent.defaultUserAgent()

        // Set the UA for WKWebView (via defaults), the favicon fetcher, and the image loader.
        // This only needs to be done once per runtime. Note that we use defaults here that are
        // readable from extensions, so they can just use the cached identifier.
        let defaults = NSUserDefaults(suiteName: AppInfo.sharedContainerIdentifier())!
        defaults.registerDefaults(["UserAgent": firefoxUA])

        SDWebImageDownloader.sharedDownloader().setValue(firefoxUA, forHTTPHeaderField: "User-Agent")

        // Record the user agent for use by search suggestion clients.
        SearchViewController.userAgent = firefoxUA

        // Some sites will only serve HTML that points to .ico files.
        // The FaviconFetcher is explicitly for getting high-res icons, so use the desktop user agent.
        FaviconFetcher.userAgent = UserAgent.desktopUserAgent()
    }

    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        if let actionId = identifier {
            if let action = SentTabAction(rawValue: actionId) {
                viewURLInNewTab(notification)
                switch(action) {
                case .Bookmark:
                    addBookmark(notification)
                    break
                case .ReadingList:
                    addToReadingList(notification)
                    break
                default:
                    break
                }
			} else {
                print("ERROR: Unknown notification action received")
			}
		} else {
            print("ERROR: Unknown notification received")
		}
	}

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        viewURLInNewTab(notification)
    }

    private func presentEmailComposerWithLogs() {
        if let buildNumber = NSBundle.mainBundle().objectForInfoDictionaryKey(String(kCFBundleVersionKey)) as? NSString {
            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.mailComposeDelegate = self
            mailComposeViewController.setSubject("Debug Info for iOS client version v\(appVersion) (\(buildNumber))")

            if DebugSettingsBundleOptions.attachLogsToDebugEmail {
                do {
                    let logNamesAndData = try Logger.diskLogFilenamesAndData()
                    logNamesAndData.forEach { nameAndData in
                        if let data = nameAndData.1 {
                            mailComposeViewController.addAttachmentData(data, mimeType: "text/plain", fileName: nameAndData.0)
                        }
                    }
                } catch _ {
                    print("Failed to retrieve logs from device")
                }
            }

            if DebugSettingsBundleOptions.attachTabStateToDebugEmail {
                if let tabStateDebugData = TabManager.tabRestorationDebugInfo().dataUsingEncoding(NSUTF8StringEncoding) {
                    mailComposeViewController.addAttachmentData(tabStateDebugData, mimeType: "text/plain", fileName: "tabState.txt")
                }
                if let tabStateData = TabManager.tabArchiveData() {
                    mailComposeViewController.addAttachmentData(tabStateData, mimeType: "application/octet-stream", fileName: "tabsState.archive")
                }
            }

            self.window?.rootViewController?.presentViewController(mailComposeViewController, animated: true, completion: nil)
        }
    }

    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        if let url = userActivity.webpageURL {
            browserViewController.switchToTabForURLOrOpen(url)
            return true
        }
        return false
    }

    private func viewURLInNewTab(notification: UILocalNotification) {
        if let alertURL = notification.userInfo?[TabSendURLKey] as? String {
            if let urlToOpen = NSURL(string: alertURL) {
                browserViewController.navigateToURLInNewTab(urlToOpen)
            }
        }
    }

    private func addBookmark(notification: UILocalNotification) {
        if let alertURL = notification.userInfo?[TabSendURLKey] as? String,
            let title = notification.userInfo?[TabSendTitleKey] as? String {
            let tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: false, url: NSURL(string: alertURL), title: title, favicon: nil)
                browserViewController.addBookmark(tabState)

            // Cliqz: comented Firefox 3D Touch code
//                if #available(iOS 9, *) {
//                    let userData = [QuickActions.TabURLKey: alertURL,
//                        QuickActions.TabTitleKey: title]
//                    QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.OpenLastBookmark, withUserData: userData, toApplication: UIApplication.sharedApplication())
//                }
        }
    }

    private func addToReadingList(notification: UILocalNotification) {
        if let alertURL = notification.userInfo?[TabSendURLKey] as? String,
           let title = notification.userInfo?[TabSendTitleKey] as? String {
            if let urlToOpen = NSURL(string: alertURL) {
                NSNotificationCenter.defaultCenter().postNotificationName(FSReadingListAddReadingListItemNotification, object: self, userInfo: ["URL": urlToOpen, "Title": title])
            }
        }
    }


    // Cliqz: comented Firefox 3D Touch code
//    @available(iOS 9.0, *)
//    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: Bool -> Void) {
//        let handledShortCutItem = QuickActions.sharedInstance.handleShortCutItem(shortcutItem, withBrowserViewController: browserViewController)
//
//        completionHandler(handledShortCutItem)
//    }
}

// MARK: - Root View Controller Animations
extension AppDelegate: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController,
        animationControllerForOperation operation: UINavigationControllerOperation,
        fromViewController fromVC: UIViewController,
        toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            if operation == UINavigationControllerOperation.Push {
                return BrowserToTrayAnimator()
            } else if operation == UINavigationControllerOperation.Pop {
                return TrayToBrowserAnimator()
            } else {
                return nil
            }
    }
}

extension AppDelegate: TabManagerStateDelegate {
    func tabManagerWillStoreTabs(tabs: [Tab]) {
        // It is possible that not all tabs have loaded yet, so we filter out tabs with a nil URL.
        let storedTabs: [RemoteTab] = tabs.flatMap( Tab.toTab )

        // Don't insert into the DB immediately. We tend to contend with more important
        // work like querying for top sites.
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(ProfileRemoteTabsSyncDelay * Double(NSEC_PER_MSEC))), queue) {
            self.profile?.storeTabs(storedTabs)
        }
    }
}

extension AppDelegate: MFMailComposeViewControllerDelegate {
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        // Dismiss the view controller and start the app up
        controller.dismissViewControllerAnimated(true, completion: nil)
        startApplication(application!, withLaunchOptions: self.launchOptions)
    }
}

struct LaunchParams {
    let url: NSURL?
    let isPrivate: Bool?
}
