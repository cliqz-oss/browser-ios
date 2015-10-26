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
	
	func searchView(SearchViewController: CliqzSearchViewController, didSelectUrl url: NSURL)
	
}

class CliqzSearchViewController : UIViewController, LoaderListener, WKNavigationDelegate, WKScriptMessageHandler, KeyboardHelperDelegate  {
	
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
		let config = WKWebViewConfiguration()
		let controller = WKUserContentController()
		config.userContentController = controller
		controller.addScriptMessageHandler(self, name: "interOp")
		controller.addScriptMessageHandler(self, name: "linkSelected")
		controller.addScriptMessageHandler(self, name: "changeUrlVal")
        self.webView = WKWebView(frame: self.view.bounds, configuration: config)
		self.webView?.navigationDelegate = self;
        self.view.addSubview(self.webView!)
		let url = NSURL(string: "http://localhost:3005/extension/index.html")
		self.webView!.loadRequest(NSURLRequest(URL: url!))

		KeyboardHelper.defaultHelper.addDelegate(self)
		layoutSearchEngineScrollView()
	}

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
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
		var JSString: String!
		let q = query.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
		if q == "" {
			JSString = "_cliqzNoResults()"
		} else {
			JSString = "search_mobile('\(q)')"
		}
		self.webView!.evaluateJavaScript(JSString, completionHandler: nil)
	}

	func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
		if !navigationAction.request.URL!.absoluteString.hasPrefix("http://localhost:3005/") {
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
		} else if message.name == "linkSelected" {
			let url = message.body as! String
			print("LINK SEL: ---- \(url)")
			delegate?.searchView(self, didSelectUrl: NSURL(string: url)!)
		} else if message.name == "changeUrlVal" {
			let url = message.body as! String
				// TODO: Naira
		}
	}

	private func layoutSearchEngineScrollView() {
		let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(self.view) ?? 0
		self.webView!.snp_remakeConstraints { make in
			make.top.equalTo(0)
			make.left.right.equalTo(self.view)
			make.bottom.equalTo(self.view).offset(-keyboardHeight)
		}
	}

	private func animateSearchEnginesWithKeyboard(keyboardState: KeyboardState) {
		layoutSearchEngineScrollView()
		
		UIView.animateWithDuration(keyboardState.animationDuration, animations: {
			UIView.setAnimationCurve(keyboardState.animationCurve)
			self.view.layoutIfNeeded()
		})
	}

	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
		animateSearchEnginesWithKeyboard(state)
	}
	
	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
	}
	
	func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
		animateSearchEnginesWithKeyboard(state)
	}

}
