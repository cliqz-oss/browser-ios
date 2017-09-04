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

class CliqzSearchViewController : UIViewController, LoaderListener, WKNavigationDelegate, WKScriptMessageHandler, KeyboardHelperDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate  {
	
    fileprivate var searchLoader: SearchLoader!
    fileprivate let cliqzSearch = CliqzSearch()
    
    fileprivate let lastQueryKey = "LastQuery"
    fileprivate let lastURLKey = "LastURL"
    fileprivate let lastTitleKey = "LastTitle"
    
    fileprivate var lastQuery: String?

	var webView: WKWebView?
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
    
    lazy var javaScriptBridge: JavaScriptBridge = {
        let javaScriptBridge = JavaScriptBridge(profile: self.profile)
        javaScriptBridge.delegate = self
        return javaScriptBridge
        }()

	weak var delegate: SearchViewDelegate?

	fileprivate var spinnerView: UIActivityIndicatorView!

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
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationShowBlockedTopSites), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: LocationManager.NotificationShowOpenLocationSettingsAlert), object: nil)
    }

	override func viewDidLoad() {
		super.viewDidLoad()

        let config = ConfigurationManager.sharedInstance.getSharedConfiguration(self)

        self.webView = WKWebView(frame: self.view.bounds, configuration: config)
		self.webView?.navigationDelegate = self
        self.webView?.scrollView.isScrollEnabled = false
        self.webView?.accessibilityLabel = "Web content"
        self.view.addSubview(self.webView!)
        

        self.webView!.snp_makeConstraints { make in
            make.top.equalTo(0)
            make.bottom.left.right.equalTo(self.view)
        }
        
        
		self.spinnerView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
		self.view.addSubview(spinnerView)
		spinnerView.startAnimating()

		KeyboardHelper.defaultHelper.addDelegate(self)
		layoutSearchEngineScrollView()
        addGuestureRecognizers()
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(CliqzSearchViewController.fixViewport), name: NSNotification.Name.UIDeviceOrientationDidChange, object: UIDevice.current)
        
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

    func fixViewport() {
        if #available(iOS 9.0, *) {
            return
        }

        var currentWidth = "device-width"
        var currentHeight = "device-height"
        if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
            currentWidth = "device-height"
            currentHeight = "device-width"
        }
        if let path = Bundle.main.path(forResource: "viewport", ofType: "js"), let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
            var modifiedSource = source.replacingOccurrences(of: "device-height", with: currentHeight)
            modifiedSource = modifiedSource.replacingOccurrences(of: "device-width", with: currentWidth)
            
            
            self.webView?.evaluateJavaScript(modifiedSource, completionHandler: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        javaScriptBridge.setDefaultSearchEngine()
        self.updateExtensionPreferences()
		if self.webView?.url == nil {
			loadExtension()
		}
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(searchWithLastQuery), name: NSNotification.Name(rawValue: LocationManager.NotificationUserLocationAvailable), object: nil)
	}

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.javaScriptBridge.publishEvent("show")
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
        self.javaScriptBridge.publishEvent("urlbar-focus")
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
        let q = query.trimmingCharacters(in: CharacterSet.whitespaces)
        var parameters = "'\(q.escape())'"
        if let l = LocationManager.sharedInstance.getUserLocation() {
            parameters += ", true, \(l.coordinate.latitude), \(l.coordinate.longitude)"
        }
        self.javaScriptBridge.publishEvent("search", parameters: parameters)
        
        lastQuery = query
    }
    
    func updatePrivateMode(_ privateMode: Bool) {
        if privateMode != self.privateMode {
            self.privateMode = privateMode
			self.updateExtensionPreferences()
        }
    }
    
    //MARK: - WKWebView Delegate
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if webView == shareCardWebView {
            decisionHandler(.allow)
            return
        }
        
		if !navigationAction.request.url!.absoluteString.hasPrefix(NavigationExtension.baseURL) {
//			delegate?.searchView(self, didSelectUrl: navigationAction.request.URL!)
			decisionHandler(.cancel)
		}
		decisionHandler(.allow)
	}

	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

    }

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        ErrorHandler.handleError(.cliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
	}

	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		ErrorHandler.handleError(.cliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
	}

	func userContentController(_ userContentController:  WKUserContentController, didReceive message: WKScriptMessage) {
		javaScriptBridge.handleJSMessage(message)
	}
    
	// Mark: AlertViewDelegate
	func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
		switch (buttonIndex) {
		case 0:
			stopLoadingAnimation()
		case 1:
			loadExtension()
		default:
			debugPrint("Unhandled Button Click")
		}
	}

	fileprivate func layoutSearchEngineScrollView() {
		let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(self.view) ?? 0
		if let _ = self.spinnerView.superview {
			self.spinnerView.snp_makeConstraints { make in
				make.centerX.equalTo(self.view)
				make.top.equalTo((self.view.frame.size.height - keyboardHeight) / 2)
			}
		}
	}

	fileprivate func animateSearchEnginesWithKeyboard(_ keyboardState: KeyboardState) {
		layoutSearchEngineScrollView()
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

	fileprivate func loadExtension() {
		let url = URL(string: NavigationExtension.indexURL)
		self.webView!.load(URLRequest(url: url!))
	}

	fileprivate func stopLoadingAnimation() {
		self.spinnerView.removeFromSuperview()
		self.spinnerView.stopAnimating()
	}
	
	fileprivate func updateExtensionPreferences() {
		let isBlocked = SettingsPrefs.getBlockExplicitContentPref()
		let params = ["adultContentFilter" : isBlocked ? "moderate" : "liberal",
		              "incognito" : self.privateMode,
                      "backend_country" : self.getCountry(),
                      "suggestionsEnabled"  : QuerySuggestions.isEnabled()] as [String : Any]
        
        javaScriptBridge.publishEvent("notify-preferences", parameters: params)
	}
    fileprivate func getCountry() -> String {
        if let country = SettingsPrefs.getRegionPref() {
            return country
        }
        return SettingsPrefs.getDefaultRegion()
    }
	
    //MARK: - Reset TopSites
    func showBlockedTopSites(_ notification: Notification) {
        javaScriptBridge.publishEvent("restore-blocked-topsites")
    }
    
    //MARK: - Guestures
    func addGuestureRecognizers() {
        // longPress gesture recognizer
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(CliqzSearchViewController.onLongPress(_:)))
        longPressGestureRecognizer.delegate = self
        self.webView?.addGestureRecognizer(longPressGestureRecognizer)
        
        
        // swiper up gesture recognizer
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(CliqzSearchViewController.onSwipeUp(_:)))
        swipeGestureRecognizer.direction = .up
        swipeGestureRecognizer.delegate = self
        self.webView?.addGestureRecognizer(swipeGestureRecognizer)
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
        let fileName = generateTempFileName(title)
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(fileName).png")
        do {
            try data.write(to: tempFile)
            var activityItems = [AnyObject]()
            activityItems.append(TitleActivityItemProvider(title: title))
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
    private func generateTempFileName(_ title: String) -> String {
        var fileName = title
        fileName = fileName.replace(" ", replacement: "_")
        fileName = fileName.replace("...", replacement: "")
        if fileName.contains("\n") {
           fileName = fileName.components(separatedBy: "\n")[1]
        }
        return fileName
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

extension CliqzSearchViewController: JavaScriptBridgeDelegate {
    
    func didSelectUrl(_ url: URL) {
        if !inSelectionMode {
            delegate?.didSelectURL(url, searchQuery: self.searchQuery)
        } else {
            inSelectionMode = false
        }
    }
    
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        self.webView?.evaluateJavaScript(javaScriptString, completionHandler: completionHandler as! ((Any?, Error?) -> Void)?)
    }
    
    func searchForQuery(_ query: String) {
        delegate?.searchForQuery(query)
    }
    
	func getSearchHistoryResults(_ query: String?, _ callback: String?) {
		let fullResults = NSDictionary(objects: [getHistory(), query ?? ""], forKeys: ["results" as NSCopying, "query" as NSCopying])
        javaScriptBridge.callJSMethod(callback!, parameter: fullResults, completionHandler: nil)
    }
    
    func autoCompeleteQuery(_ autoCompleteText: String) {
        delegate?.autoCompeleteQuery(autoCompleteText)
    }
	
	func isReady() {
        stopLoadingAnimation()
		self.sendUrlBarFocusEvent()
		javaScriptBridge.setDefaultSearchEngine()
		self.updateExtensionPreferences()
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

}
