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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



class ContainerWebView : WKWebView {
	weak var legacyWebView: CliqzWebView?
}

var globalContainerWebView = ContainerWebView()
var nullWKNavigation: WKNavigation = WKNavigation()
@objc class HandleJsWindowOpen : NSObject {
    static func open(_ url: String) {
        postAsyncToMain(0) { // we now know JS callbacks can be off main
            guard let wv = getCurrentWebView() else { return }
            let current = wv.url
            if SettingsPrefs.getBlockPopupsPref() {
                guard let lastTappedTime = wv.lastTappedTime else { return }
                if fabs(lastTappedTime.timeIntervalSinceNow) > 0.75 { // outside of the 3/4 sec time window and we ignore it
                    return
                }
            }
            wv.lastTappedTime = nil
            if let _url = URL(string: url, relativeTo: current) {
                getApp().browserViewController.openURLInNewTab(_url)
            }
        }
    }
}


class WebViewToUAMapper {
    static fileprivate let idToWebview = NSMapTable<AnyObject, CliqzWebView>(keyOptions: NSPointerFunctions.Options(), valueOptions: [.weakMemory])
    
    static func setId(_ uniqueId: Int, webView: CliqzWebView) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        idToWebview.setObject(webView, forKey: uniqueId as AnyObject)
    }
    
    static func removeWebViewWithId(_ uniqueId: Int) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        idToWebview.removeObject(forKey: uniqueId as AnyObject)
    }
    
    static func idToWebView(_ uniqueId: Int?) -> CliqzWebView? {
        return idToWebview.object(forKey: uniqueId as AnyObject) as? CliqzWebView
    }
    
    static func userAgentToWebview(_ userAgent: String?) -> CliqzWebView? {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard let userAgent = userAgent else { return nil }
        guard let loc = userAgent.range(of: "_id/") else {
            // the first created webview doesn't have this id set (see webviewBuiltinUserAgent to explain)
            return idToWebview.object(forKey: 1 as AnyObject) as? CliqzWebView
        }
		let keyString = userAgent.substring(with: loc.upperBound..<userAgent.index(loc.upperBound, offsetBy: 6)) // .upperBound..<index.index(loc.upperBound, offsetBy: 6))
        guard let key = Int(keyString) else { return nil }
        return idToWebview.object(forKey: key as AnyObject) as? CliqzWebView
    }
}

struct CliqzWebViewConstants {
    static let kNotificationWebViewLoadCompleteOrFailed = "kNotificationWebViewLoadCompleteOrFailed"
    static let kNotificationPageInteractive = "kNotificationPageInteractive"
}

protocol CliqzWebViewDelegate: class {
    func didFinishLoadingRequest(request: NSURLRequest?)
}

class CliqzWebView: UIWebView {
	
	weak var navigationDelegate: WKNavigationDelegate?
	weak var UIDelegate: WKUIDelegate?
    weak var webViewDelegate: CliqzWebViewDelegate?

	lazy var configuration: CliqzWebViewConfiguration = { return CliqzWebViewConfiguration(webView: self) }()
	lazy var backForwardList: WebViewBackForwardList = { return WebViewBackForwardList(webView: self) } ()
	
	var progress: WebViewProgress?
	
	var allowsBackForwardNavigationGestures: Bool = false

    fileprivate let lockQueue = DispatchQueue(label: "com.cliqz.webView.lockQueue", attributes: [])
    
	fileprivate static var containerWebViewForCallbacks = { return ContainerWebView() }()
    
    // This gets set as soon as it is available from the first UIWebVew created
    fileprivate static var webviewBuiltinUserAgent: String?

	fileprivate var _url: (url: Foundation.URL?, isReliableSource: Bool, prevUrl: Foundation.URL?) = (nil, false, nil)
	func setUrl(_ url: Foundation.URL?, reliableSource: Bool) {
		_url.prevUrl = _url.url
		_url.isReliableSource = reliableSource
		if url?.absoluteString.endsWith("?") ?? false {
			if let noQuery = url?.absoluteString.components(separatedBy: "?")[0] {
				_url.url = Foundation.URL(string: noQuery)
			}
		} else {
			_url.url = url
		}
		self.url = _url.url
	}

