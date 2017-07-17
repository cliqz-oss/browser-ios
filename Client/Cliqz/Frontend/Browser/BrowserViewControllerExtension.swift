//
//  BrowserViewControllerExtension.swift
//  Client
//
//  Created by Sahakyan on 4/28/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import JavaScriptCore

extension BrowserViewController: ControlCenterViewDelegate {

	func loadInitialURL() {
		if let urlString = self.initialURL,
		   let url = URL(string: urlString) {
			self.navigateToURL(url)
            if let tab = tabManager.selectedTab {
                tab.url = url
            }
			self.initialURL = nil
		}
	}

    func askForNewsNotificationPermissionIfNeeded () {
        if (NewsNotificationPermissionHelper.sharedInstance.shouldAskForPermission() ){
            let controller = UINavigationController(rootViewController: NewsNotificationPermissionViewController())
            if UIDevice.current.userInterfaceIdiom == .pad {
                controller.preferredContentSize = CGSize(width: NewsNotificationPermissionViewControllerUX.Width, height: NewsNotificationPermissionViewControllerUX.Height)
                controller.modalPresentationStyle = UIModalPresentationStyle.formSheet
            }
            
            self.present(controller, animated: true, completion: {
                self.urlBar.leaveOverlayMode()
            })
        }
    }

	func downloadVideoFromURL(_ url: String, sourceRect: CGRect) {
		if let filepath = Bundle.main.path(forResource: "main", ofType: "js") {
			do {
                let hudMessage = NSLocalizedString("Retrieving video information", tableName: "Cliqz", comment: "HUD message displayed while youtube downloader grabing the download URLs of the video")
                FeedbackUI.showLoadingHUD(hudMessage)
				let jsString = try NSString(contentsOfFile:filepath, encoding: String.Encoding.utf8.rawValue)
				if let context = JSContext() {
					let httpRequest = XMLHttpRequest()
					httpRequest.extendJSContext(context)
					context.exceptionHandler = { context, exception in
						print("JS Error: \(exception)")
					}
					context.evaluateScript(jsString as String)
					let callback: @convention(block)([AnyObject])->()  = { [weak self] (urls) in
						self?.downloadVideoOfSelectedFormat(urls, sourceRect: sourceRect)
					}
					let callbackName = "URLReceived"
					context.setObject(unsafeBitCast(callback, to: AnyObject.self), forKeyedSubscript: callbackName as (NSCopying & NSObjectProtocol)!)
					context.evaluateScript("window.ytdownloader.getUrls('\(url)', \(callbackName))")
				}
			} catch {
				debugPrint("Couldn't load file")
			}
		}
	}
	
