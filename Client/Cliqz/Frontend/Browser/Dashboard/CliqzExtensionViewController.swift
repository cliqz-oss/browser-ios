//
//  CliqzExtensionViewController.swift
//  Client
//
//  Created by Sahakyan on 8/24/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import WebKit

class CliqzExtensionViewController: UIViewController,  UIAlertViewDelegate {
	
    var profile: Profile!
    var loadExtensionStartTime : Double?
    var viewType: String
	
	lazy var extensionWebView: WKWebView = {
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

	var queuedScripts = [String]()
	
//	weak var delegate: FavoritesDelegate?
    init(profile: Profile) {
        self.profile = profile
        self.viewType = "NONE"
        super.init(nibName: nil, bundle: nil)
    }
    
    init(profile: Profile, viewType: String) {
		self.profile = profile
        self.viewType = viewType
		super.init(nibName: nil, bundle: nil)
	}

    func loadExtensionWebView() {
		loadExtensionStartTime = NSDate.getCurrentMillis()
        if self.extensionWebView.URL == nil {
            let url = NSURL(string:  self.mainRequestURL())
            self.extensionWebView.loadRequest(NSURLRequest(URL: url!))
        }
    }

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
    }

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.setupConstraints()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
        self.loadExtensionWebView()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
        self.javaScriptBridge.publishEvent("show")
	}

	func mainRequestURL() -> String {
		return ""
	}

	// Mark: Configure Layout
	private func setupConstraints() {
		self.extensionWebView.snp_remakeConstraints { make in
			make.top.equalTo(snp_topLayoutGuideBottom)
			make.left.right.bottom.equalTo(self.view)
		}
	}

	private func evaluateQueuedScripts() {
		for script in queuedScripts {
			self.evaluateJavaScript(script, completionHandler: nil)
		}
		queuedScripts.removeAll()
	}

}

extension CliqzExtensionViewController: WKNavigationDelegate, WKScriptMessageHandler {

	// Mark: Navigation delegate
	func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
		
	}

	func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
		ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
	}

	func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
		ErrorHandler.handleError(.CliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
	}

	// Mark: WKScriptMessageHandler
	func userContentController(userContentController:  WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		javaScriptBridge.handleJSMessage(message)
	}
}

extension CliqzExtensionViewController: JavaScriptBridgeDelegate {

	func didSelectUrl(url: NSURL) {
	}
	
	func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        guard self.isViewLoaded() == true else {
            queuedScripts.append(javaScriptString)
            return
        }

		self.extensionWebView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
	}

    func isReady() {
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "ExtensionIsReady", object: nil))
        evaluateQueuedScripts()
        self.logShowViewSignal()
    }

}


//MARK: - telemetry singals

extension CliqzExtensionViewController {
    
    private func logShowViewSignal() {
        if let startTime  =  loadExtensionStartTime {
            let duration = Int(NSDate.getCurrentMillis() - startTime)
            let customData = ["load_duration" : duration]
            TelemetryLogger.sharedInstance.logEvent(.DashBoard(viewType, "show", nil, customData))
            loadExtensionStartTime = nil
        }
        
    }
}
