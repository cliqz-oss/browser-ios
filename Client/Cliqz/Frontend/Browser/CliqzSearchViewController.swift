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
    func searchView(SearchViewController: CliqzSearchViewController, searchForQuery query: String)
	
}

class CliqzSearchViewController : UIViewController, LoaderListener, WKNavigationDelegate, WKScriptMessageHandler, KeyboardHelperDelegate, UIAlertViewDelegate  {
	
    private var searchLoader: SearchLoader!
    private let cliqzSearch = CliqzSearch()
    
    private let lastQueryKey = "LastQuery"
    private let lastURLKey = "LastURL"
    private let lastTitleKey = "LastTitle"
    
    private var lastQuery: String?

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

		loadExtension()

		KeyboardHelper.defaultHelper.addDelegate(self)
		layoutSearchEngineScrollView()
        lastQuery = LocalDataStore.objectForKey(lastQueryKey) as? String
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

        if query.characters.count > 0 {
            lastQuery = query
        }
	}

	func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
//		if !navigationAction.request.URL!.absoluteString.hasPrefix("http://localhost:3005/") {
		if !navigationAction.request.URL!.absoluteString.hasPrefix("http://cdn.cliqz.com") {
//			delegate?.searchView(self, didSelectUrl: navigationAction.request.URL!)
			decisionHandler(.Cancel)
		}
		decisionHandler(.Allow)
	}

	func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
	}

	func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
		stopLoadingAnimation()
	}

	func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
		ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self)
	}

	func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
		ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self)
	}

	func userContentController(userContentController:  WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		handleJSMessage(message)
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
		self.webView!.snp_remakeConstraints { make in
			make.top.equalTo(0)
			make.left.right.equalTo(self.view)
			make.bottom.equalTo(self.view).offset(-keyboardHeight)
		}
		if let _ = self.spinnerView.superview {
			self.spinnerView.snp_makeConstraints { make in
				make.centerX.equalTo(self.view)
				make.top.equalTo((self.view.frame.size.height - keyboardHeight) / 2)
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
		//		let url = NSURL(string: "http://localhost:3005/extension/index.html")
		let url = NSURL(string: "http://cdn.cliqz.com/mobile/beta/index.html")
		self.webView!.loadRequest(NSURLRequest(URL: url!))
	}

	private func stopLoadingAnimation() {
		self.spinnerView.removeFromSuperview()
		self.spinnerView.stopAnimating()
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
            
            callJSMethod("resetState", parameter: configs)
        } else if let query = lastQuery { // the app was closed while searching
            configs["q"] = query
            // get current location if possible
            if let currentLocation = LocationManager.sharedInstance.location {
                configs["lat"] = currentLocation.coordinate.latitude
                configs["long"] = currentLocation.coordinate.longitude
            }
            
            callJSMethod("resetState", parameter: configs)
        }
        
    }
    
    private func handleJSMessage(message: WKScriptMessage) {
        
        switch message.name {
        case "jsBridge":
            if let input = message.body as? NSDictionary {
                if let action = input["action"] as? String {
                    handleJSAction(action, data: input["data"], callback: input["callback"] as? String)
                }
            } else {
                DebugLogger.log("Unhandled JS Bridge message with name :\(message.name), and body: \(message.body) !!!")
            }
        default:
            DebugLogger.log("Unhandled JS message with name : \(message.name) !!!")
            
        }
    }
    
    private func handleJSAction(action: String, data: AnyObject?, callback: String?) {
        
        switch action {
        case "searchHistory":
            let fullResults = NSDictionary(objects: [getHistory(), self.searchQuery!], forKeys: ["results", "query"])
            callJSMethod(callback, parameter: fullResults)
            
        case "openLink":
            if let url = data as? String {
                delegate?.searchView(self, didSelectUrl: NSURL(string: url)!)
            }
            
        case "pushTelemetry":
            if let telemetrySignal = data as? [String: AnyObject] {
                TelemetryLogger.sharedInstance.logEvent(.JavaScriptsignal(telemetrySignal))
            }
        case "browserAction":
            if let actionData = data as? [String: AnyObject], let actionType = actionData["type"] as? String {
                if actionType == "phoneNumber" {
                    if let phoneNumber = actionData["data"] as? String {
                        let trimmedPhoneNumber = phoneNumber.removeWhitespaces()
                        if let url = NSURL(string: "tel://\(trimmedPhoneNumber)") {
                            UIApplication.sharedApplication().openURL(url)
                        }
                    }
                }
            }
        case "notifyQuery":
            if let queryData = data as? [String: AnyObject],
                let query = queryData["q"] as? String {
                    delegate?.searchView(self, searchForQuery: query)

            }
        default:
            print("Unhandles JS action: \(action), with data: \(data)")
        }
    }
    
    private func callJSMethod(methodName: String?, parameter: AnyObject) {
        var jsonStr: NSString = ""
        do {
            let json = try NSJSONSerialization.dataWithJSONObject(parameter, options: NSJSONWritingOptions(rawValue: 0))
            jsonStr = NSString(data:json, encoding: NSUTF8StringEncoding)!
        } catch let error as NSError {
            print("Json conversion is failed with error: \(error)")
        }
        if let c = methodName {
            let exec = "\(c)(\(jsonStr))"
            self.webView!.evaluateJavaScript(exec, completionHandler: nil)
        }
    }
    
    
}
