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
//		controller.addScriptMessageHandler(self, name: "interOp")
//		controller.addScriptMessageHandler(self, name: "linkSelected")
//		controller.addScriptMessageHandler(self, name: "changeUrlVal")
		self.webView = WKWebView(frame: self.view.bounds, configuration: config)
		self.webView?.navigationDelegate = self;
		self.view.addSubview(self.webView!)

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
		self.historyResults.removeAll(keepCapacity: true)
		for site in data {
			var d = Dictionary<String, String>()
			d["url"] = site!.url
			d["title"] = site!.title
			self.historyResults.append(d)
		}
	}

	func loadData(query: String) {
		cliqzSearch.startSearch(query, history: self.historyResults) {
			(q, data) in
			if q == self.searchQuery {
				self.webView!.loadHTMLString(data, baseURL: nil)
			}
		}
	}

	func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
		if navigationAction.request.URL!.absoluteString.hasPrefix("http") {
			delegate?.searchView(self, didSelectUrl: navigationAction.request.URL!)
			decisionHandler(.Cancel)
		}
		decisionHandler(.Allow)
	}

	func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
	}

	func userContentController(userContentController:  WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
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
