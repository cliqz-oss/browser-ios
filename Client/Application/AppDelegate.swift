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
import CRToast

import React

private let log = Logger.browserLogger

let LatestAppVersionProfileKey = "latestAppVersion"
let AllowThirdPartyKeyboardsKey = "settings.allowThirdPartyKeyboards"
private let InitialPingSentKey = "initialPingSent"

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    struct LaunchParams {
        let url: URL?
        let isPrivate: Bool?
    }

    
    var window: UIWindow?

    var rootViewController: UINavigationController!
    weak var profile: BrowserProfile?
    var tabManager: TabManager!
    var adjustIntegration: AdjustIntegration?
    var foregroundStartTime = 0

    weak var application: UIApplication?
    var launchOptions: [AnyHashable: Any]?

    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

    var openInFirefoxParams: LaunchParams? = nil

    var appStateStore: AppStateStore!

    var systemBrightness: CGFloat = UIScreen.main.brightness
  //Cliqz: capacity limits for URLCache
    let CacheMemoryCapacity = 8 * 1024 * 1024
    let CacheDiskCapacity   = 50 * 1024 * 1024

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        AppStatus.sharedInstance.appWillFinishLaunching()
        
        //Cliqz: Configure URL Cache; set memoryCapacity to 8MB, and diskCapacity to 50MB
        let urlCache = URLCache(memoryCapacity: CacheMemoryCapacity, diskCapacity: CacheDiskCapacity, diskPath: nil)
        URLCache.shared = urlCache

        
        // Hold references to willFinishLaunching parameters for delayed app launch
        self.application = application
        self.launchOptions = launchOptions

        log.debug("Configuring window…")

        self.window = CliqzMainWindow(frame: UIScreen.main.bounds)
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

	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let deviceTokenString = "\(deviceToken)"
			.trimmingCharacters(in: CharacterSet(charactersIn:"<>"))
			.replacingOccurrences(of: " ", with: "")
		AWSSNSManager.createPlatformEndpoint(deviceTokenString)
	}

	func application(_ application: UIApplication,didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print("Register for Notifications is failed with error: \(error)")
	}

    fileprivate func startApplication(_ application: UIApplication,  withLaunchOptions launchOptions: [AnyHashable: Any]?) -> Bool {
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
//        let logDate = Date()
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
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
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
        
        let viewController = MainContainerViewController()

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.delegate = self
        navigationController.isNavigationBarHidden = true

        rootViewController = navigationController

        self.window!.rootViewController = navigationController
        
        self.window?.backgroundColor = UIColor.red
        self.window?.rootViewController?.view.backgroundColor = UIColor.green

        // Cliqz: disable crash reporting
//        do {
//            log.debug("Configuring Crash Reporting...")
//            try PLCrashReporter.sharedReporter().enableCrashReporterAndReturnError()
//        } catch let error as NSError {
//            log.error("Failed to enable PLCrashReporter - \(error.description)")
//        }

        log.debug("Adding observers…")
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FSReadingListAddReadingListItem, object: nil, queue: nil) { (notification) -> Void in
            if let userInfo = notification.userInfo, let url = userInfo["URL"] as? URL {
                let title = (userInfo["Title"] as? String) ?? ""
                profile.readingList?.createRecordWithURL(url.absoluteString, title: title, addedBy: UIDevice.current.name)
            }
        }

        // check to see if we started 'cos someone tapped on a notification.
