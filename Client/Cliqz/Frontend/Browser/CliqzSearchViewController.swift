//
//  CliqzSearchViewController.swift
//  BlurredTemptation
//
//  Created by Bogdan Sulima on 20/11/14.
//  Copyright (c) 2014 Cliqz. All rights reserved.
//

import UIKit
import WebKit
import Shared
import Storage

protocol SearchViewDelegate: class {

    func didSelectURL(_ url: URL, searchQuery: String?)
    func searchForQuery(_ query: String)
    func autoCompeleteQuery(_ autoCompleteText: String)
	func dismissKeyboard()
}

let OpenUrlSearchNotification = NSNotification.Name(rawValue: "mobile-search:openUrl")
let CopyValueSearchNotification = NSNotification.Name(rawValue: "mobile-search:copyValue")
let HideKeyboardSearchNotification = NSNotification.Name(rawValue: "mobile-search:hideKeyboard")
let CallSearchNotification = NSNotification.Name(rawValue: "mobile-search:call")
let MapSearchNotification = NSNotification.Name(rawValue: "mobile-search:map")
let ShareLocationSearchNotification = NSNotification.Name(rawValue: "mobile-search:share-location")

class CliqzSearchViewController : UIViewController, LoaderListener, WKNavigationDelegate /*, WKScriptMessageHandler*/, KeyboardHelperDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate  {
	
    fileprivate var searchLoader: SearchLoader!
    fileprivate let cliqzSearch = CliqzSearch()
    
    fileprivate let lastQueryKey = "LastQuery"
    fileprivate let lastURLKey = "LastURL"
    fileprivate let lastTitleKey = "LastTitle"
    
    fileprivate var lastQuery: String?
    
    let searchView = Engine.sharedInstance.rootView

//    var webView: WKWebView?
    lazy var shareCardWebView: WKWebView = {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = false
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = self
        return webView
    }()
    private static let KVOLoading = "loading"
    
    var privateMode = false
    
    var inSelectionMode = false
    
    // for homepanel state because we show the cliqz search as the home panel
    var homePanelState: HomePanelState {
        return HomePanelState(isPrivate: privateMode, selectedIndex: 0)
    }
    
//    lazy var javaScriptBridge: JavaScriptBridge = {
//        let javaScriptBridge = JavaScriptBridge(profile: self.profile)
//        javaScriptBridge.delegate = self
//        return javaScriptBridge
//        }()

	weak var delegate: SearchViewDelegate?

	fileprivate var historyResults: Cursor<Site>?
	
	var searchQuery: String? {
		didSet {
			self.loadData(searchQuery!)
		}
	}
    
    var profile: Profile
    
    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CliqzSearchViewController.showBlockedTopSites(_:)), name: NSNotification.Name(rawValue: NotificationShowBlockedTopSites), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didSelectUrl), name: OpenUrlSearchNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(copyValue), name: CopyValueSearchNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: HideKeyboardSearchNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(call), name: CallSearchNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openMap), name: MapSearchNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shareLocation), name: ShareLocationSearchNotification, object: nil)
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

	override func viewDidLoad() {
		super.viewDidLoad()
        
        self.view.addSubview(searchView)
        self.searchView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }

		KeyboardHelper.defaultHelper.addDelegate(self)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(showOpenSettingsAlert(_:)), name: NSNotification.Name(rawValue: LocationManager.NotificationShowOpenLocationSettingsAlert), object: nil)

    }

    func showOpenSettingsAlert(_ notification: Notification) {
        var message: String!
        var settingsAction: UIAlertAction!
        
        let settingsOptionTitle = NSLocalizedString("Settings", tableName: "Cliqz", comment: "Settings option for turning on location service")
        
        if let locationServicesEnabled = notification.object as? Bool, locationServicesEnabled == true {
            message = NSLocalizedString("To share your location, go to the settings for the CLIQZ app:\n1.Tap Location\n2.Enable 'While Using'", tableName: "Cliqz", comment: "Alert message for turning on location service when clicking share location on local card")
            settingsAction = UIAlertAction(title: settingsOptionTitle, style: .default) { (_) -> Void in
                if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(settingsUrl)
                }
            }
        } else {
            message = NSLocalizedString("To share your location, go to the settings of your smartphone:\n1.Turn on Location Services\n2.Select the CLIQZ App\n3.Enable 'While Using'", tableName: "Cliqz", comment: "Alert message for turning on location service when clicking share location on local card")
            settingsAction = UIAlertAction(title: settingsOptionTitle, style: .default) { (_) -> Void in
                if let settingsUrl = URL(string: "App-Prefs:root=Privacy&path=LOCATION") {
                    UIApplication.shared.openURL(settingsUrl)
                }
            }
        }
        
        let title = NSLocalizedString("Turn on Location Services", tableName: "Cliqz", comment: "Alert title for turning on location service when clicking share location on local card")
        
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        
        let notNowOptionTitle = NSLocalizedString("Not Now", tableName: "Cliqz", comment: "Not now option for turning on location service")
        let cancelAction = UIAlertAction(title: notNowOptionTitle, style: .default, handler: nil)
        
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Engine.sharedInstance.getBridge().setDefaultSearchEngine()
        self.updateExtensionPreferences()
        
        NotificationCenter.default.addObserver(self, selector: #selector(searchWithLastQuery), name: NSNotification.Name(rawValue: LocationManager.NotificationUserLocationAvailable), object: nil)
	}
    
    override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: LocationManager.NotificationUserLocationAvailable), object: nil)
    }

	override func didReceiveMemoryWarning() {
		self.cliqzSearch.clearCache()
	}

	func loader(dataLoaded data: Cursor<Site>) {
		self.historyResults = data
	}
    
    func sendUrlBarFocusEvent() {
        Engine.sharedInstance.getBridge().publishEvent("urlbar-focus", args: [])
    }
