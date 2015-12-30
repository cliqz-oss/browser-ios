//
//  SearchHistoryViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 11/25/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import UIKit
import Shared
import Storage

protocol SearchHistoryViewControllerDelegate: class {
    
    func didSelectURL(url: NSURL)
    func searchForQuery(query: String)
}

class SearchHistoryViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, UIAlertViewDelegate {
    
    lazy var historyWebView: WKWebView = {
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
    weak var delegate: SearchHistoryViewControllerDelegate?
    let QueryLimit = 50
    var reload = false
    
    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadHistory()
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 246.0/255.0, green: 90.0/255.0, blue: 42.0/255.0, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.whiteColor()]
        self.title = NSLocalizedString("Search history", comment: "Search history title")
        self.navigationItem.leftBarButtonItem = createUIBarButton("future", action: Selector("dismiss"))
        
        
        self.setupConstraints()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.reload == true {
            self.reload = false;
            self.historyWebView.reload()
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

    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
    }
    
    // Mark: Action handlers
    func dismiss() {
        TelemetryLogger.sharedInstance.logEvent(.LayerChange("past", "present"))
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func openSettings() {
        let settingsTableViewController = SettingsTableViewController()
        settingsTableViewController.profile = profile
        settingsTableViewController.tabManager = tabManager
        
        let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
        controller.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        presentViewController(controller, animated: true, completion: nil)
    }
    
    
    // Mark: Configure Layout
    private func setupConstraints() {
        self.historyWebView.snp_remakeConstraints { make in
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
    
    private func loadHistory() {
		let url = NSURL(string: "http://cdn.cliqz.com/mobile/beta/history.html")
//        let url = NSURL(string: "http://localhost:3005/extension/history.html")
        self.historyWebView.loadRequest(NSURLRequest(URL: url!))
    }
    
}


extension SearchHistoryViewController: JavaScriptBridgeDelegate {
    
    func didSelectUrl(url: NSURL) {
        delegate?.didSelectURL(url)
        self.dismiss()
    }
    
    func evaluateJavaScript(javaScriptString: String) {
        self.historyWebView.evaluateJavaScript(javaScriptString, completionHandler: nil)
    }
    
    func searchForQuery(query: String) {
        TelemetryLogger.sharedInstance.logEvent(.LayerChange("past", "present"))
        self.dismissViewControllerAnimated(true, completion: {
            delegate?.searchForQuery(query)
        })
    }
    
    func getSearchHistoryResults(callback: String?) {

        if callback != nil {
            self.profile.history.getSitesByLastVisit(QueryLimit).uponQueue(dispatch_get_main_queue()) { result in
                if let sites = result.successValue {
                    var historyResults = [[String: AnyObject]]()
                    for site in sites {
                        var d = [String: AnyObject]()
                        d["url"] = site!.url
                        d["title"] = site!.title
                        d["timestamp"] = Double(site!.latestVisit!.date) / 1000.0
                        d["score"] = 0
                        historyResults.append(d)
                    }
                    self.javaScriptBridge.callJSMethod(callback!, parameter: ["results": historyResults])
                }
            }
        }
    }

}