//        if let localNotification = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification {
//            viewURLInNewTab(localNotification)
//        }
        
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
        
        //NotificationCenter.default.addObserver(self, selector: #selector(allNotifications), name: nil, object: nil)
		
        log.debug("Done with setting up the application.")

        return true
    }
    
    @objc func allNotifications(_ notification: Notification) {
        debugPrint(notification.name)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        log.debug("Application will terminate.")
		
		// We have only five seconds here, so let's hope this doesn't take too long.
        self.profile?.shutdown()

        // Allow deinitializers to close our database connections.
        self.profile = nil
        self.tabManager = nil
        self.rootViewController = nil

        AppStatus.sharedInstance.appWillTerminate()
        
        CIReminderManager.sharedInstance.saveState()
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
    func getProfile(_ application: UIApplication) -> Profile {
        if let profile = self.profile {
            return profile
        }
        let p = BrowserProfile(localName: "profile", app: application)
        self.profile = p
        return p
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        AppStatus.sharedInstance.appDidFinishLaunching()
        
        //UIApplication.shared.cancelAllLocalNotifications()

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
        Crashlytics.sharedInstance().delegate = self
        Fabric.with([Crashlytics.self])

        
        // Cliqz: Added Lookback integration
#if BETA
//		Lookback.setupWithAppToken("HWiD4ErSbeNy9JcRg")
//		Lookback.sharedLookback().shakeToRecord = true
//		Lookback.sharedLookback() = false
#endif
        // Configure AntiTracking/AdBlocking Module
        AntiTrackingModule.sharedInstance.initModule()
        AdblockingModule.sharedInstance.initModule()
        
        //Init Reminder Manager
        _ = CIReminderManager.sharedInstance
        
        //Register for local notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
        
        log.debug("Done with applicationDidFinishLaunching.")
        
        if let notification = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification {
            handleLocalNotification(notification: notification, startUp: true)
        }
		application.applicationSupportsShakeToEdit = true
        return shouldPerformAdditionalDelegateHandling
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject],
                let urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String] else {
            // Something very strange has happened; org.mozilla.Client should be the zeroeth URL type.
            log.error("Custom URL schemes not available for validating")
            return false
        }

        guard let scheme = components.scheme, urlSchemes.contains(scheme) else {
            log.warning("Cannot handle \(String(describing: components.scheme)) URL scheme")
            return false
        }

        var url: String?
        var isPrivate: Bool = false
        for item in (components.queryItems ?? []) as [URLQueryItem] {
            switch item.name {
            case "url":
                url = item.value
            case "private":
                isPrivate = NSString(string: item.value ?? "false").boolValue
            default: ()
            }
        }

        let params: LaunchParams

        if let url = url, let newURL = URL(string: url) {
            params = LaunchParams(url: newURL, isPrivate: isPrivate)
        } else {
            params = LaunchParams(url: nil, isPrivate: isPrivate)
        }

        if application.applicationState == .active {
            // If we are active then we can ask the BVC to open the new tab right away. 
            // Otherwise, we remember the URL and we open it in applicationDidBecomeActive.
            launchFromURL(params)
        } else {
            openInFirefoxParams = params
        }

        return true
    }

    func launchFromURL(_ params: LaunchParams) {
        StateManager.shared.handleAction(action: Action(data: ["url": params.url?.absoluteString as Any], type: .urlSelected))
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplicationExtensionPointIdentifier) -> Bool {
		return false
    }

    // We sync in the foreground only, to avoid the possibility of runaway resource usage.
    // Eventually we'll sync in response to notifications.
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        AppStatus.sharedInstance.appDidBecomeActive(self.profile!)

        guard !DebugSettingsBundleOptions.launchIntoEmailComposer else {
            return
        }

        NightModeHelper.restoreNightModeBrightness((self.profile?.prefs)!, toForeground: true)
        //self.profile?.syncManager.applicationDidBecomeActive()

        // Check if we have a URL from an external app or extension waiting to launch,
        // then launch it on the main thread.
        if let params = openInFirefoxParams {
            openInFirefoxParams = nil
            DispatchQueue.main.async {
                self.launchFromURL(params)
            }
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {

        // Cliq: notify the AppStatus that the app entered background
        AppStatus.sharedInstance.appDidEnterBackground()
        
        // Workaround for crashing in the background when <select> popovers are visible (rdar://24571325).
        let jsBlurSelect = "if (document.activeElement && document.activeElement.tagName === 'SELECT') { document.activeElement.blur(); }"
        tabManager.selectedTab?.webView?.evaluateJavaScript(jsBlurSelect, completionHandler: nil)
        //syncOnDidEnterBackground(application: application)

        let elapsed = Int(Date().timeIntervalSince1970) - foregroundStartTime
        Telemetry.recordEvent(UsageTelemetry.makeEvent(elapsed))
        sendCorePing()
        
        // Cliqz: Clear cache whenever the app goes to background
        var taskId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        taskId = application.beginBackgroundTask { _ in
            application.endBackgroundTask(taskId)
        }
        self.clearCache()
        application.endBackgroundTask(taskId)
        
        CIReminderManager.sharedInstance.saveState()
    }
    
    // Cliqz: clear cache if the cache size exceed predified limits
    private func clearCache() {

        let currentMemoryUsage = URLCache.shared.currentMemoryUsage
        let currentDiskUsage = URLCache.shared.currentDiskUsage
        
        if currentMemoryUsage > CacheMemoryCapacity || currentDiskUsage > CacheDiskCapacity {
            let cacheClearable = CacheClearable(tabManager: self.tabManager)
            _ = cacheClearable.clear()
        }
    }

//    fileprivate func syncOnDidEnterBackground(application: UIApplication) {
//        // Short circuit and don't sync if we don't have a syncable account.
//        guard self.profile?.hasSyncableAccount() ?? false else {
//            return
//        }
//
////        self.profile?.syncManager.applicationDidEnterBackground()
//
//        var taskId: UIBackgroundTaskIdentifier = 0
//        taskId = application.beginBackgroundTask (expirationHandler: { _ in
//            log.warning("Running out of background time, but we have a profile shutdown pending.")
//            self.profile?.shutdown()
//            application.endBackgroundTask(taskId)
//        })
//
////        let backgroundQueue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background)
////        self.profile?.syncManager.syncEverything().uponQueue(backgroundQueue) { _ in
////            self.profile?.shutdown()
////            application.endBackgroundTask(taskId)
////        }
//    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        NightModeHelper.restoreNightModeBrightness((self.profile?.prefs)!, toForeground: false)
        // Cliqz: notify AppStatus that the app will resign active
        AppStatus.sharedInstance.appWillResignActive()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // The reason we need to call this method here instead of `applicationDidBecomeActive`
        // is that this method is only invoked whenever the application is entering the foreground where as 
        // `applicationDidBecomeActive` will get called whenever the Touch ID authentication overlay disappears.
        self.updateAuthenticationInfo()
        
        CIReminderManager.sharedInstance.refresh()

        // Cliqz: call AppStatus
        AppStatus.sharedInstance.appWillEnterForeground()

        resetForegroundStartTime()

        profile?.reopen()
    }
    

    fileprivate func resetForegroundStartTime() {
        foregroundStartTime = Int(Date().timeIntervalSince1970)
    }

    /// Send a telemetry ping if the user hasn't disabled reporting.
    /// We still create and log the ping for non-release channels, but we don't submit it.
    fileprivate func sendCorePing() {
        guard let profile = profile, (profile.prefs.boolForKey("settings.sendUsageData") ?? true) else {
            log.debug("Usage sending is disabled. Not creating core telemetry ping.")
            return
        }

        DispatchQueue(label: "background").async {
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

    fileprivate func updateAuthenticationInfo() {
        if let authInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo() {
            if !LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                authInfo.useTouchID = false
                KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(authInfo)
            }
        }
    }

    fileprivate func setUpWebServer(_ profile: Profile) {
        let server = WebServer.sharedInstance
        ReaderModeHandlers.register(server, profile: profile)
        ErrorPageHelper.register(server, certStore: profile.certStore)
        AboutHomeHandler.register(server)
        AboutLicenseHandler.register(server)
        SessionRestoreHandler.register(server)

        // Cliqz: Registered trampolineForward to be able to load it via URLRequest
        //server.registerMainBundleResource("trampolineForward.html", module: "cliqz")
        
        // Cliqz: starting the navigation extension
        NavigationExtension.start()
        
        // Bug 1223009 was an issue whereby CGDWebserver crashed when moving to a background task
        // catching and handling the error seemed to fix things, but we're not sure why.
        // Either way, not implicitly unwrapping a try is not a great way of doing things
        // so this is better anyway.
        do {
            try _ = server.start()
        } catch let err as NSError {
            log.error("Unable to start WebServer \(err)")
        }
    }

    fileprivate func setUserAgent() {
        let firefoxUA = UserAgent.defaultUserAgent()

        // Set the UA for WKWebView (via defaults), the favicon fetcher, and the image loader.
        // This only needs to be done once per runtime. Note that we use defaults here that are
        // readable from extensions, so they can just use the cached identifier.
        let defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier())!
        defaults.register(defaults: ["UserAgent": firefoxUA])

        SDWebImageDownloader.shared().setValue(firefoxUA, forHTTPHeaderField: "User-Agent")

        // Record the user agent for use by search suggestion clients.
        SearchViewController.userAgent = firefoxUA

        // Some sites will only serve HTML that points to .ico files.
        // The FaviconFetcher is explicitly for getting high-res icons, so use the desktop user agent.
        FaviconFetcher.userAgent = UserAgent.desktopUserAgent()
    }

    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
