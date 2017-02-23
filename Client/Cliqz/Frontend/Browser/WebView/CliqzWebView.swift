//
//  CliqzWebView.swift
//  Client
//
//  Created by Sahakyan on 8/3/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import WebKit
import Shared


class ContainerWebView : WKWebView {
	weak var legacyWebView: CliqzWebView?
}

var globalContainerWebView = ContainerWebView()
var nullWKNavigation: WKNavigation = WKNavigation()
@objc class HandleJsWindowOpen : NSObject {
    static func open(url: String) {
        postAsyncToMain(0) { // we now know JS callbacks can be off main
            guard let wv = getCurrentWebView() else { return }
            let current = wv.URL
            if SettingsPrefs.getBlockPopupsPref() {
                guard let lastTappedTime = wv.lastTappedTime else { return }
                if fabs(lastTappedTime.timeIntervalSinceNow) > 0.75 { // outside of the 3/4 sec time window and we ignore it
                    return
                }
            }
            wv.lastTappedTime = nil
            if let _url = NSURL(string: url, relativeToURL: current) {
                getApp().browserViewController.openURLInNewTab(_url)
            }
        }
    }
}


class WebViewToUAMapper {
    static private let idToWebview = NSMapTable(keyOptions: .StrongMemory, valueOptions: .WeakMemory)
    
    static func setId(uniqueId: Int, webView: CliqzWebView) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        idToWebview.setObject(webView, forKey: uniqueId)
    }
    
    static func removeWebViewWithId(uniqueId: Int) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        idToWebview.removeObjectForKey(uniqueId)
    }
    
    static func idToWebView(uniqueId: Int?) -> CliqzWebView? {
        return idToWebview.objectForKey(uniqueId) as? CliqzWebView
    }
    
    static func userAgentToWebview(userAgent: String?) -> CliqzWebView? {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard let userAgent = userAgent else { return nil }
        guard let loc = userAgent.rangeOfString("_id/") else {
            // the first created webview doesn't have this id set (see webviewBuiltinUserAgent to explain)
            return idToWebview.objectForKey(1) as? CliqzWebView
        }
        let keyString = userAgent.substringWithRange(loc.endIndex..<loc.endIndex.advancedBy(6))
        guard let key = Int(keyString) else { return nil }
        return idToWebview.objectForKey(key) as? CliqzWebView
    }
}

struct CliqzWebViewConstants {
    static let kNotificationWebViewLoadCompleteOrFailed = "kNotificationWebViewLoadCompleteOrFailed"
    static let kNotificationPageInteractive = "kNotificationPageInteractive"
}

class CliqzWebView: UIWebView {
	
	weak var navigationDelegate: WKNavigationDelegate?
	weak var UIDelegate: WKUIDelegate?

	lazy var configuration: CliqzWebViewConfiguration = { return CliqzWebViewConfiguration(webView: self) }()
	lazy var backForwardList: WKBackForwardList = { return globalContainerWebView.backForwardList } ()
	
	var progress: WebViewProgress?
	
	var allowsBackForwardNavigationGestures: Bool = false

    private let lockQueue = dispatch_queue_create("com.cliqz.webView.lockQueue", nil)
    
	private static var containerWebViewForCallbacks = { return ContainerWebView() }()
    
    // This gets set as soon as it is available from the first UIWebVew created
    private static var webviewBuiltinUserAgent: String?

	private var _url: (url: NSURL?, isReliableSource: Bool, prevUrl: NSURL?) = (nil, false, nil)
	func setUrl(url: NSURL?, reliableSource: Bool) {
		_url.prevUrl = _url.url
		_url.isReliableSource = reliableSource
		if URL?.absoluteString!.endsWith("?") ?? false {
			if let noQuery = URL?.absoluteString!.componentsSeparatedByString("?")[0] {
				_url.url = NSURL(string: noQuery)
			}
		} else {
			_url.url = url
		}
		self.URL = _url.url
	}

	dynamic var URL: NSURL? /*{
		get {
			return _url.url
		}
	}*/
    
    var _loading: Bool = false
    override internal dynamic var loading: Bool {
        get {
            if internalLoadingEndedFlag {
                // we detected load complete internally –UIWebView sometimes stays in a loading state (i.e. bbc.com)
                return false
            }
            return _loading
        }
        set {
            _loading = newValue
        }
    }
    
    var _canGoBack: Bool = false
    override internal dynamic var canGoBack: Bool {
        get {
            return _canGoBack
        }
        set {
            _canGoBack = newValue
        }
    }
    
    var _canGoForward: Bool = false
    override internal dynamic var canGoForward: Bool {
        get {
            return _canGoForward
        }
        set {
            _canGoForward = newValue
        }
    }
    