/*
	func getHistory() -> Array<Dictionary<String, String>> {
		var results = Array<Dictionary<String, String>>()
		if let r = self.historyResults {
			for site in r {
				var d = Dictionary<String, String>()
				d["url"] = site!.url
				d["title"] = site!.title
				results.append(d)
			}
		}
		return results
	}
*/

	func getHistory() -> NSArray {
		let results = NSMutableArray()
		if let r = self.historyResults {
			for site in r {
				let d: NSDictionary = ["url": site!.url, "title": site!.title]
				results.add(d)
			}
		}
		return NSArray(array: results)
	}

	func isHistoryUptodate() -> Bool {
		return true
	}
    func searchWithLastQuery() {
        if let query = lastQuery {
            search(query)
        }
    }
    
	func loadData(_ query: String) {
        guard query != lastQuery else {
            return
        }
        if query == "" && lastQuery == nil {
            return
        }
        
		search(query)
	}
    
    fileprivate func search(_ query: String) {
        var parameters: Array<Any> = [query.escape()]
        if let l = LocationManager.sharedInstance.getUserLocation() {
            parameters += [true, l.coordinate.latitude, l.coordinate.longitude]
        }
        //self.javaScriptBridge.publishEvent("search", parameters: parameters)
        //TODO: Bridge can return null, so implement a queue, on Engine level.
        Engine.sharedInstance.getBridge().publishEvent("search", args: parameters)
        
        lastQuery = query
    }
    
    func updatePrivateMode(_ privateMode: Bool) {
        if privateMode != self.privateMode {
            self.privateMode = privateMode
			self.updateExtensionPreferences()
        }
    }
    
//    //MARK: - WKWebView Delegate
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        if webView == shareCardWebView {
//            decisionHandler(.allow)
//            return
//        }
//
//        if !navigationAction.request.url!.absoluteString.hasPrefix(NavigationExtension.baseURL) {
////            delegate?.searchView(self, didSelectUrl: navigationAction.request.URL!)
//            decisionHandler(.cancel)
//        }
//        decisionHandler(.allow)
//    }
//
//    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//    }
//
//    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//
//    }
//
//    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        ErrorHandler.handleError(.cliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
//    }
//
//    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        ErrorHandler.handleError(.cliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
//    }
//
//    func userContentController(_ userContentController:  WKUserContentController, didReceive message: WKScriptMessage) {
//        javaScriptBridge.handleJSMessage(message)
//    }
    
	// Mark: AlertViewDelegate
	func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
		switch (buttonIndex) {
		default:
			debugPrint("Unhandled Button Click")
		}
	}