//        if let actionId = identifier {
//            if let action = SentTabAction(rawValue: actionId) {
//                viewURLInNewTab(notification)
//                switch(action) {
//                case .Bookmark:
//                    addBookmark(notification)
//                    break
//                case .ReadingList:
//                    addToReadingList(notification)
//                    break
//                default:
//                    break
//                }
//            } else {
//                print("ERROR: Unknown notification action received")
//            }
//        } else {
//            print("ERROR: Unknown notification received")
//        }
	}

    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        handleLocalNotification(notification: notification, startUp: false)
    }
    
    func handleLocalNotification(notification: UILocalNotification, startUp: Bool) {
        if let dict = notification.userInfo, let isReminder = dict["isReminder"] as? Bool {
            if isReminder {
                guard let url = dict["url"] as? String else {return}
                let title = dict["title"] as? String ?? ""
                CIReminderManager.sharedInstance.reminderFired(url_str: url, date: notification.fireDate, title: title)
                
                if UIApplication.shared.applicationState == .active {
                    presentReminderToast(title: title, url: url)
                }
                else {
                    let extend = startUp ? 2.0 : 0.5
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + extend, execute: {
                        self.specialOpenUrl(url: url)
                    })
                }
                
                return
            }
        }
        //viewURLInNewTab(notification)
    }

}