	dynamic var estimatedProgress: Double = 0
	var title: String = "" /* {
		didSet {
			if let item = backForwardList.currentItem {
				item.title = title
			}
		}
	}*/
    
    var knownFrameContexts = Set<NSObject>()

	var prevDocumentLocation = ""
	var internalLoadingEndedFlag: Bool = false;

    var removeProgressObserversOnDeinit: ((UIWebView) -> Void)?

    var triggeredLocationCheckTimer = NSTimer()
    
    var lastTappedTime: NSDate?
    
    static var modifyLinksScript: WKUserScript?
    
    override class func initialize() {
        // Added for modifying page links with target blank to open in new tabs
        let path = NSBundle.mainBundle().pathForResource("ModifyLinksForNewTab", ofType: "js")!
        let source = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
        modifyLinksScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)

    }
    
	init(frame: CGRect, configuration: WKWebViewConfiguration) {
		super.init(frame: frame)
		commonInit()
	}

    // Anti-Tracking
    var uniqueId = -1
	var unsafeRequests = 0 {
		didSet {
			NSNotificationCenter.defaultCenter().postNotificationName(NotificationBadRequestDetected, object: self.uniqueId)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
    deinit {
        
        WebViewToUAMapper.removeWebViewWithId(self.uniqueId)
        
        _ = Try(withTry: {
            self.removeProgressObserversOnDeinit?(self)
        }) { (exception) -> Void in
            print("Failed remove: \(exception)")
        }
    }
	
	func goToBackForwardListItem(item: WKBackForwardListItem) {
		if let index = backForwardList.backList.indexOf(item) {
			let backCount = backForwardList.backList.count - index
			for _ in 0..<backCount {
				goBack()
			}
		} else if let index = backForwardList.forwardList.indexOf(item) {
			for _ in 0..<(index + 1) {
				goForward()
			}
		}
	}

	func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
		ensureMainThread() {
			let wrapped = "var result = \(javaScriptString); JSON.stringify(result)"
			let evaluatedstring = self.stringByEvaluatingJavaScriptFromString(wrapped)
            
            var result: AnyObject?
            if let dict = self.convertStringToDictionary(evaluatedstring) {
                result = dict
            } else {
                // in case the result was not dictionary, return the original response (reverse JSON stringify)
                result = self.reverseStringify(evaluatedstring)
            }
			completionHandler?(result, NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil))
		}
	}
	
	override func loadRequest(request: NSURLRequest) {
		if let url = request.URL where
			!ReaderModeUtils.isReaderModeURL(url) {
			unsafeRequests = 0
		}
		super.loadRequest(request)
	}

	func loadingCompleted() {
		if internalLoadingEndedFlag {
			return
		}
		internalLoadingEndedFlag = true
        
        self.configuration.userContentController.injectJsIntoPage()
		
		guard let docLoc = self.stringByEvaluatingJavaScriptFromString("document.location.href") else { return }

		if docLoc != self.prevDocumentLocation {
			if !(self.URL?.absoluteString!.startsWith(WebServer.sharedInstance.base) ?? false) && !docLoc.startsWith(WebServer.sharedInstance.base) {
				self.title = self.stringByEvaluatingJavaScriptFromString("document.title") ?? NSURL(string: docLoc)?.baseDomain() ?? ""
			}

			if let nd = self.navigationDelegate {
				globalContainerWebView.legacyWebView = self
				nd.webView?(globalContainerWebView, didFinishNavigation: nullWKNavigation)
			}
		}
		self.prevDocumentLocation = docLoc
        
        NSNotificationCenter.defaultCenter().postNotificationName(CliqzWebViewConstants.kNotificationWebViewLoadCompleteOrFailed, object: self)
	}
	
	var customUserAgent:String? /*{
		willSet {
			if self.customUserAgent == newValue || newValue == nil {
				return
			}
			self.customUserAgent = newValue == nil ? nil : kDesktopUserAgent
			// The following doesn't work, we need to kill and restart the webview, and restore its history state
			// for this setting to take effect
			//      let defaults = NSUserDefaults(suiteName: AppInfo.sharedContainerIdentifier())!
			//      defaults.registerDefaults(["UserAgent": (self.customUserAgent ?? "")])
		}
	}*/
	
	func reloadFromOrigin() {
		self.reload()
	}
    
    func updateUnsafeRequestsCount(newCount: Int) {
        dispatch_sync(lockQueue) {
            self.unsafeRequests = newCount
        }
    }
    
    
    // On page load, the contentSize of the webview is updated (**). If the webview has not been notified of a page change (i.e. shouldStartLoadWithRequest was never called) then 'loading' will be false, and we should check the page location using JS.
    // (** Not always updated, particularly on back/forward. For instance load duckduckgo.com, then google.com, and go back. No content size change detected.)
    func contentSizeChangeDetected() {
        if triggeredLocationCheckTimer.valid {
            return
        }
        
        // Add a time delay so that multiple calls are aggregated
        triggeredLocationCheckTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(timeoutCheckLocation), userInfo: nil, repeats: false)
    }
    
    // Pushstate navigation may require this case (see brianbondy.com), as well as sites for which simple pushstate detection doesn't work:
    // youtube and yahoo news are examples of this (http://stackoverflow.com/questions/24297929/javascript-to-listen-for-url-changes-in-youtube-html5-player)
    @objc func timeoutCheckLocation() {
        func shouldUpdateUrl(currentUrl: String, newLocation: String) -> Bool {
            if newLocation == currentUrl || newLocation.contains("about:") || newLocation.contains("//localhost") || URL?.host != NSURL(string: newLocation)?.host {
                return false
            }
            return true
        }
        
        func tryUpdateUrl() {
            guard let location = self.stringByEvaluatingJavaScriptFromString("window.location.href"), currentUrl = URL?.absoluteString where shouldUpdateUrl(currentUrl, newLocation: location) else {
                return
            }
            
            setUrl(NSURL(string: location), reliableSource: false)

            progress?.reset()
        }
        
        dispatch_async(dispatch_get_main_queue()) { 
            tryUpdateUrl()
        }
        
    }


	// MARK:- Private methods

	private class func isTopFrameRequest(request:NSURLRequest) -> Bool {
		return request.URL == request.mainDocumentURL
	}
	
	private func commonInit() {
		delegate = self
        scalesPageToFit = true
        generateUniqueUserAgent()
        Engine.sharedInstance.webRequest?.newTabCreated(self.uniqueId, webView: self)
		progress = WebViewProgress(parent: self)
		let refresh = UIRefreshControl()
		refresh.bounds = CGRectMake(0, -10, refresh.bounds.size.width, refresh.bounds.size.height)
		refresh.tintColor = UIColor.blackColor()
		refresh.addTarget(self, action: #selector(refreshWebView), forControlEvents: UIControlEvents.ValueChanged)
		self.scrollView.addSubview(refresh)
		
        // built-in userScripts
		self.configuration.userContentController.addUserScript(CliqzWebView.modifyLinksScript!)
	}

    // Needed to identify webview in url protocol
    func generateUniqueUserAgent() {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        struct StaticCounter {
            static var counter = 0
        }
        
        StaticCounter.counter += 1
        if let webviewBuiltinUserAgent = CliqzWebView.webviewBuiltinUserAgent {
            let userAgent = webviewBuiltinUserAgent + String(format:" _id/%06d", StaticCounter.counter)
            let defaults = NSUserDefaults(suiteName: AppInfo.sharedContainerIdentifier())!
            defaults.registerDefaults(["UserAgent": userAgent ])
            self.uniqueId = StaticCounter.counter
            WebViewToUAMapper.setId(uniqueId, webView:self)
        } else {
            if StaticCounter.counter > 1 {
                // We shouldn't get here, we allow the first webview to have no user agent, and we special-case the look up. The first webview inits the UA from its built in defaults
                // If we get to more than one, just use a hard coded user agent, to avoid major bugs
                let device = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? "iPhone" : "iPad"
                CliqzWebView.webviewBuiltinUserAgent = "Mozilla/5.0 (\(device)) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13C75"
            }
            self.uniqueId = 1
            WebViewToUAMapper.idToWebview.setObject(self, forKey: 1) // the first webview, we don't have the user agent just yet
        }
    }
    
	private func convertStringToDictionary(text: String?) -> [String:AnyObject]? {
		if let data = text?.dataUsingEncoding(NSUTF8StringEncoding) where text?.characters.count > 0 {
			do {
				let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
				return json
			} catch {
				print("Something went wrong")
			}
		}
		return nil
	}

    private func reverseStringify(text: String?) -> String? {
        guard text != nil else {
            return nil
        }
        let length = text!.characters.count
        if  length > 2 {
            let startIndex = text?.startIndex.successor()
            let endIndex = text?.endIndex.predecessor()
            
            return text!.substringWithRange(Range(startIndex! ..< endIndex!))
        } else {
            return text
        }
    }
    private func updateObservableAttributes() {
        
        self.loading = super.loading
        self.canGoBack = super.canGoBack
        self.canGoForward = super.canGoForward
    }
    
	@objc private func refreshWebView(refresh: UIRefreshControl) {
		refresh.endRefreshing()
		self.reload()
	}
}