	dynamic var url: Foundation.URL? /*{
		get {
			return _url.url
		}
	}*/
    
    var _loading: Bool = false
    override internal dynamic var isLoading: Bool {
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
	var title: String = "" {
		didSet {
			if let item = backForwardList.currentItem {
				item.title = title
			}
		}
	}
    
    var knownFrameContexts = Set<NSObject>()

	var prevDocumentLocation = ""
	var internalLoadingEndedFlag: Bool = false;

    var removeProgressObserversOnDeinit: ((UIWebView) -> Void)?

    var triggeredLocationCheckTimer = Timer()
    
    var lastTappedTime: Date?
    
    static var modifyLinksScript: WKUserScript?
    
    override class func initialize() {
        // Added for modifying page links with target blank to open in new tabs
        let path = Bundle.main.path(forResource: "ModifyLinksForNewTab", ofType: "js")!
        let source = try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
        modifyLinksScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)

    }
    
	init(frame: CGRect, configuration: WKWebViewConfiguration) {
		super.init(frame: frame)
		commonInit()
	}

    // Anti-Tracking
    var uniqueId = -1
	var unsafeRequests = 0 {
		didSet {
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationBadRequestDetected), object: self.uniqueId)
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
            debugPrint("Failed remove: \(exception)")
        }
    }
	
	func goToBackForwardListItem(item: LegacyBackForwardListItem) {
		if let index = backForwardList.backList.index(of: item) {
			let backCount = backForwardList.backList.count - index
			for _ in 0..<backCount {
				goBack()
			}
		} else if let index = backForwardList.forwardList.index(of: item) {
			for _ in 0..<(index + 1) {
				goForward()
			}
		}
	}

	func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
		ensureMainThread() {
			let wrapped = "var result = \(javaScriptString); JSON.stringify(result)"
			let evaluatedstring = self.stringByEvaluatingJavaScript(from: wrapped)
            
            var result: AnyObject?
            if let dict = self.convertStringToDictionary(evaluatedstring) {
                result = dict as AnyObject?
            } else {
                // in case the result was not dictionary, return the original response (reverse JSON stringify)
                result = self.reverseStringify(evaluatedstring) as AnyObject?
            }
			completionHandler?(result, NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil))
		}
	}
	
	override func loadRequest(_ request: URLRequest) {
		if let url = request.url,
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
		
		guard let docLoc = self.stringByEvaluatingJavaScript(from: "document.location.href") else { return }

		if docLoc != self.prevDocumentLocation {
			if !(self.url?.absoluteString.startsWith(WebServer.sharedInstance.base) ?? false) && !docLoc.startsWith(WebServer.sharedInstance.base) {
				self.title = self.stringByEvaluatingJavaScript(from: "document.title") ?? Foundation.URL(string: docLoc)?.baseDomain() ?? ""
			}

			if let nd = self.navigationDelegate {
				globalContainerWebView.legacyWebView = self
				nd.webView?(globalContainerWebView, didFinish: nullWKNavigation)
			}
		}
		self.prevDocumentLocation = docLoc
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: CliqzWebViewConstants.kNotificationWebViewLoadCompleteOrFailed), object: self)
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
    
    func updateUnsafeRequestsCount(_ newCount: Int) {
        lockQueue.sync {
            self.unsafeRequests = newCount
        }
    }
    
    
    // On page load, the contentSize of the webview is updated (**). If the webview has not been notified of a page change (i.e. shouldStartLoadWithRequest was never called) then 'loading' will be false, and we should check the page location using JS.
    // (** Not always updated, particularly on back/forward. For instance load duckduckgo.com, then google.com, and go back. No content size change detected.)
    func contentSizeChangeDetected() {
        if triggeredLocationCheckTimer.isValid {
            return
        }
        
        // Add a time delay so that multiple calls are aggregated
        triggeredLocationCheckTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeoutCheckLocation), userInfo: nil, repeats: false)
    }
    
    // Pushstate navigation may require this case (see brianbondy.com), as well as sites for which simple pushstate detection doesn't work:
    // youtube and yahoo news are examples of this (http://stackoverflow.com/questions/24297929/javascript-to-listen-for-url-changes-in-youtube-html5-player)
    @objc func timeoutCheckLocation() {
        func shouldUpdateUrl(_ currentUrl: String, newLocation: String) -> Bool {
            if newLocation == currentUrl || newLocation.contains("about:") || newLocation.contains("//localhost") || url?.host != Foundation.URL(string: newLocation)?.host {
                return false
            }
            return true
        }
        
        func tryUpdateUrl() {
            guard let location = self.stringByEvaluatingJavaScript(from: "window.location.href"), let currentUrl = url?.absoluteString, shouldUpdateUrl(currentUrl, newLocation: location) else {
                return
            }
            
            setUrl(Foundation.URL(string: location), reliableSource: false)

            progress?.reset()
        }
        
        DispatchQueue.main.async { 
            tryUpdateUrl()
        }
        
    }
    
    override func goBack() {
        super.goBack()
        self.canGoForward = true
    }

    
    override func goForward() {
        super.goForward()
        self.canGoBack = true
    }
    
	// MARK:- Private methods

	fileprivate class func isTopFrameRequest(_ request:URLRequest) -> Bool {
		return request.url == request.mainDocumentURL
	}
	
	fileprivate func commonInit() {
		delegate = self
        scalesPageToFit = true
        generateUniqueUserAgent()
        Engine.sharedInstance.getWebRequest().newTabCreated(self.uniqueId, webView: self)
		progress = WebViewProgress(parent: self)
		let refresh = UIRefreshControl()
		refresh.bounds = CGRect(x: 0, y: -10, width: refresh.bounds.size.width, height: refresh.bounds.size.height)
		refresh.tintColor = UIColor.black
		refresh.addTarget(self, action: #selector(refreshWebView), for: UIControlEvents.valueChanged)
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
            let defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier())!
            defaults.register(defaults: ["UserAgent": userAgent ])
            self.uniqueId = StaticCounter.counter
            WebViewToUAMapper.setId(uniqueId, webView:self)
        } else {
            if StaticCounter.counter > 1 {
                // We shouldn't get here, we allow the first webview to have no user agent, and we special-case the look up. The first webview inits the UA from its built in defaults
                // If we get to more than one, just use a hard coded user agent, to avoid major bugs
                let device = UIDevice.current.userInterfaceIdiom == .phone ? "iPhone" : "iPad"
                CliqzWebView.webviewBuiltinUserAgent = "Mozilla/5.0 (\(device)) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13C75"
            }
            self.uniqueId = 1
            WebViewToUAMapper.idToWebview.setObject(self, forKey: 1 as AnyObject) // the first webview, we don't have the user agent just yet
        }
    }
    
	fileprivate func convertStringToDictionary(_ text: String?) -> [String:AnyObject]? {
		if let data = text?.data(using: String.Encoding.utf8), text?.characters.count > 0 {
			do {
				let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
				return json
			} catch {
				debugPrint("Something went wrong")
			}
		}
		return nil
	}

    fileprivate func reverseStringify(_ text: String?) -> String? {
        guard text != nil else {
            return nil
        }
        let length = text!.characters.count
        if  length > 2 {
            let startIndex = text?.characters.index(after: (text?.startIndex)!)
            let endIndex = text?.characters.index(before: (text?.endIndex)!)
            
            return text!.substring(with: Range(startIndex! ..< endIndex!))
        } else {
            return text
        }
    }
    fileprivate func updateObservableAttributes() {
        
        self.isLoading = super.isLoading
        self.canGoBack = super.canGoBack
        self.canGoForward = super.canGoForward
    }
    
	@objc fileprivate func refreshWebView(_ refresh: UIRefreshControl) {
		refresh.endRefreshing()
		self.reload()
	}
}