//Util - Reminder notifications
extension AppDelegate {
    
    func specialOpenUrl(url:String) {
        StateManager.shared.handleAction(action: Action(data: ["url": url], type: .urlSelected, actionFlag: .isReminder))
        //notification pressed
        CIReminderManager.sharedInstance.reminderPressed(url_str: url)
    }
    
    func presentReminderToast(title: String, url: String) {
        
        let defaultOptions : [AnyHashable: Any] = [
            kCRToastTextAlignmentKey : NSNumber(value: NSTextAlignment.left.rawValue),
            kCRToastNotificationTypeKey: NSNumber(value: CRToastType.navigationBar.rawValue),
            kCRToastNotificationPresentationTypeKey: NSNumber(value: CRToastPresentationType.cover.rawValue),
            kCRToastAnimationInTypeKey : NSNumber(value: CRToastAnimationType.linear.rawValue),
            kCRToastAnimationOutTypeKey : NSNumber(value: CRToastAnimationType.linear.rawValue),
            kCRToastAnimationInDirectionKey : NSNumber(value: CRToastAnimationDirection.top.rawValue),
            kCRToastAnimationOutDirectionKey : NSNumber(value: CRToastAnimationDirection.top.rawValue),
            kCRToastImageAlignmentKey: NSNumber(value: CRToastAccessoryViewAlignment.left.rawValue)
        ]
        
        let tapInteraction = CRToastInteractionResponder.init(interactionType: .tap, automaticallyDismiss: true) { (tap) in
            self.specialOpenUrl(url: url)
        }
        
        var options : [AnyHashable: Any] = [kCRToastTextKey: CIReminderManager.alertBody(url: url, title: title)]
        
        options[kCRToastBackgroundColorKey] = UIColor(colorString: "24262f")
        options[kCRToastInteractionRespondersKey] = [tapInteraction]
        options[kCRToastImageKey] = UIImage(named:"notificationImg")!
        options[kCRToastTextColorKey] = UIColor.white
        options[kCRToastTimeIntervalKey] = 4
        
        // copy default options to the current options dictionary
        defaultOptions.forEach { options[$0] = $1 }
        
        DispatchQueue.main.async {
            CRToastManager.showNotification(options: options, completionBlock: nil)
        }
    }
    
    func presentActionSheet(title: String?, message: String?, actions:[UIAlertAction]) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        //there must be at least a cancel action...check still to be implemented.
        for action in actions {
            controller.addAction(action)
        }
        
        
        presentContollerOnTop(controller: controller)
    }
    
    fileprivate func presentEmailComposerWithLogs() {
        if let buildNumber = Bundle.main.object(forInfoDictionaryKey: String(kCFBundleVersionKey)) as? NSString {
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
                if let tabStateDebugData = TabManager.tabRestorationDebugInfo().data(using: String.Encoding.utf8) {
                    mailComposeViewController.addAttachmentData(tabStateDebugData, mimeType: "text/plain", fileName: "tabState.txt")
                }
                if let tabStateData = TabManager.tabArchiveData() {
                    mailComposeViewController.addAttachmentData(tabStateData as Data, mimeType: "application/octet-stream", fileName: "tabsState.archive")
                }
            }
            
            self.window?.rootViewController?.present(mailComposeViewController, animated: true, completion: nil)
        }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        return true
    }

}

//Util
extension AppDelegate {
    func presentContollerOnTop(controller: UIViewController) {
        
        var rootViewController = UIApplication.shared.keyWindow?.rootViewController
        if let navigationController = rootViewController as? UINavigationController {
            rootViewController = navigationController.viewControllers.first
        }
        if let tabBarController = rootViewController as? UITabBarController {
            rootViewController = tabBarController.selectedViewController
        }
        rootViewController?.present(controller, animated: true, completion: nil)
    }
}

// MARK: - Root View Controller Animations
extension AppDelegate: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationControllerOperation,
        from fromVC: UIViewController,
        to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            if operation == UINavigationControllerOperation.push {
                return BrowserToTrayAnimator()
            } else if operation == UINavigationControllerOperation.pop {
                return TrayToBrowserAnimator()
            } else {
                return nil
            }
    }
}

extension AppDelegate: TabManagerStateDelegate {
    func tabManagerWillStoreTabs(_ tabs: [Tab]) {

    }
}

extension AppDelegate: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss the view controller and start the app up
        controller.dismiss(animated: true, completion: nil)
        _ = startApplication(application!, withLaunchOptions: self.launchOptions)
    }
}

extension AppDelegate: CrashlyticsDelegate {
    func crashlyticsDidDetectReport(forLastExecution report: CLSReport, completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .default).async {
            completionHandler(true)
        }
    }
}
