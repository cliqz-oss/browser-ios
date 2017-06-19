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
import WebKit

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

	fileprivate let maxFrecencyLimit: Int = 30

	weak var delegate: BrowserNavigationDelegate?
    var reload = false

	fileprivate var spinnerView: UIActivityIndicatorView!

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
		
		self.navigationController?.navigationBar.tintColor = UIColor.white
		self.navigationController?.navigationBar.barTintColor = UIColor(red: 68.0/255.0, green: 166.0/255.0, blue: 48.0/255.0, alpha: 1)
		self.navigationController?.navigationBar.titleTextAttributes = [
			NSForegroundColorAttributeName : UIColor.white]
        self.title = NSLocalizedString("Search recommendations", tableName: "Cliqz", comment: "Search Recommendations and top visited sites title")
        
		self.navigationItem.leftBarButtonItems = createBarButtonItems("present", action: #selector(RecommendationsViewController.dismissAnimated))
		self.navigationItem.rightBarButtonItems = createBarButtonItems("cliqzSettings", action: #selector(RecommendationsViewController.openSettings))

		self.spinnerView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
		self.view.addSubview(spinnerView)
		spinnerView.startAnimating()

		self.setupConstraints()
		self.profile.history.setTopSitesCacheSize(Int32(maxFrecencyLimit))
		self.refreshTopSites(maxFrecencyLimit)
	}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.reload == true {
            self.reload = false;
            self.reloadTopSitesWithLimit(5, callback: "CLIQZEnvironment.displayTopSites")
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.reload = true;
    }

	// Mark: WKScriptMessageHandler
	func userContentController(_ userContentController:  WKUserContentController, didReceive message: WKScriptMessage) {
        javaScriptBridge.handleJSMessage(message)
	}
    
	// Mark: Navigation delegate
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		stopLoadingAnimation()
	}
	
	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		ErrorHandler.handleError(.cliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error as NSError)
	}
	
	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		ErrorHandler.handleError(.cliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error as NSError)
	}

	// Mark: Action handlers
	func dismissAnimated() {
		self.dismiss(animated: true, completion: nil)
	}

	func openSettings() {
		let settingsTableViewController = SettingsTableViewController()
		settingsTableViewController.profile = profile
		settingsTableViewController.tabManager = tabManager
		
		let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
		controller.modalPresentationStyle = UIModalPresentationStyle.formSheet
		present(controller, animated: true, completion: nil)
	}

	// Mark: AlertViewDelegate
	func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
		switch (buttonIndex) {
		case 0:
			stopLoadingAnimation()
		case 1:
			loadFreshtab()
		default:
			debugPrint("Unhandled Button Click")
		}
	}

	// Mark: Data loader
	fileprivate func refreshTopSites(_ frecencyLimit: Int) {
		// Reload right away with whatever is in the cache, then check to see if the cache is invalid. If it's invalid,
		// invalidate the cache and requery. This allows us to always show results right away if they are cached but
		// also load in the up-to-date results asynchronously if needed
		reloadTopSitesWithLimit(frecencyLimit, callback: "") >>> {
			return self.profile.history.updateTopSitesCacheIfInvalidated() >>== { result in
				return result ? self.reloadTopSitesWithLimit(frecencyLimit, callback: "") : succeed()
			}
		}
	}

	fileprivate func reloadTopSitesWithLimit(_ limit: Int, callback: String) -> Success {
		return self.profile.history.getTopSitesWithLimit(limit).bindQueue(DispatchQueue.main) { result in
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
				let json = try JSONSerialization.data(withJSONObject: results, options: JSONSerialization.WritingOptions(rawValue: 0))
				let jsonStr = NSString(data:json, encoding: String.Encoding.utf8.rawValue)!
				let exec = "\(callback)(\(jsonStr))"
				self.topSitesWebView.evaluateJavaScript(exec, completionHandler: nil)
			} catch let error as NSError {
				debugPrint("Json conversion is failed with error: \(error)")
			}
			return succeed()
		}
	}

	// Mark: Configure Layout
	fileprivate func setupConstraints() {
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
	
	fileprivate func createBarButtonItems(_ imageName: String, action: Selector) -> [UIBarButtonItem] {
		let button: UIButton = UIButton(type: UIButtonType.custom)
		button.setImage(UIImage(named: imageName), for: UIControlState())
		button.addTarget(self, action: action, for: UIControlEvents.touchUpInside)
		button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
		
		let barButton = UIBarButtonItem(customView: button)
        
        let spacerBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target:nil, action: nil)
        spacerBarButtonItem.width = -5
        
        return [spacerBarButtonItem, barButton]
	}

	fileprivate func loadFreshtab() {
        let url = URL(string: NavigationExtension.freshtabURL)
		self.topSitesWebView.load(URLRequest(url: url!))
	}
	
	fileprivate func stopLoadingAnimation() {
		self.spinnerView.removeFromSuperview()
		self.spinnerView.stopAnimating()
	}

}


extension RecommendationsViewController: JavaScriptBridgeDelegate {
    
    func didSelectUrl(_ url: URL) {
        delegate?.navigateToURL(url)
        self.dismissAnimated()
    }
    
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        self.topSitesWebView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler as! ((Any?, Error?) -> Void)?)
    }
}