extension CliqzWebView: UIWebViewDelegate {
	class LegacyNavigationAction : WKNavigationAction {
		var writableRequest: URLRequest
		var writableType: WKNavigationType
		
		init(type: WKNavigationType, request: URLRequest) {
			writableType = type
			writableRequest = request
			super.init()
		}
		
		override var request: URLRequest { get { return writableRequest} }
		override var navigationType: WKNavigationType { get { return writableType } }
		override var sourceFrame: WKFrameInfo {
			get { return WKFrameInfo() }
		}
	}

	func webView(_ webView: UIWebView,shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType ) -> Bool {
		guard let url = request.url else { return false }
		internalLoadingEndedFlag = false

        
        if CliqzWebView.webviewBuiltinUserAgent == nil {
            CliqzWebView.webviewBuiltinUserAgent = request.value(forHTTPHeaderField: "User-Agent")
            assert(CliqzWebView.webviewBuiltinUserAgent != nil)
        }

		if url.scheme == "newtab" {
			if let delegate = self.UIDelegate,
				let absoluteStr = url.absoluteString.removingPercentEncoding {
				let startIndex = absoluteStr.characters.index(absoluteStr.startIndex, offsetBy: (url.scheme?.characters.count)! + 1)
				let newURL = Foundation.URL(string: absoluteStr.substring(from: startIndex))!
				let newRequest = URLRequest(url: newURL)
				_ = delegate.webView!(globalContainerWebView, createWebViewWith: WKWebViewConfiguration(), for: LegacyNavigationAction(type: WKNavigationType(rawValue: navigationType.rawValue)!, request: newRequest), windowFeatures: WKWindowFeatures())
			}
			return false
		}

		if let progressCheck = progress?.shouldStartLoadWithRequest(request, navigationType: navigationType), !progressCheck {
			return false
		}

		var result = true
		if let nd = navigationDelegate {
			let action = LegacyNavigationAction(type: WKNavigationType(rawValue: navigationType.rawValue)!, request: request)
			globalContainerWebView.legacyWebView = self
			nd.webView?(globalContainerWebView, decidePolicyFor: action, decisionHandler: { (policy:WKNavigationActionPolicy) -> Void in
						result = policy == .allow
			})
		}

		let locationChanged = CliqzWebView.isTopFrameRequest(request) && url.absoluteString != self.url?.absoluteString
		if locationChanged {
			setUrl(url, reliableSource: true)
		}
        
        updateObservableAttributes()
		return result
	}

