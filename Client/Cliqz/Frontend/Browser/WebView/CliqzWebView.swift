//
//  CliqzWebView.swift
//  Client
//
//  Created by Sahakyan on 8/3/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import WebKit

class CliqzWebView: UIWebView {
	
	weak var navigationDelegate: WKNavigationDelegate?
	weak var UIDelegate: WKUIDelegate?

	lazy var configuration: WKWebViewConfiguration = { return WKWebViewConfiguration() }()
	lazy var backForwardList: WKBackForwardList = { return WKBackForwardList() } ()

	var allowsBackForwardNavigationGestures: Bool = false
	
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
	}

	var URL: NSURL? {
		get {
			return _url.url
		}
	}

	var estimatedProgress: Double = 0
	var title: String = "" /* {
		didSet {
			if let item = backForwardList.currentItem {
				item.title = title
			}
		}
	}*/
	
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
	private func commonInit() {
		delegate = self
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
	
}