extension CliqzWebView: UIWebViewDelegate {
	class LegacyNavigationAction : WKNavigationAction {
		var writableRequest: NSURLRequest
		var writableType: WKNavigationType
		
		init(type: WKNavigationType, request: NSURLRequest) {
			writableType = type
			writableRequest = request
			super.init()
		}
		
		override var request: NSURLRequest { get { return writableRequest} }
		override var navigationType: WKNavigationType { get { return writableType } }
		override var sourceFrame: WKFrameInfo {
			get { return WKFrameInfo() }
		}
	}

	func webView(webView: UIWebView,shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType ) -> Bool {
		guard let url = request.URL else { return false }
		internalLoadingEndedFlag = false

        
        if CliqzWebView.webviewBuiltinUserAgent == nil {
            CliqzWebView.webviewBuiltinUserAgent = request.valueForHTTPHeaderField("User-Agent")
            assert(CliqzWebView.webviewBuiltinUserAgent != nil)
        }

		if url.scheme == "newtab" {
			if let delegate = self.UIDelegate,
				let absoluteStr = url.absoluteString?.stringByRemovingPercentEncoding {
				let startIndex = absoluteStr.startIndex.advancedBy((url.scheme?.characters.count)! + 1)
				let newURL = NSURL(string: absoluteStr.substringFromIndex(startIndex))!
				let newRequest = NSURLRequest(URL: newURL)
				delegate.webView!(globalContainerWebView, createWebViewWithConfiguration: WKWebViewConfiguration(), forNavigationAction: LegacyNavigationAction(type: WKNavigationType(rawValue: navigationType.rawValue)!, request: newRequest), windowFeatures: WKWindowFeatures())
			}
			return false
		}

		if let progressCheck = progress?.shouldStartLoadWithRequest(request, navigationType: navigationType) where !progressCheck {
			return false
		}

		var result = true
		if let nd = navigationDelegate {
			let action = LegacyNavigationAction(type: WKNavigationType(rawValue: navigationType.rawValue)!, request: request)
			globalContainerWebView.legacyWebView = self
			nd.webView?(globalContainerWebView, decidePolicyForNavigationAction: action, decisionHandler: { (policy:WKNavigationActionPolicy) -> Void in
						result = policy == .Allow
			})
		}

		let locationChanged = CliqzWebView.isTopFrameRequest(request) && url.absoluteString != URL?.absoluteString
		if locationChanged {
			setUrl(url, reliableSource: true)
		}
        
        updateObservableAttributes()
		return result
	}

