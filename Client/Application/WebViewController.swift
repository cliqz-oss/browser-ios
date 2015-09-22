//
//  WebViewController.swift
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
	
	func searchView(SearchViewController: BrowserViewController2, didSelectUrl url: NSURL)
	
}

class BrowserViewController2 : UIViewController, LoaderListener, WKNavigationDelegate, WKScriptMessageHandler  {
	
	private var searchLoader: SearchLoader!
    var webView: WKWebView?
	weak var delegate: SearchViewDelegate?

	private var historyResults: Array<Dictionary<String, String>> = Array<Dictionary<String, String>>()
	
	var searchQuery: String? {
		didSet {
			self.loadData(searchQuery!)
		}
	}

	override func viewDidLoad() {
        super.viewDidLoad()
//		let v = PagingScrollView(frame: CGRectMake(0, 0, 320, self.webViewContainer.frame.size.height))
//		v.delegate = self
//		v.setTranslatesAutoresizingMaskIntoConstraints(false)
//		self.webViewContainer.addSubview(v)
//		webViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
//			"H:|[pagingScrollView]|",
//			options: NSLayoutFormatOptions(0),
//			metrics: nil,
//			views: ["pagingScrollView": v]))
//		
//		webViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
//			"V:|[pagingScrollView]|",
//			options: NSLayoutFormatOptions(0),
//			metrics: nil,
//			views: ["pagingScrollView": v]))
//
//		self.pagingScrollView = v
		let config = WKWebViewConfiguration()
		let controller = WKUserContentController()
		config.userContentController = controller
		controller.addScriptMessageHandler(self, name: "interOp")
        self.webView = WKWebView(frame: self.view.bounds, configuration: config)
        self.webView?.translatesAutoresizingMaskIntoConstraints = false
		self.webView?.navigationDelegate = self;
        self.view.addSubview(self.webView!)
		self.view.backgroundColor = UIColor.redColor()
//		var theWebView = WKWebView(frame:self.view.frame,
//			configuration: theConfiguration)
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|[webView]|",
			options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: ["webView": self.webView!]))
        
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            "V:|[webView]|",
			options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: ["webView": self.webView!]))
		let u = NSURL(string: "http://localhost:3001/extension/index.html")
		self.webView!.loadRequest(NSURLRequest(URL:u!))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//		if let u = self.urls.last {
//			self.pagingScrollView.loadUrl(u)
//		}
//		self.pagingScrollView.loadURLs(self.urls)
//		for s in self.urls {
//			self.pagingScrollView.loadUrl(s)
//		}

//		if let l = self.url {
//			self.pagingScrollView.loadUrl(l)
//		}
/*		if let u = self.url {
			let requestUrl = NSURL(string: u)
			urlLabel.setTitle(requestUrl!.host, forState: .Normal)
			
			webView!.loadRequest(NSURLRequest(URL: requestUrl!))
			webView!.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
		}
*/
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
//        webView!.removeObserver(self, forKeyPath: "estimatedProgress")
    }

	func loader(dataLoaded data: Cursor<Site>) {
		self.historyResults.removeAll(keepCapacity: true)
		for site in data {
			var d = Dictionary<String, String>()
			d["url"] = site!.url
			d["title"] = site!.title
			self.historyResults.append(d)
		}
	}

	func loadData(query: String) {
		if let l = LocationManager.sharedLocationManager.location {
			self.webView!.evaluateJavaScript("setLocation(\(l.coordinate.latitude), \(l.coordinate.longitude))", completionHandler: nil)
		}
		var JSString: String!
		let q = query.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
		if q == "" {
			JSString = "_cliqzNoResults()"
		} else {
			JSString = "search_mobile('\(q)')"
		}
		self.webView!.evaluateJavaScript(JSString, completionHandler: nil)
	}
	
	func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		if request.URL!.absoluteString.hasPrefix("http") {
			delegate?.searchView(self, didSelectUrl: request.URL!)
			return false
		} else {
		}
		return true
	}

	func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
		if !navigationAction.request.URL!.absoluteString.hasPrefix("http://localhost:3001/") {
			delegate?.searchView(self, didSelectUrl: navigationAction.request.URL!)
			decisionHandler(.Cancel)
		}
		decisionHandler(.Allow)
	}

	func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
	}

	func userContentController(userContentController:  WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		if message.name == "interOp" {
			print("Received event \(message.body) --- \(message.name)")
			let input = message.body as! NSDictionary
			let callbakcID = input.objectForKey("callbackId")
			let query = input.objectForKey("query") as? String
			var jsonStr: NSString = ""
			do {
				let json = try NSJSONSerialization.dataWithJSONObject(self.historyResults, options: NSJSONWritingOptions(rawValue: 0))
					jsonStr = NSString(data:json, encoding: NSUTF8StringEncoding)!
			} catch let error as NSError {
				print("Json conversion is failed with error: \(error)")
			}
			let exec = "CLIQZEnvironment.historySearchDone(\(callbakcID!), '\(query!)', '\(jsonStr)');"
			self.webView!.evaluateJavaScript(exec, completionHandler: nil)
		}
	}

}
