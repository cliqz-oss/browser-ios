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

	func didSelectURL(url: NSURL)
}

class RecommendationsViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, UIAlertViewDelegate {

	lazy var topSitesWebView: WKWebView = {
        let config = ConfigurationManager.sharedInstance.getSharedConfiguration(self)
        
		let webView = WKWebView(frame: self.view.bounds, configuration: config)
		webView.navigationDelegate = self
		self.view.addSubview(webView)
		return webView
	}()
    
    lazy var javaScriptBridge: JavaScriptBridge = {
        let javaScriptBridge = JavaScriptBridge(profile: self.profile)
        javaScriptBridge.delegate = self
        return javaScriptBridge
    }()

	var profile: Profile!
	var tabManager: TabManager!

	private let maxFrecencyLimit: Int = 30

	weak var delegate: RecommendationsViewControllerDelegate?
    var reload = false

	private var spinnerView: UIActivityIndicatorView!

	init(profile: Profile) {
		self.profile = profile
		super.init(nibName: nil, bundle: nil)
	}

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func viewDidLoad() {
		super.viewDidLoad()

		loadFreshtab()
		
		self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
		self.navigationController?.navigationBar.barTintColor = UIColor(red: 68.0/255.0, green: 166.0/255.0, blue: 48.0/255.0, alpha: 1)
		self.navigationController?.navigationBar.titleTextAttributes = [
			NSForegroundColorAttributeName : UIColor.whiteColor()]
        self.title = NSLocalizedString("Search recommendations", tableName: "Cliqz", comment: "Search Recommendations and top visited sites title")
        
		self.navigationItem.leftBarButtonItems = createBarButtonItems("present", action: Selector("dismiss"))
		self.navigationItem.rightBarButtonItems = createBarButtonItems("cliqzSettings", action: Selector("openSettings"))

		self.spinnerView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
		self.view.addSubview(spinnerView)
		spinnerView.startAnimating()

		self.setupConstraints()
		self.profile.history.setTopSitesCacheSize(Int32(maxFrecencyLimit))
		self.refreshTopSites(maxFrecencyLimit)
	}
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.reload == true {
            self.reload = false;
            self.reloadTopSitesWithLimit(5, callback: "CLIQZEnvironment.displayTopSites")
        }
    }
    override func viewWillDisappear(animated: Bool) {
        self.reload = true;
    }

	// Mark: WKScriptMessageHandler
	func userContentController(userContentController:  WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        javaScriptBridge.handleJSMessage(message)
	}
    
	// Mark: Navigation delegate
	func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
		stopLoadingAnimation()
	}
	
	func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
		ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
	}
	
	func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
		ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
	}

	// Mark: Action handlers
	func dismiss() {
		self.dismissViewControllerAnimated(true, completion: nil)
        TelemetryLogger.sharedInstance.logEvent(.LayerChange("future", "present"))
	}

	func openSettings() {
		let settingsTableViewController = SettingsTableViewController()
		settingsTableViewController.profile = profile
		settingsTableViewController.tabManager = tabManager
		
		let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
		controller.modalPresentationStyle = UIModalPresentationStyle.FormSheet
		presentViewController(controller, animated: true, completion: nil)
	}

	// Mark: AlertViewDelegate
	func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
		switch (buttonIndex) {
		case 0:
			stopLoadingAnimation()
		case 1:
			loadFreshtab()
		default:
			print("Unhandled Button Click")
		}
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
            var results = [[String: String]]()
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
		if let _ = self.spinnerView.superview {
			self.spinnerView.snp_makeConstraints { make in
				make.center.equalTo(self.view)
			}
		}
	}
	
	private func createBarButtonItems(imageName: String, action: Selector) -> [UIBarButtonItem] {
		let button: UIButton = UIButton(type: UIButtonType.Custom)
		button.setImage(UIImage(named: imageName), forState: UIControlState.Normal)
		button.addTarget(self, action: action, forControlEvents: UIControlEvents.TouchUpInside)
		button.frame = CGRectMake(0, 0, 36, 36)
		
		let barButton = UIBarButtonItem(customView: button)
        
        let spacerBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target:nil, action: nil)
        spacerBarButtonItem.width = -5
        
        return [spacerBarButtonItem, barButton]
	}

	private func loadFreshtab() {
        let url = NSURL(string: NavigationExtension.freshtabURL)
		self.topSitesWebView.loadRequest(NSURLRequest(URL: url!))
	}
	
	private func stopLoadingAnimation() {
		self.spinnerView.removeFromSuperview()
		self.spinnerView.stopAnimating()
	}

}


extension RecommendationsViewController: JavaScriptBridgeDelegate {
    
    func didSelectUrl(url: NSURL) {
        delegate?.didSelectURL(url)
        self.dismiss()
    }
    
    func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        self.topSitesWebView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
}