	func webViewDidStartLoad(_ webView: UIWebView) {
        backForwardList.update()
		progress?.webViewDidStartLoad()
		if let nd = self.navigationDelegate {
			globalContainerWebView.legacyWebView = self
			nd.webView?(globalContainerWebView, didCommit: nullWKNavigation)
		}
        updateObservableAttributes()
	}

	func webViewDidFinishLoad(_ webView: UIWebView) {
		guard let pageInfo = stringByEvaluatingJavaScript(from: "document.readyState.toLowerCase() + '|' + document.title") else {
			return
		}
        
        backForwardList.update()
        
        // prevent the default context menu on UIWebView
        stringByEvaluatingJavaScript(from: "document.body.style.webkitTouchCallout='none';")
        
		let pageInfoArray = pageInfo.components(separatedBy: "|")
		
		let readyState = pageInfoArray.first // ;debugPrint("readyState:\(readyState)")
		if let t = pageInfoArray.last, !t.isEmpty {
			title = t
		}
		progress?.webViewDidFinishLoad(readyState)
        updateObservableAttributes()
        
	}
	
	func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
		// The error may not be the main document that failed to load. Check if the failing URL matches the URL being loaded
		
		if let errorUrl = (error as NSError).userInfo[NSURLErrorFailingURLErrorKey] as? Foundation.URL {
			var handled = false
			if (error as NSError).code == -1009 /*kCFURLErrorNotConnectedToInternet*/ {
				let cache = URLCache.shared.cachedResponse(for: URLRequest(url: errorUrl))
				if let html = cache?.data.utf8EncodedString, html.characters.count > 100 {
					loadHTMLString(html, baseURL: errorUrl)
					handled = true
				}
			}
			
			if !handled && url?.absoluteString == errorUrl.absoluteString {
				if let nd = navigationDelegate {
					globalContainerWebView.legacyWebView = self
					nd.webView?(globalContainerWebView, didFail: nullWKNavigation, withError: error)
				}
			}
		}
        
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: CliqzWebViewConstants.kNotificationWebViewLoadCompleteOrFailed), object: self)
        
		progress?.didFailLoadWithError()
        updateObservableAttributes()
	}

}
