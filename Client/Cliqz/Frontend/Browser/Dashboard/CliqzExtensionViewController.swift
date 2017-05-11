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
		loadExtensionStartTime = Date.getCurrentMillis()
        if self.extensionWebView.url == nil {
            let url = URL(string:  self.mainRequestURL())
            self.extensionWebView.load(URLRequest(url: url!))
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

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        self.loadExtensionWebView()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
        self.javaScriptBridge.publishEvent("show")
	}

	func mainRequestURL() -> String {
		return ""
	}

	// Mark: Configure Layout
	fileprivate func setupConstraints() {
		self.extensionWebView.snp.remakeConstraints { make in
			make.top.equalTo(topLayoutGuide.snp.bottom)
			make.left.right.bottom.equalTo(self.view)
		}
	}

	fileprivate func evaluateQueuedScripts() {
		for script in queuedScripts {
			self.evaluateJavaScript(script, completionHandler: nil)
		}
		queuedScripts.removeAll()
	}

}

extension CliqzExtensionViewController: WKNavigationDelegate, WKScriptMessageHandler {

	// Mark: Navigation delegate
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		ErrorHandler.handleError(.cliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
	}

	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		ErrorHandler.handleError(.cliqzErrorCodeScriptsLoadingFailed, delegate: self, error: error)
	}

	// Mark: WKScriptMessageHandler
	func userContentController(_ userContentController:  WKUserContentController, didReceive message: WKScriptMessage) {
		javaScriptBridge.handleJSMessage(message)
	}
}

extension CliqzExtensionViewController: JavaScriptBridgeDelegate {

	func didSelectUrl(_ url: URL) {
	}
	
	func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        guard self.isViewLoaded == true else {
            queuedScripts.append(javaScriptString)
            return
        }

		self.extensionWebView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler as! ((Any?, Error?) -> Void)?)
	}

    func isReady() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "ExtensionIsReady"), object: nil))
        evaluateQueuedScripts()
        self.logShowViewSignal()
    }

}


//MARK: - telemetry singals

extension CliqzExtensionViewController {
    
    fileprivate func logShowViewSignal() {
        if let startTime  =  loadExtensionStartTime {
            let duration = Int(Date.getCurrentMillis() - startTime)
            let customData = ["load_duration" : duration]
            TelemetryLogger.sharedInstance.logEvent(.DashBoard(viewType, "show", nil, customData))
            loadExtensionStartTime = nil
        }
        
    }
}
