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
    private let cliqzSearch = CliqzSearch()

	var webView: WKWebView?
	weak var delegate: SearchViewDelegate?

	private var spinnerView: UIActivityIndicatorView!

	private var historyResults: Cursor<Site>?
	
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
		controller.addScriptMessageHandler(self, name: "jsBridge")

        self.webView = WKWebView(frame: self.view.bounds, configuration: config)
		self.webView?.navigationDelegate = self;
        self.view.addSubview(self.webView!)

		self.spinnerView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
		self.view.addSubview(spinnerView)
		spinnerView.startAnimating()

//		let url = NSURL(string: "http://localhost:3005/extension/index.html")
		let url = NSURL(string: "http://cdn.cliqz.com/mobile/beta/index.html")
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

	override func didReceiveMemoryWarning() {
		self.cliqzSearch.clearCache()
	}

	func loader(dataLoaded data: Cursor<Site>) {
		self.historyResults = data
	}

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
	
	func isHistoryUptodate() -> Bool {
		return true
	}
	
	func loadData(query: String) {
		var JSString: String!
		let q = query.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
		var coordinates = ""
		if let l = LocationManager.sharedInstance.location {
			coordinates += ", true, \(l.coordinate.latitude), \(l.coordinate.longitude)"
		}
		JSString = "search_mobile('\(q)'\(coordinates))"
		self.webView!.evaluateJavaScript(JSString, completionHandler: nil)
	}

	func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
//		if !navigationAction.request.URL!.absoluteString.hasPrefix("http://localhost:3005/") {
		if !navigationAction.request.URL!.absoluteString.hasPrefix("http://cdn.cliqz.com") {
			delegate?.searchView(self, didSelectUrl: navigationAction.request.URL!)
			decisionHandler(.Cancel)
		}
		decisionHandler(.Allow)
	}

	func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
	}

	func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
		self.spinnerView.removeFromSuperview()
		self.spinnerView.stopAnimating()
	}

	func userContentController(userContentController:  WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		switch message.name {
			case "jsBridge":
				if let input = message.body as? NSDictionary {
					if let action = input["action"] as? String {
						handleJSMessage(action, data: input["data"], callback: input["callback"] as? String)
					}
				}
		default:
			print("Unhandled JS message: \(message.name)!!!")
			
		}
		/*
		== "interOp" {
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
*/
	}

	private func layoutSearchEngineScrollView() {
		let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(self.view) ?? 0
		self.webView!.snp_remakeConstraints { make in
			make.top.equalTo(0)
			make.left.right.equalTo(self.view)
			make.bottom.equalTo(self.view).offset(-keyboardHeight)
		}
		if let _ = self.spinnerView.superview {
			self.spinnerView.snp_makeConstraints { make in
				make.centerX.equalTo(self.view)
				make.top.equalTo((self.view.frame.size.height - keyboardHeight) / 2)
				return
			}
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

	private func handleJSMessage(action: String, data: AnyObject?, callback: String?) {
		switch action {
			case "searchHistory":
				var jsonStr: NSString = ""
				do {
					let fullResults = NSDictionary(objects: [getHistory(), self.searchQuery!], forKeys: ["results", "query"])
					let json = try NSJSONSerialization.dataWithJSONObject(fullResults, options: NSJSONWritingOptions(rawValue: 0))
					jsonStr = NSString(data:json, encoding: NSUTF8StringEncoding)!
				} catch let error as NSError {
					print("Json conversion is failed with error: \(error)")
				}
				if let c = callback {
					let exec = "\(c)(\(jsonStr))"
					self.webView!.evaluateJavaScript(exec, completionHandler: nil)
				}
			case "openLink":
				if let url = data as? String {
					delegate?.searchView(self, didSelectUrl: NSURL(string: url)!)
				}
//			case "":
		default:
				print("Unhandles JS action: \(action)")
		}
	}
}