//    fileprivate func layoutSearchEngineScrollView() {
//        let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(self.view) ?? 0
//        if let _ = self.spinnerView.superview {
//            self.spinnerView.snp_makeConstraints { make in
//                make.centerX.equalTo(self.view)
//                make.top.equalTo((self.view.frame.size.height - keyboardHeight) / 2)
//            }
//        }
//    }

	fileprivate func animateSearchEnginesWithKeyboard(_ keyboardState: KeyboardState) {
        self.view.layoutIfNeeded()
	}

	// Mark Keyboard delegate methods
	func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
		animateSearchEnginesWithKeyboard(state)
	}

	func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
	}
	
	func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
		animateSearchEnginesWithKeyboard(state)
	}
	
	fileprivate func updateExtensionPreferences() {
		let isBlocked = SettingsPrefs.shared.getBlockExplicitContentPref()
        let subscriptions = SubscriptionsHandler.sharedInstance.getSubscriptions()
		let params = ["adultContentFilter" : isBlocked ? "moderate" : "liberal",
		              "incognito" : self.privateMode,
                      "backend_country" : self.getCountry(),
                      "suggestionsEnabled"  : QuerySuggestions.isEnabled(),
                      "subscriptions" : subscriptions] as [String : Any]
        
        //javaScriptBridge.publishEvent("notify-preferences", parameters: params)
        Engine.sharedInstance.getBridge().publishEvent("notify-preferences", args: [params])
	}
    fileprivate func getCountry() -> String {
        if let country = SettingsPrefs.shared.getRegionPref() {
            return country
        }
        return SettingsPrefs.shared.getDefaultRegion()
    }
	
    //MARK: - Reset TopSites
    func showBlockedTopSites(_ notification: Notification) {
        Engine.sharedInstance.getBridge().publishEvent("restore-blocked-topsites", args: [])
        //javaScriptBridge.publishEvent("restore-blocked-topsites")
    }
    
    func onLongPress(_ gestureRecognizer: UIGestureRecognizer) {
        inSelectionMode = true
        delegate?.dismissKeyboard()
    }
    
    func onSwipeUp(_ gestureRecognizer: UIGestureRecognizer) {
        delegate?.dismissKeyboard()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK:- Share Card
    func loadShareCardWebView(_ url: URL, frame: CGRect) {
        self.view.addSubview(shareCardWebView)
        shareCardWebView.frame = frame
        shareCardWebView.load(URLRequest(url: url))
        shareCardWebView.addObserver(self, forKeyPath: CliqzSearchViewController.KVOLoading,
                                     options: .new, context: nil)
        
    }
    
    func unLoadShareCardWebView() {
        shareCardWebView.frame = CGRect.zero
        shareCardWebView.removeFromSuperview()
        shareCardWebView.removeObserver(self, forKeyPath: CliqzSearchViewController.KVOLoading)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
        case CliqzSearchViewController.KVOLoading:
            guard let loading = change?[NSKeyValueChangeKey.newKey] as? Bool else { break }
            
            if (!loading) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
                    if let image = self?.shareCardWebView.screenshot(), let title = ShareCardHelper.sharedInstance.currentCardTitle {
                        self?.presentShareCardActivityViewController(title, image: image)
                        self?.unLoadShareCardWebView()
                    }
                })
            }
        default:break
            
        }
    }
    
    func presentShareCardActivityViewController(_ title:String, image: UIImage) {
        guard let data:Data = UIImagePNGRepresentation(image) else {
            return
        }
        let fileName = String(Date.getCurrentMillis())
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(fileName).png")
        do {
            try data.write(to: tempFile)
            var activityItems = [AnyObject]()
            activityItems.append(TitleActivityItemProvider(title: title, activitiesToIgnore: [UIActivityType.init("net.whatsapp.WhatsApp.ShareExtension")]))
            activityItems.append(tempFile as AnyObject)
            
            let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.excludedActivityTypes = [.assignToContact]
            
            activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
                if let target = activityType?.rawValue {
                    TelemetryLogger.sharedInstance.logEvent(.ContextMenu(target, "card_sharing", ["is_success": completed]))
                }
                try? FileManager.default.removeItem(at: tempFile)
            }
            
            present(activityViewController, animated: true, completion: nil)
        } catch _ {
            
        }
    }
    
}

// Handling communications with JavaScript
extension CliqzSearchViewController {

    func appDidEnterBackground(_ lastURL: URL? = nil, lastTitle: String? = nil) {
        LocalDataStore.setObject(lastQuery, forKey: lastQueryKey)

        if lastURL != nil {
            LocalDataStore.setObject(lastURL?.absoluteString, forKey: lastURLKey)
            LocalDataStore.setObject(lastTitle, forKey: lastTitleKey)
        } else {
            LocalDataStore.setObject(nil, forKey: lastURLKey)
            LocalDataStore.setObject(nil, forKey: lastTitleKey)
        }
        
    }    
}