	func downloadVideoOfSelectedFormat(_ urls: [AnyObject], sourceRect: CGRect) {
		if urls.count > 0 {
			TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("page_load", ["is_downloadable": true]))
		} else {
			TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("page_load", ["is_downloadable": false]))
		}
        FeedbackUI.dismissHUD()
        let title = NSLocalizedString("Video quality", tableName: "Cliqz", comment: "Youtube downloader action sheet title")
        let message = NSLocalizedString("Please select video quality", tableName: "Cliqz", comment: "Youtube downloader action sheet message")
 		let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
		for url in urls {
			if let f = url["label"] as? String, let u = url["url"] as? String {
				actionSheet.addAction(UIAlertAction(title: f, style: .default, handler: { _ in
					YoutubeVideoDownloader.downloadFromURL(u)
                    TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("click", ["target": f.replace(" ", replacement: "_")]))
				}))
			}
		}
        actionSheet.addAction(UIAlertAction(title: UIConstants.CancelString, style: .cancel, handler: { _ in
            TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("click", ["target": "cancel"]))
        }))
        
        if let popoverPresentationController = actionSheet.popoverPresentationController {
            popoverPresentationController.sourceView = view
            let center = self.view.center
            popoverPresentationController.sourceRect = CGRect(x: center.x, y: center.y, width: 1, height: 1)
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
        }
		self.present(actionSheet, animated: true, completion: nil)
	}
	
	func SELBadRequestDetected(_ notification: Notification) {
		DispatchQueue.main.async {
			
			if let tabId = notification.object as? Int, self.tabManager.selectedTab?.webView?.uniqueId == tabId {
                let newCount = (self.tabManager.selectedTab?.webView?.unsafeRequests)!
                self.urlBar.updateTrackersCount(newCount)
                if newCount > 0 && InteractiveIntro.sharedInstance.shouldShowAntitrackingHint() && !self.urlBar.isAntiTrackingButtonHidden() {
                    self.showHint(.antitracking(newCount))
                }
			}
			
		}
	}
    
	func urlBarDidClickAntitracking(_ urlBar: URLBarView, trackersCount: Int, status: String) {
        
        if let controlCenter = self.controlCenterController {
            if controlCenter.visible == true {
                self.controlCenterController?.closeControlCenter()
                self.controlCenterController?.visible = false
                
                // log telemetry signal
                let customData : [String: AnyObject] = ["tracker_count": trackersCount as AnyObject, "status": status as AnyObject, "state": "open" as AnyObject]
                logToolbarSignal("click", target: "control_center", customData: customData)
                
                return
            }
        }
        
        if let tab = self.tabManager.selectedTab, let webView = tab.webView, let url = self.urlBar.currentURL {
        
            let panelLayout = OrientationUtil.controlPanelLayout()
            
            let controlCenterVC = ControlCenterViewController(webViewID: webView.uniqueId, url:url, privateMode: tab.isPrivate)
            controlCenterVC.delegate = self
            controlCenterVC.controlCenterDelegate = self
            self.addChildViewController(controlCenterVC)
            self.controlCenterController = controlCenterVC
            
            let toolbarHeight: CGFloat = 44.0
            
            if (panelLayout != .landscapeRegularSize){
                var r = self.view.bounds
                r.origin.y = -r.size.height
                r.size.height = r.size.height - toolbarHeight
                controlCenterVC.view.frame = r
            }
            else{
                var r = self.view.frame
                r.origin.x = r.size.width
                r.origin.y = r.origin.y + toolbarHeight
                r.size.width = r.size.width/2
                r.size.height = r.size.height - toolbarHeight
                controlCenterVC.view.frame = r
            }
            
            self.view.addSubview(controlCenterVC.view)
            self.view.bringSubview(toFront: self.urlBar)
            //self.urlBar.enableAntitrackingButton(false)
            
            // log telemetry signal
            let customData : [String: AnyObject] = ["tracker_count": trackersCount as AnyObject, "status": status as AnyObject, "state": "closed" as AnyObject]
            logToolbarSignal("click", target: "control_center", customData: customData)
            
            
            if (panelLayout != .landscapeRegularSize){
                UIView.animate(withDuration: 0.5, animations: {
                    controlCenterVC.view.frame.origin.y = self.view.frame.origin.y + toolbarHeight
                    }, completion: { (finished) in
                        if finished {
                            self.view.bringSubview(toFront: controlCenterVC.view)
                            self.controlCenterController?.visible = true
                        }
                })
            }
            else { //Control center in landscape.
                // First resize the webview
                self.controlCenterActiveInLandscape = true
                self.updateViewConstraints()
                
                UIView.animate(withDuration: 0.12, animations: {
                    controlCenterVC.view.frame.origin.x = self.view.frame.size.width/2
                    }, completion: { (finished) in
                        if finished {
                            self.view.bringSubview(toFront: controlCenterVC.view)
                            self.controlCenterController?.visible = true
                        }
                })
            }

        }
        
	}
    
    func urlBarDidClearSearchField(_ urlBar: URLBarView, oldText: String?) {
        if let charCount = oldText?.characters.count {
            self.logToolbarDeleteSignal(charCount)
        }
        self.urlBar(urlBar, didEnterText: "")
    }

	func controlCenterViewWillClose(_ controlCenterView: UIView) {
        if self.controlCenterActiveInLandscape {
            self.controlCenterActiveInLandscape = false
            self.updateViewConstraints()
        }
        self.controlCenterController = nil
		//self.urlBar.enableAntitrackingButton(true)
		self.view.bringSubview(toFront: self.urlBar)
	}
    func reloadCurrentPage() {
        if let tab = self.tabManager.selectedTab, let webView = tab.webView {
            webView.reload()
        }
    }

    func showAntiPhishingAlert(_ domainName: String) {
        let antiPhishingShowTime = Date.getCurrentMillis()
        
        let title = NSLocalizedString("Warning: deceptive website!", tableName: "Cliqz", comment: "Antiphishing alert title")
        let message = NSLocalizedString("CLIQZ has blocked access to %1$ because it has been reported as a phishing website.Phishing websites disguise as other sites you may trust in order to trick you into disclosing your login, password or other sensitive information", tableName: "Cliqz", comment: "Antiphishing alert message")
        let personnalizedMessage = message.replace("%1$", replacement: domainName)
        
        let alert = UIAlertController(title: title, message: personnalizedMessage, preferredStyle: .alert)
        
        let backToSafeSiteButtonTitle = NSLocalizedString("Back to safe site", tableName: "Cliqz", comment: "Back to safe site buttun title in antiphishing alert title")
        alert.addAction(UIAlertAction(title: backToSafeSiteButtonTitle, style: .default, handler: { (action) in
            // go back
            self.goBack()
            TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("click", "back", nil))
            let duration = Int(Date.getCurrentMillis()-antiPhishingShowTime)
            TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("hide", nil, duration))
        }))
        
        let continueDespiteWarningButtonTitle = NSLocalizedString("Continue despite warning", tableName: "Cliqz", comment: "Continue despite warning buttun title in antiphishing alert title")
        alert.addAction(UIAlertAction(title: continueDespiteWarningButtonTitle, style: .destructive, handler: { (action) in
            TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("click", "continue", nil))
            let duration = Int(Date.getCurrentMillis()-antiPhishingShowTime)
            TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("hide", nil, duration))
        }))
        
        self.present(alert, animated: true, completion: nil)
        TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("show", nil, nil))
        
    }
    
    // MARK: - toolbar telemetry signals
    func logToolbarFocusSignal() {
        logToolbarSignal("focus", target: "search", customData: nil)
        SearchBarTelemetryHelper.sharedInstance.didFocusUrlBar()
    }
    func logToolbarBlurSignal() {
        logToolbarSignal("blur", target: "search", customData: nil)
    }
    func logToolbarDeleteSignal(_ charCount: Int) {
        logToolbarSignal("click", target: "delete", customData: ["char_count": charCount as AnyObject])
        
    }
    func logToolbarOverviewSignal() {
        let openTabs = self.tabManager.tabs.count
        logToolbarSignal("click", target: "overview", customData: ["open_tabs_count" :openTabs as AnyObject])
    }
    func logToolbarReaderModeSignal(_ state: Bool) {
        logToolbarSignal("click", target: "reader_mode", customData: ["state" :state as AnyObject])
    }
    
    fileprivate func logToolbarSignal(_ action: String, target: String, customData: [String: AnyObject]?) {
        if let isForgetMode = self.tabManager.selectedTab?.isPrivate,
            let view = getCurrentView() {
            TelemetryLogger.sharedInstance.logEvent(.Toolbar(action, target, view, isForgetMode, customData))
        }
    }
    
    //MARK - keyboard telemetry signals
    func keyboardWillShow(_ notification: Notification) {
        if let isForgetMode = self.tabManager.selectedTab?.isPrivate,
            let view = getCurrentView() {
            keyboardShowTime = Date.getCurrentMillis()
            TelemetryLogger.sharedInstance.logEvent(.Keyboard("show", view, isForgetMode, nil))
        }
    }
    func keyboardWillHide(_ notification: Notification) {
        if let isForgetMode = self.tabManager.selectedTab?.isPrivate,
            let view = getCurrentView(),
            let showTime = keyboardShowTime {
            let showDuration = Int(Date.getCurrentMillis() - showTime)
            TelemetryLogger.sharedInstance.logEvent(.Keyboard("hide", view, isForgetMode, showDuration))
            keyboardShowTime = nil
        }
    }
    
    //MARK - WebMenu signals
    func logWebMenuSignal(_ action: String, target: String) {
        if let isForgetMode = self.tabManager.selectedTab?.isPrivate {
            TelemetryLogger.sharedInstance.logEvent(.WebMenu(action, target, isForgetMode))
        }
    }


    func showHint(_ type: HintType) {
        
        let intro = InteractiveIntroViewController()
		intro.modalPresentationStyle = .overFullScreen
        intro.showHint(type)
		self.present(intro, animated: true) { 
			InteractiveIntro.sharedInstance.updateHintPref(type, value: false)
		}
		
	}
    
    // MARK: - Connect
    
    func openTabViaConnect(notification: NSNotification) {
        guard let data = notification.object as? [String: String], let urlString = data["url"] else {
            return
        }
        if let url = URL(string: urlString)  {
            openURLInNewTab(url)
            self.urlBar.leaveOverlayMode()
            self.homePanelController?.view.isHidden = true
        }
        
        // Telemetry
        TelemetryLogger.sharedInstance.logEvent(.Connect("open_tab", nil))
    }
    
    func downloadVideoViaConnect(notification: NSNotification) {
        guard let data = notification.object as? [String: String], let urlString = data["url"] else {
            return
        }
        
        let limitMobileDataUsage = SettingsPrefs.getLimitMobileDataUsagePref()
        
        if let networkReachabilityStatus = NetworkReachability.sharedInstance.networkReachabilityStatus, limitMobileDataUsage == true && networkReachabilityStatus != .reachableViaWiFi {
            showNoWifiConnectionAlert()
            return
        }
        
        YoutubeVideoDownloader.downloadFromURL(urlString, viaConnect: true)
    }
    
    func showNoWifiConnectionAlert() {
        let title = NSLocalizedString("No Wi-Fi Connection", tableName: "Cliqz", comment: "[Connect] No Wi-Fi connection alert title")
        let message = NSLocalizedString("No Wi-Fi Connection message", tableName: "Cliqz", comment: "[Connect] No Wi-Fi connection alert message")
        
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", tableName: "Cliqz", comment: "Settings"), style: .default) { (_) in
            
            self.openSettings()
        }
        
        let dismissAction = UIAlertAction(title: NSLocalizedString("Dismiss", tableName: "Cliqz", comment: "Dismiss No Wi-Fi connection alert"), style: .cancel) { (_) in }
        
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(settingsAction)
        alertController.addAction(dismissAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

