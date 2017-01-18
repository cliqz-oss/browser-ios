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

    func didSelectURL(url: NSURL, searchQuery: String?)
    func searchForQuery(query: String)
    func autoCompeleteQuery(autoCompleteText: String)
	func dismissKeyboard()
}

class CliqzSearchViewController : UIViewController, LoaderListener, WKNavigationDelegate, WKScriptMessageHandler, KeyboardHelperDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate  {
	
    private var searchLoader: SearchLoader!
    private let cliqzSearch = CliqzSearch()
    
    private let lastQueryKey = "LastQuery"
    private let lastURLKey = "LastURL"
    private let lastTitleKey = "LastTitle"
    
    private var lastQuery: String?

	var webView: WKWebView?
    
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

	private var spinnerView: UIActivityIndicatorView!

	private var historyResults: Cursor<Site>?
	
	var searchQuery: String? {
		didSet {
			self.loadData(searchQuery!)
		}
	}
    
    var profile: Profile
    
    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CliqzSearchViewController.showBlockedTopSites(_:)), name: NotificationShowBlockedTopSites, object: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationShowBlockedTopSites, object: nil)
    }

	override func viewDidLoad() {
		super.viewDidLoad()

        let config = ConfigurationManager.sharedInstance.getSharedConfiguration(self)

        self.webView = WKWebView(frame: self.view.bounds, configuration: config)
		self.webView?.navigationDelegate = self
        self.webView?.scrollView.scrollEnabled = false
        self.webView?.accessibilityLabel = "Web content"

        self.view.addSubview(self.webView!)
        

        self.webView!.snp_makeConstraints { make in
            make.top.equalTo(0)
            make.bottom.left.right.equalTo(self.view)
        }
        
		self.spinnerView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
		self.view.addSubview(spinnerView)
		spinnerView.startAnimating()

		KeyboardHelper.defaultHelper.addDelegate(self)
		layoutSearchEngineScrollView()
        addGuestureRecognizers()
        
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CliqzSearchViewController.fixViewport), name: UIDeviceOrientationDidChangeNotification, object: UIDevice.currentDevice())

    }

    func fixViewport() {
        if #available(iOS 9.0, *) {
            return
        }

        var currentWidth = "device-width"
        var currentHeight = "device-height"
        if UIDevice.currentDevice().orientation == .LandscapeLeft || UIDevice.currentDevice().orientation == .LandscapeRight {
            currentWidth = "device-height"
            currentHeight = "device-width"
        }
        if let path = NSBundle.mainBundle().pathForResource("viewport", ofType: "js"), source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
            var modifiedSource = source.stringByReplacingOccurrencesOfString("device-height", withString: currentHeight)
            modifiedSource = modifiedSource.stringByReplacingOccurrencesOfString("device-width", withString: currentWidth)
            
            
            self.webView?.evaluateJavaScript(modifiedSource, completionHandler: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        javaScriptBridge.setDefaultSearchEngine()
		self.sendUrlBarFocusEvent()
		if self.webView?.URL == nil {
			loadExtension()
		}
	}

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.javaScriptBridge.publishEvent("show")
        self.updateExtensionPreferences()
    }
    
    override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
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
				results.addObject(d)
			}
		}
		return NSArray(array: results)
	}

	func isHistoryUptodate() -> Bool {
		return true
	}
	
	func loadData(query: String) {
        guard query != lastQuery else {
            return
        }
        if query == "" && lastQuery == nil {
            return
        }
        
		let q = query.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
		var parameters = "'\(q)'"
		if let l = LocationManager.sharedInstance.location {
			parameters += ", true, \(l.coordinate.latitude), \(l.coordinate.longitude)"
		}
        self.javaScriptBridge.publishEvent("search", parameters: parameters)

        lastQuery = query
	}
    
    func updatePrivateMode(privateMode: Bool) {
        if privateMode != self.privateMode {
            self.privateMode = privateMode
			self.updateExtensionPreferences()
        }
    }
    
    //MARK: - WKWebView Delegate
	func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
		if !navigationAction.request.URL!.absoluteString!.hasPrefix(NavigationExtension.baseURL) {
//			delegate?.searchView(self, didSelectUrl: navigationAction.request.URL!)
			decisionHandler(.Cancel)
		}
		decisionHandler(.Allow)
	}

	func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
	}

	func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {

    }

	func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
	}

	func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
		ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
	}

	func userContentController(userContentController:  WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		javaScriptBridge.handleJSMessage(message)
	}

	// Mark: AlertViewDelegate
	func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
		switch (buttonIndex) {
		case 0:
			stopLoadingAnimation()
		case 1:
			loadExtension()
		default:
			print("Unhandled Button Click")
		}
	}

	private func layoutSearchEngineScrollView() {
		let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(self.view) ?? 0
		if let _ = self.spinnerView.superview {
			self.spinnerView.snp_makeConstraints { make in
				make.centerX.equalTo(self.view)
				make.top.equalTo((self.view.frame.size.height - keyboardHeight) / 2)
			}
		}
	}

	private func animateSearchEnginesWithKeyboard(keyboardState: KeyboardState) {
		layoutSearchEngineScrollView()
        self.view.layoutIfNeeded()
	}

	// Mark Keyboard delegate methods
	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
		animateSearchEnginesWithKeyboard(state)
	}

	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
	}
	
	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
		animateSearchEnginesWithKeyboard(state)
	}

	private func loadExtension() {
		let url = NSURL(string: NavigationExtension.indexURL)
		self.webView!.loadRequest(NSURLRequest(URL: url!))
	}

	private func stopLoadingAnimation() {
		self.spinnerView.removeFromSuperview()
		self.spinnerView.stopAnimating()
	}
	
	private func updateExtensionPreferences() {
		let isBlocked = SettingsPrefs.getBlockExplicitContentPref()
		let params = ["adultContentFilter" : isBlocked ? "moderate" : "liberal",
		              "incognito" : self.privateMode]
        javaScriptBridge.publishEvent("notify-preferences", parameters: params)
	}

    //MARK: - Reset TopSites
    func showBlockedTopSites(notification: NSNotification) {
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
        swipeGestureRecognizer.direction = .Up
        swipeGestureRecognizer.delegate = self
        self.webView?.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    func onLongPress(gestureRecognizer: UIGestureRecognizer) {
        inSelectionMode = true
        delegate?.dismissKeyboard()
    }
    
    func onSwipeUp(gestureRecognizer: UIGestureRecognizer) {
        delegate?.dismissKeyboard()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// Handling communications with JavaScript
extension CliqzSearchViewController {

    func appDidEnterBackground(lastURL: NSURL? = nil, lastTitle: String? = nil) {
        LocalDataStore.setObject(lastQuery, forKey: lastQueryKey)

        if lastURL != nil {
            LocalDataStore.setObject(lastURL?.absoluteString, forKey: lastURLKey)
            LocalDataStore.setObject(lastTitle, forKey: lastTitleKey)
        } else {
            LocalDataStore.setObject(nil, forKey: lastURLKey)
            LocalDataStore.setObject(nil, forKey: lastTitleKey)
        }
        
    }

    func resetState() {

        var configs = [String: AnyObject]()
        if let lastURL = LocalDataStore.objectForKey(lastURLKey) as? String { // the app was closed while showing a url
            configs["url"] = lastURL
            // get title if possible
            if let lastTitle = LocalDataStore.objectForKey(lastTitleKey) {
                configs["title"] = lastTitle
            }
            
            javaScriptBridge.publishEvent("reset-state", parameters: configs)
        } else if let query = LocalDataStore.objectForKey(lastQueryKey) { // the app was closed while searching
            configs["q"] = query
            // get current location if possible
            if let currentLocation = LocationManager.sharedInstance.location {
                configs["lat"] = currentLocation.coordinate.latitude
                configs["long"] = currentLocation.coordinate.longitude
            }
            javaScriptBridge.publishEvent("reset-state", parameters: configs)
        }
        
        // reset local stored values
        LocalDataStore.setObject(nil, forKey: lastQueryKey)
        LocalDataStore.setObject(nil, forKey: lastURLKey)
        LocalDataStore.setObject(nil, forKey: lastTitleKey)
        
    }
    
}

extension CliqzSearchViewController: JavaScriptBridgeDelegate {
    
    func didSelectUrl(url: NSURL) {
        if !inSelectionMode {
            delegate?.didSelectURL(url, searchQuery: self.searchQuery)
        } else {
            inSelectionMode = false
        }
    }
    
    func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        self.webView?.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
    func searchForQuery(query: String) {
        delegate?.searchForQuery(query)
    }
    
    func getSearchHistoryResults(callback: String?) {
		let fullResults = NSDictionary(objects: [getHistory(), self.searchQuery ?? ""], forKeys: ["results", "query"])
        javaScriptBridge.callJSMethod(callback!, parameter: fullResults, completionHandler: nil)
    }
    
    func shareCard(cardURL: String) {

        // start by empty activity items
        var activityItems = [AnyObject]()
        
        // add the url to activity items
        activityItems.append(cardURL)
        
        // add cliqz footer to activity items
        let footer = NSLocalizedString("Shared with CLIQZ for iOS", tableName: "Cliqz", comment: "Share footer")
        activityItems.append(FooterActivityItemProvider(footer: "\n\n\(footer)"))
        
        // creating the ActivityController and presenting it
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            self.presentViewController(activityViewController, animated: true, completion: nil)
        } else {
            let popup: UIPopoverController = UIPopoverController(contentViewController: activityViewController)
            popup.presentPopoverFromRect(CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2, 0, 0), inView: self.view, permittedArrowDirections: UIPopoverArrowDirection(), animated: true)
        }
    }
    
    func autoCompeleteQuery(autoCompleteText: String) {
        delegate?.autoCompeleteQuery(autoCompleteText)
    }
	
	func isReady() {
        stopLoadingAnimation()
		javaScriptBridge.setDefaultSearchEngine()
		self.updateExtensionPreferences()
	}

}
