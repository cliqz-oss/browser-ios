//
//  CliqzWebView.swift
//  Client
//
//  Created by Sahakyan on 8/3/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import WebKit


class ContainerWebView : WKWebView {
	weak var legacyWebView: CliqzWebView?
}

var globalContainerWebView = ContainerWebView()
var nullWKNavigation: WKNavigation = WKNavigation()


class CliqzWebView: UIWebView {
	
	weak var navigationDelegate: WKNavigationDelegate?
	weak var UIDelegate: WKUIDelegate?

	lazy var configuration: WKWebViewConfiguration = { return WKWebViewConfiguration() }()
	lazy var backForwardList: WKBackForwardList = { return WKBackForwardList() } ()
	
	var progress: WebViewProgress?
	
	var allowsBackForwardNavigationGestures: Bool = false

	private static var containerWebViewForCallbacks = { return ContainerWebView() }()

	private var _url: (url: NSURL?, isReliableSource: Bool, prevUrl: NSURL?) = (nil, false, nil)
	func setUrl(url: NSURL?, reliableSource: Bool) {
		_url.prevUrl = _url.url
		_url.isReliableSource = reliableSource
		if URL?.absoluteString.endsWith("?") ?? false {
			if let noQuery = URL?.absoluteString.componentsSeparatedByString("?")[0] {
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

	dynamic var estimatedProgress: Double = 0
	var title: String = "" /* {
		didSet {
			if let item = backForwardList.currentItem {
				item.title = title
			}
		}
	}*/

	var prevDocumentLocation = ""
	var internalLoadingEndedFlag: Bool = false;
	
	init(frame: CGRect, configuration: WKWebViewConfiguration) {
		super.init(frame: frame)
		self.configuration = configuration
		commonInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
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
			let string = self.stringByEvaluatingJavaScriptFromString(wrapped)
			let dict = self.convertStringToDictionary(string)
			completionHandler?(dict, NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil))
		}
	}
	
	override func loadRequest(request: NSURLRequest) {
		super.loadRequest(request)
	}
	
	func loadingCompleted() {
		if internalLoadingEndedFlag {
			return
		}
		internalLoadingEndedFlag = true
		
		guard let docLoc = self.stringByEvaluatingJavaScriptFromString("document.location.href") else { return }

		if docLoc != self.prevDocumentLocation {
			if !(self.URL?.absoluteString.startsWith(WebServer.sharedInstance.base) ?? false) && !docLoc.startsWith(WebServer.sharedInstance.base) {
				self.title = self.stringByEvaluatingJavaScriptFromString("document.title") ?? NSURL(string: docLoc)?.baseDomain() ?? ""
			}
			
			if let nd = self.navigationDelegate {
				globalContainerWebView.legacyWebView = self
				nd.webView?(globalContainerWebView, didFinishNavigation: nullWKNavigation)
			}
		}
		self.prevDocumentLocation = docLoc
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

	// MARK:- Private methods

	private class func isTopFrameRequest(request:NSURLRequest) -> Bool {
		return request.URL == request.mainDocumentURL
	}
	
	private func commonInit() {
		delegate = self
		progress = WebViewProgress(parent: self)
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
		return result
	}
	
	func webViewDidStartLoad(webView: UIWebView) {
		progress?.webViewDidStartLoad()
		if let nd = self.navigationDelegate {
			globalContainerWebView.legacyWebView = self
			nd.webView?(globalContainerWebView, didCommitNavigation: nullWKNavigation)
		}
	}
	
	func webViewDidFinishLoad(webView: UIWebView) {
		guard let pageInfo = stringByEvaluatingJavaScriptFromString("document.readyState.toLowerCase() + '|' + document.title") else {
			return
		}
		let pageInfoArray = pageInfo.componentsSeparatedByString("|")
		
		let readyState = pageInfoArray.first // ;print("readyState:\(readyState)")
		if let t = pageInfoArray.last where !t.isEmpty {
			title = t
		}
		progress?.webViewDidFinishLoad(documentReadyState: readyState)
	}
	
	func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
		// The error may not be the main document that failed to load. Check if the failing URL matches the URL being loaded
		
		if let error = error, errorUrl = error.userInfo[NSURLErrorFailingURLErrorKey] as? NSURL {
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
		progress?.didFailLoadWithError()
	}

}