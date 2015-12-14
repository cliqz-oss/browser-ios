//
//  RecommendationsViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 11/25/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import UIKit
import Shared
import Storage

protocol RecommendationsViewControllerDelegate: class {

	func recommendationsViewController(recommendationsViewController: RecommendationsViewController, didSelectURL url: NSURL?)

}

class RecommendationsViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

	lazy var topSitesWebView: WKWebView = {
		let config = WKWebViewConfiguration()
		let controller = WKUserContentController()
		config.userContentController = controller
		controller.addScriptMessageHandler(self, name: "jsBridge")
		
		let webView = WKWebView(frame: self.view.bounds, configuration: config)
		webView.navigationDelegate = self
		self.view.addSubview(webView)
		return webView
	}()

	var profile: Profile

	private let maxFrecencyLimit: Int = 30

	weak var delegate: RecommendationsViewControllerDelegate?

	init(profile: Profile) {
		self.profile = profile
		super.init(nibName: nil, bundle: nil)
	}

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func viewDidLoad() {
		super.viewDidLoad()

		let url = NSURL(string: "http://cdn.cliqz.com/mobile/beta/freshtab.html")
		self.topSitesWebView.loadRequest(NSURLRequest(URL: url!))
		
		self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
		self.navigationController?.navigationBar.barTintColor = UIColor(red: 68.0/255.0, green: 166.0/255.0, blue: 48.0/255.0, alpha: 1)
		self.navigationController?.navigationBar.titleTextAttributes = [
			NSForegroundColorAttributeName : UIColor.whiteColor()]
		
		self.navigationItem.rightBarButtonItem = createUIBarButton("past", action: Selector("dismiss"))

		self.setupConstraints()
		self.profile.history.setTopSitesCacheSize(Int32(maxFrecencyLimit))
		self.refreshTopSites(maxFrecencyLimit)
	}

	// Mark: WKScriptMessageHandler
	func userContentController(userContentController:  WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		switch message.name {
		case "jsBridge":
			if let input = message.body as? NSDictionary {
				if let action = input["action"] as? String {
					switch action {
					case "getTopSites":
						if let callback = input["callback"] as? String,
							limit = input["data"] as? Int {
								self.reloadTopSitesWithLimit(limit, callback: callback)
						}
					case "openLink":
						if let url = input["data"] as? String {
							self.delegate?.recommendationsViewController(self, didSelectURL: NSURL(string: url))
							self.dismiss()
						}
					default:
						print("Unhandled action: \(action)")
					}
				}
			}
		default:
			print("Unhandled Message")
		}
	}
	
	// Mark: Action handlers
	func dismiss() {
		self.dismissViewControllerAnimated(true, completion: nil)
        TelemetryLogger.sharedInstance.logEvent(.LayerChange("future", "present"))
	}
	
	// Mark: Data loader
	private func refreshTopSites(frecencyLimit: Int) {
		// Reload right away with whatever is in the cache, then check to see if the cache is invalid. If it's invalid,
		// invalidate the cache and requery. This allows us to always show results right away if they are cached but
		// also load in the up-to-date results asynchronously if needed
		reloadTopSitesWithLimit(frecencyLimit, callback: "") >>> {
			return self.profile.history.updateTopSitesCacheIfInvalidated() >>== { result in
				return result ? self.reloadTopSitesWithLimit(frecencyLimit, callback: "") : succeed()
			}
		}
	}

	private func reloadTopSitesWithLimit(limit: Int, callback: String) -> Success {
		return self.profile.history.getTopSitesWithLimit(limit).bindQueue(dispatch_get_main_queue()) { result in
			var results = Array<Dictionary<String, String>>()
			if let r = result.successValue {
				for site in r {
					var d = Dictionary<String, String>()
					d["url"] = site!.url
					d["title"] = site!.title
					results.append(d)
				}
			}
			do {
				let json = try NSJSONSerialization.dataWithJSONObject(results, options: NSJSONWritingOptions(rawValue: 0))
				let jsonStr = NSString(data:json, encoding: NSUTF8StringEncoding)!
				let exec = "\(callback)(\(jsonStr))"
				self.topSitesWebView.evaluateJavaScript(exec, completionHandler: nil)
			} catch let error as NSError {
				print("Json conversion is failed with error: \(error)")
			}
			return succeed()
		}
	}

	// Mark: Configure Layout
	private func setupConstraints() {
		self.topSitesWebView.snp_remakeConstraints { make in
			make.top.equalTo(0)
			make.left.right.bottom.equalTo(self.view)
		}
	}
	
	private func createUIBarButton(imageName: String, action: Selector) -> UIBarButtonItem {
		
		let button: UIButton = UIButton(type: UIButtonType.Custom)
		button.setImage(UIImage(named: imageName), forState: UIControlState.Normal)
		button.addTarget(self, action: action, forControlEvents: UIControlEvents.TouchUpInside)
		button.frame = CGRectMake(0, 0, 20, 20)
		
		let barButton = UIBarButtonItem(customView: button)
		return barButton
	}

}