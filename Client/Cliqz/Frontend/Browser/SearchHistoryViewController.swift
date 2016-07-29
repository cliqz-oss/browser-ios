//
//  SearchHistoryViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 11/25/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import UIKit
import Shared
import Storage
import WebKit

protocol SearchHistoryViewControllerDelegate: class {
    
    func didSelectURL(url: NSURL)
    func searchForQuery(query: String)
}

class SearchHistoryViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, UIAlertViewDelegate {
    
    lazy var historyWebView: WKWebView = {
        let config = ConfigurationManager.sharedInstance.getSharedConfiguration(self)
        
        let webView = WKWebView(frame: self.view.bounds, configuration: config)
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        return webView
        }()
    
    lazy var javaScriptBridge: JavaScriptBridge = {
        let javaScriptBridge = JavaScriptBridge(profile: self.profile)
        javaScriptBridge.delegate = self
        return javaScriptBridge
        }()
    
    var profile: Profile!
	var bookmarkSource: BookmarksModel?

    var tabManager: TabManager!
    weak var delegate: SearchHistoryViewControllerDelegate?
    let QueryLimit = 100
    
    var queuedScripts = [String]()
    
	init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
		self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearQueries:", name: NotificationPrivateDataClearQueries, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationPrivateDataClearQueries, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadHistory()
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.barTintColor = UIConstants.OrangeColor
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.whiteColor()]
        self.title = NSLocalizedString("Search history", tableName: "Cliqz", comment: "Search history title")
        self.navigationItem.leftBarButtonItems = createBarButtonItems("present", action: Selector("dismiss"), accessibilityLabel: "CloseHistoryButton")

		
        self.setupConstraints()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
		self.javaScriptBridge.callJSMethod("jsAPI.onShow", parameter: nil, completionHandler: nil)
        self.historyWebView.scrollView.contentInset = UIEdgeInsetsMake(0,0,0,0)
    }
    
    private func evaluateQueuedScripts() {
        for script in queuedScripts {
            self.evaluateJavaScript(script, completionHandler: nil)
        }
        queuedScripts.removeAll()
    }
    
    // Mark: WKScriptMessageHandler
    func userContentController(userContentController:  WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        javaScriptBridge.handleJSMessage(message)
    }
    
    // Mark: Navigation delegate
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
		
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
    }
    
    // Mark: Action handlers
    func dismiss() {
        logLayerChangeTelemetrySignal()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func logLayerChangeTelemetrySignal() {
        TelemetryLogger.sharedInstance.logEvent(.LayerChange("past", "present"))
    }
    
    // Mark: Configure Layout
    private func setupConstraints() {
        self.historyWebView.snp_remakeConstraints { make in
            make.top.equalTo(snp_topLayoutGuideBottom)
            make.left.right.bottom.equalTo(self.view)
        }
    }
    
	private func createBarButtonItems(imageName: String, action: Selector, accessibilityLabel: String) -> [UIBarButtonItem] {
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: imageName), forState: UIControlState.Normal)
        button.addTarget(self, action: action, forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 36, 36)
        button.accessibilityLabel = accessibilityLabel

        let barButton = UIBarButtonItem(customView: button)
        
        let spacerBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target:nil, action: nil)
        spacerBarButtonItem.width = -5
        
        return [spacerBarButtonItem, barButton]
    }
    
    private func loadHistory() {
        let url = NSURL(string: NavigationExtension.historyURL)
        self.historyWebView.loadRequest(NSURLRequest(URL: url!))
    }
    
}


extension SearchHistoryViewController: JavaScriptBridgeDelegate {
    
    func didSelectUrl(url: NSURL) {
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.delegate?.didSelectURL(url)
        }
        logLayerChangeTelemetrySignal()
    }
    
    func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        guard self.isViewLoaded() == true else {
            queuedScripts.append(javaScriptString)
            return
        }
        self.historyWebView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
    func searchForQuery(query: String) {
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.delegate?.searchForQuery(query)
        }
        logLayerChangeTelemetrySignal()

    }
	
	func getFavorites(callback: String?) {
		self.profile.bookmarks.getBookmarks().uponQueue(dispatch_get_main_queue()) { result in
			if let bookmarks = result.successValue {
				var favorites = [[String: AnyObject]]()
				for i in bookmarks {
					switch (i) {
					case let item as CliqzBookmarkItem:
						var bm = [String: AnyObject]()
						bm["title"] = item.title
						bm["url"] = item.url
						bm["timestamp"] = Double(item.bookmarkedDate)
						favorites.append(bm)
					default:
						print("Not a bookmark item")
					}
				}
				self.javaScriptBridge.callJSMethod(callback!, parameter: favorites, completionHandler: nil)
			}
		}
	}

	private func onModelFetched(result: Maybe<BookmarksModel>) {
		guard let model = result.successValue else {
			print("Error: failed to get data: \(result.failureValue)")
			return
		}

		if NSThread.currentThread().isMainThread {
			self.bookmarkSource = model
			return
		}

		dispatch_async(dispatch_get_main_queue()) {
			self.bookmarkSource = model
		}
	}

	func getSearchHistory(callback: String?) {
		if let c = callback {
			self.profile.history.getHistoryVisits(QueryLimit).uponQueue(dispatch_get_main_queue()) { result in
				if let sites = result.successValue {
					var historyResults = [[String: AnyObject]]()
					for site in sites {
						var d = [String: AnyObject]()
						d["id"] = site!.id
						d["url"] = site!.url
						d["title"] = site!.title
						d["timestamp"] = Double(site!.latestVisit!.date) / 1000.0
						historyResults.append(d)
					}
					self.javaScriptBridge.callJSMethod(c, parameter: historyResults.reverse(), completionHandler: nil)
				}
			}
		}
	}

    func isReady() {
        evaluateQueuedScripts()
        
        guard NSUserDefaults.standardUserDefaults().boolForKey(IsAppTerminated) ?? false else {
            return
        }
        guard let profile = self.profile where (profile.prefs.boolForKey(ClearDataOnTerminatingPrefKey) ?? false) == true && profile.historyTypeShouldBeCleared() != .None else {
            return
        }
        clearQueries(includeFavorites: profile.historyTypeShouldBeCleared() == .All)
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: IsAppTerminated)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    // MARK: - Clear History
	func clearQueries(notification: NSNotification) {
        let includeFavorites: Bool = (notification.object as? Bool) ?? false
		self.clearQueries(includeFavorites: includeFavorites)
	}

	func clearQueries(includeFavorites includeFavorites: Bool) {
        if includeFavorites == true {
            self.evaluateJavaScript("jsAPI.clearFavorites()", completionHandler: nil)
        } else {
            self.evaluateJavaScript("jsAPI.clearHistory()", completionHandler: nil)
        }
    }

}