	func webViewDidStartLoad(webView: UIWebView) {
		progress?.webViewDidStartLoad()
		if let nd = self.navigationDelegate {
			globalContainerWebView.legacyWebView = self
			nd.webView?(globalContainerWebView, didCommitNavigation: nullWKNavigation)
		}
        updateObservableAttributes()
	}

	func webViewDidFinishLoad(webView: UIWebView) {
		guard let pageInfo = stringByEvaluatingJavaScriptFromString("document.readyState.toLowerCase() + '|' + document.title") else {
			return
		}
        
        // prevent the default context menu on UIWebView
        stringByEvaluatingJavaScriptFromString("document.body.style.webkitTouchCallout='none';")
        
		let pageInfoArray = pageInfo.componentsSeparatedByString("|")
		
		let readyState = pageInfoArray.first // ;print("readyState:\(readyState)")
		if let t = pageInfoArray.last where !t.isEmpty {
			title = t
		}
		progress?.webViewDidFinishLoad(documentReadyState: readyState)
        updateObservableAttributes()
	}
	
	func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
		// The error may not be the main document that failed to load. Check if the failing URL matches the URL being loaded
		
		if let errorUrl = error.userInfo[NSURLErrorFailingURLErrorKey] as? NSURL {
			var handled = false
			if error.code == -1009 /*kCFURLErrorNotConnectedToInternet*/ {
				let cache = NSURLCache.sharedURLCache().cachedResponseForRequest(NSURLRequest(URL: errorUrl))
				if let html = cache?.data.utf8EncodedString where html.characters.count > 100 {
					loadHTMLString(html, baseURL: errorUrl)
					handled = true
				}
			}
			
			if !handled && URL?.absoluteString == errorUrl.absoluteString {
				if let nd = navigationDelegate {
					globalContainerWebView.legacyWebView = self
					nd.webView?(globalContainerWebView, didFailNavigation: nullWKNavigation, withError: error ?? NSError.init(domain: "", code: 0, userInfo: nil))
				}
			}
		}
        
        NSNotificationCenter.defaultCenter()
            .postNotificationName(CliqzWebViewConstants.kNotificationWebViewLoadCompleteOrFailed, object: self)
        
		progress?.didFailLoadWithError()
        updateObservableAttributes()
	}

}
