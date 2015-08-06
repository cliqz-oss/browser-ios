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
		var config = WKWebViewConfiguration()
		let controller = WKUserContentController()
		config.userContentController = controller
		controller.addScriptMessageHandler(self, name: "interOp")
        self.webView = WKWebView(frame: self.view.bounds, configuration: config)
        self.webView?.setTranslatesAutoresizingMaskIntoConstraints(false)
		self.webView?.navigationDelegate = self;
        self.view.addSubview(self.webView!)
		self.view.backgroundColor = UIColor.redColor()
//		var theWebView = WKWebView(frame:self.view.frame,
//			configuration: theConfiguration)
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|[webView]|",
            options: NSLayoutFormatOptions(0),
            metrics: nil,
            views: ["webView": self.webView!]))
        
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            "V:|[webView]|",
            options: NSLayoutFormatOptions(0),
            metrics: nil,
            views: ["webView": self.webView!]))
		let myFilePath = NSBundle.mainBundle().pathForResource("tool_iOS/index", ofType: "html")
		var error: NSError?
		var content: String?
		content = String(contentsOfFile: myFilePath!, encoding: NSUTF8StringEncoding)
		var x = NSBundle.mainBundle().bundlePath as String
		x.extend("/tool_iOS/")
		let baseUrl = NSURL(fileURLWithPath: x, isDirectory: true)
		var u = NSURL(string: "http://localhost:3000/extension/index.html")
		self.webView!.loadRequest(NSURLRequest(URL:u!))
//		self.webView!.loadHTMLString(content!, baseURL: baseUrl)

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
//		println("^^^^^^ ---- \(data)")
		self.historyResults.removeAll(keepCapacity: true)
		for site in data {
//			println("HistItem^^^^ --- \(site)")
			var d = Dictionary<String, String>()
			d["url"] = site!.url
			d["title"] = site!.title
//			println("HistItem111^^^^ --- \(d)")

			self.historyResults.append(d)
		}
//		println("ALLL HISSSTTT -- \(self.historyResults)")
//		self.data = data
//		tableView.reloadData()
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
//		self.webView!.stringByEvaluatingJavaScriptFromString(JSString!)
//			stringByEvaluatingJavaScriptFromString(JSString!)
	}
	
	func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		println("QQQ -- \(request)")
		if request.URL!.absoluteString != nil && request.URL!.absoluteString!.hasPrefix("http") {
			delegate?.searchView(self, didSelectUrl: request.URL!)
			return false
		} else if (true) {
		}
		return true
	}

	func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
		if navigationAction.request.URL!.absoluteString != nil && !navigationAction.request.URL!.absoluteString!.hasPrefix("http://localhost:3000/") {
			delegate?.searchView(self, didSelectUrl: navigationAction.request.URL!)
			decisionHandler(.Cancel)
		}
		decisionHandler(.Allow)
	}

	func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
	}

	func userContentController(userContentController:  WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		if message.name == "interOp" {
			println("Received event \(message.body) --- \(message.name)")
			let input = message.body as! NSDictionary
			let callbakcID = input.objectForKey("callbackId")
			let query = input.objectForKey("query") as? String
			var error: NSError?
//			println("HISTORYYYYYYY --- \(self.historyResults)")
			var jsonStr: NSString = ""
			if let json = NSJSONSerialization.dataWithJSONObject(self.historyResults, options: NSJSONWritingOptions.allZeros, error: &error) {
				jsonStr = NSString(data:json, encoding: NSUTF8StringEncoding)!
			}

//			println("JSONFAIIILLL --- \(error)")
			let exec = "CLIQZEnvironment.historySearchDone(\(callbakcID!), '\(query!)', '\(jsonStr)');"
			println("historyresults!!! --- \(exec)")
			self.webView!.evaluateJavaScript(exec, completionHandler: nil)
		}
	}

//    @IBAction func closeBrowser(sender: AnyObject) {
//        self.willBeDismissed?()
//		AWSAnalyticsHandler.logEvent(.BackToSearch, attribute: nil)
//        dismissViewControllerAnimated(true, completion: nil)
//    }
//
//	@IBAction func closeTab(sender: AnyObject) {
//		self.pagingScrollView.closeCurrentPage()
//	}
//	
//	func pagingScrollView(pagingScrollView: PagingScrollView, didCloseTabAtIndex index: Int) {
////		self.urls.removeObjectAtIndex(index)
////		self.urls.removeAtIndex(index)
//		if self.urls.count == 0 {
//			self.closeBrowser(self.pagingScrollView)
//		}
//	}

//	func loadURLs(urls: NSMutableArray) {
//		self.urls = urls
////		if let u = url {
////			self.urls.append(u)
//////			self.pagingScrollView.loadUrl(u)
////		}
//	}

    // MARK: UIProgressView lifecycle
    
//    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
//        if keyPath == "estimatedProgress" && object as! NSObject == webView! {
//            let newValue = change["new"] as! Float
//            self.progressView.setProgress(newValue, animated: true)
//            if newValue == 1.0 {
//                self.progressView.hidden = true
//            }
//        }
//    }
//
//    func finishProgress() {
//        self.progressView.setProgress(1, animated: true)
//        UIView.animateWithDuration(0.2, delay: 0.3, options: UIViewAnimationOptions(), animations: { () -> Void in
//            self.progressView.hidden = true
//            return
//        }, completion: nil)
//    }
	
    // MARK: WKNavigationDelegate methods
    
	
//	
//	func pagingScrollViewDidStartPageLoading(pagingScrollView: PagingScrollView) {
//		self.progressView.setProgress(0, animated: false)
//		self.progressView.setProgress(0.1, animated: true)
//		self.progressView.hidden = false
//	}
	
//	func pagingScrollViewDidFinishPageLoading(pagingScrollView: PagingScrollView) {
//		finishProgress()
//	}
	
//	func pagingScrollView(pagingScrollView: PagingScrollView, estimatedProgressChanged newValue: Double) {
//		let f = Float(newValue)
//		self.progressView.setProgress(f, animated: true)
//		if newValue == 1.0 {
//			self.progressView.hidden = true
//		}
//	}

}