extension CliqzSearchViewController/*: JavaScriptBridgeDelegate*/ {

    
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        //self.webView?.evaluateJavaScript(javaScriptString, completionHandler: completionHandler as! ((Any?, Error?) -> Void)?)
    }
    
    func searchForQuery(_ query: String) {
        delegate?.searchForQuery(query)
    }
    
//    func getSearchHistoryResults(_ query: String?, _ callback: String?) {
//        let fullResults = NSDictionary(objects: [getHistory(), query ?? ""], forKeys: ["results" as NSCopying, "query" as NSCopying])
//        javaScriptBridge.callJSMethod(callback!, parameter: fullResults, completionHandler: nil)
//    }
    
    func autoCompeleteQuery(_ autoCompleteText: String) {
        delegate?.autoCompeleteQuery(autoCompleteText)
    }
    
    func shareCard(_ card: String, title: String, width: Int, height: Int) {
        let screenWidth = Int(UIScreen.main.bounds.width)
        if let url = ShareCardHelper.shareCardURL {
            ShareCardHelper.sharedInstance.currentCard = card
            ShareCardHelper.sharedInstance.currentCardTitle = title
            let cardFrame = CGRect(x: 2*screenWidth, y: 0, width: width, height: height)
            loadShareCardWebView(url, frame: cardFrame)
        }
    }

    func subscribeToNotifications(withType type: String, subType: String, id: String) {
        let notificationType = RemoteNotificationType.subscriptoinNotification(type, subType, id)
        SubscriptionsHandler.sharedInstance.subscribeForRemoteNotification(ofType: notificationType, completionHandler: { [weak self] () -> Void in
            DispatchQueue.main.async {
                self?.updateExtensionPreferences()
                self?.searchWithLastQuery()
            }
        })
    }
    
    func unsubscribeToNotifications(withType type: String, subType: String, id: String) {
        let notificationType = RemoteNotificationType.subscriptoinNotification(type, subType, id)
        SubscriptionsHandler.sharedInstance.unsubscribeForRemoteNotification(ofType: notificationType)
        self.updateExtensionPreferences()
        self.searchWithLastQuery()
    }
    
    private func migrateQueries() {
        let isQueriesMigratedKey = "Queries-Migrated"
        guard LocalDataStore.objectForKey(isQueriesMigratedKey) == nil else {
            return
        }
        
//        self.webView?.evaluateJavaScript("JSON.parse(localStorage.recentQueries || '[]')", completionHandler: { [weak self] (result, error) in
//            if let queriesMetaData = result as? [[String: Any]] {
//                self?.profile.insertPatchQueries(queriesMetaData)
//            }
//        })
        
        
        LocalDataStore.setObject(true, forKey: isQueriesMigratedKey)
    }
}


//handle Search Events
extension CliqzSearchViewController {
    
    @objc func didSelectUrl(_ notification: Notification) {
        if let url_str = notification.object as? String, let url = URL(string: url_str) {
            if !inSelectionMode {
                delegate?.didSelectURL(url, searchQuery: self.searchQuery)
            } else {
                inSelectionMode = false
            }
        }
    }
    
    @objc func hideKeyboard(_ notification: Notification) {
        delegate?.dismissKeyboard()
    }
    
    @objc func copyValue(_ notification: Notification) {
        if let result = notification.object as? String {
            UIPasteboard.general.string = result
        }
    }
    
    @objc func call(_ notification: Notification) {
        if let number = notification.object as? String {
            self.callPhoneNumber(number)
        }
    }
    
    @objc func openMap(_ notification: Notification) {
        if let url = notification.object as? String {
            self.openGoogleMaps(url)
        }
    }
    
    @objc func shareLocation(_ notification: Notification) {
        LocationManager.sharedInstance.shareLocation()
    }
    
    fileprivate func callPhoneNumber(_ phoneNumber: String) {
        let trimmedPhoneNumber = phoneNumber.removeWhitespaces()
        if let url = URL(string: "tel://\(trimmedPhoneNumber)") {
            UIApplication.shared.openURL(url)
        }
    }
    
    fileprivate func openGoogleMaps(_ url: String) {
        if let mapURL = URL(string:url) {
            delegate?.didSelectURL(mapURL, searchQuery: nil)
        }
    }
}

