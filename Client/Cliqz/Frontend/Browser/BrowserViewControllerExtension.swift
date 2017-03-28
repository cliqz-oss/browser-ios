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
		   let url = NSURL(string: urlString) {
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
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                controller.preferredContentSize = CGSize(width: NewsNotificationPermissionViewControllerUX.Width, height: NewsNotificationPermissionViewControllerUX.Height)
                controller.modalPresentationStyle = UIModalPresentationStyle.FormSheet
            }
            
            self.presentViewController(controller, animated: true, completion: {
                self.urlBar.leaveOverlayMode()
            })
        }
    }

	func downloadVideoFromURL(url: String, sourceRect: CGRect) {
		if let filepath = NSBundle.mainBundle().pathForResource("main", ofType: "js") {
			do {
                let hudMessage = NSLocalizedString("Retrieving video information", tableName: "Cliqz", comment: "HUD message displayed while youtube downloader grabing the download URLs of the video")
                FeedbackUI.showLoadingHUD(hudMessage)
				let jsString = try NSString(contentsOfFile:filepath, encoding: NSUTF8StringEncoding)
				let context = JSContext()
				let httpRequest = XMLHttpRequest()
				httpRequest.extendJSContext(context)
				context.exceptionHandler = { context, exception in
					debugPrint("JS Error: \(exception)")
				}
				context.evaluateScript(jsString as String)
				let callback: @convention(block)([AnyObject])->()  = { [weak self] (urls) in
                    self?.downloadVideoOfSelectedFormat(urls, sourceRect: sourceRect)
				}
				let callbackName = "URLReceived"
				context.setObject(unsafeBitCast(callback, AnyObject.self), forKeyedSubscript: callbackName)
				context.evaluateScript("window.ytdownloader.getUrls('\(url)', \(callbackName))")
			} catch {
				debugPrint("Couldn't load file")
			}
		}
	}
	
	func downloadVideoOfSelectedFormat(urls: [AnyObject], sourceRect: CGRect) {
		if urls.count > 0 {
			TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("page_load", "is_downloadable", "true"))
		} else {
			TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("page_load", "is_downloadable", "false"))
		}
        FeedbackUI.dismissHUD()
        let title = NSLocalizedString("Video quality", tableName: "Cliqz", comment: "Youtube downloader action sheet title")
        let message = NSLocalizedString("Please select video quality", tableName: "Cliqz", comment: "Youtube downloader action sheet message")
 		let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
		for url in urls {
			if let f = url["label"] as? String, u = url["url"] as? String {
				actionSheet.addAction(UIAlertAction(title: f, style: .Default, handler: { _ in
					YoutubeVideoDownloader.downloadFromURL(u)
                    TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("click", "target", f.replace(" ", replacement: "_")))
				}))
			}
		}
        actionSheet.addAction(UIAlertAction(title: UIConstants.CancelString, style: .Cancel, handler: { _ in
            TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("click", "target", "cancel"))
        }))
        
        if let popoverPresentationController = actionSheet.popoverPresentationController {
            popoverPresentationController.sourceView = view
            let center = self.view.center
            popoverPresentationController.sourceRect = CGRectMake(center.x, center.y, 1, 1)
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
        }
		self.presentViewController(actionSheet, animated: true, completion: nil)
	}
	
	func SELBadRequestDetected(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) {
			
			if let tabId = notification.object as? Int where self.tabManager.selectedTab?.webView?.uniqueId == tabId {
                let newCount = (self.tabManager.selectedTab?.webView?.unsafeRequests)!
                self.urlBar.updateTrackersCount(newCount)
                if newCount > 0 && InteractiveIntro.sharedInstance.shouldShowAntitrackingHint {
                    self.showHint(.Antitracking)
                }
			}
			
		}
	}
    
	func urlBarDidClickAntitracking(urlBar: URLBarView, trackersCount: Int, status: String) {
        
        if let controlCenter = self.controlCenterController {
            if controlCenter.visible == true {
                self.controlCenterController?.closeControlCenter()
                self.controlCenterController?.visible = false
                
                // log telemetry signal
                let customData : [String: AnyObject] = ["tracker_count": trackersCount, "status": status, "state": "open"]
                logToolbarSignal("click", target: "control_center", customData: customData)
                
                return
            }
        }
        
        if let tab = self.tabManager.selectedTab, webView = tab.webView, url = webView.URL {
        
            let panelLayout = OrientationUtil.controlPanelLayout()
            
            let controlCenterVC = ControlCenterViewController(webViewID: webView.uniqueId, url:url, privateMode: tab.isPrivate)
            controlCenterVC.delegate = self
            controlCenterVC.controlCenterDelegate = self
            self.addChildViewController(controlCenterVC)
            self.controlCenterController = controlCenterVC
            
            let toolbarHeight: CGFloat = 44.0
            
            if (panelLayout != .LandscapeRegularSize){
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
            self.view.bringSubviewToFront(self.urlBar)
            //self.urlBar.enableAntitrackingButton(false)
            
            // log telemetry signal
            let customData : [String: AnyObject] = ["tracker_count": trackersCount, "status": status, "state": "closed"]
            logToolbarSignal("click", target: "control_center", customData: customData)
            
            
            if (panelLayout != .LandscapeRegularSize){
                UIView.animateWithDuration(0.5, animations: {
                    controlCenterVC.view.frame.origin.y = self.view.frame.origin.y + toolbarHeight
                    }, completion: { (finished) in
                        if finished {
                            self.view.bringSubviewToFront(controlCenterVC.view)
                            self.controlCenterController?.visible = true
                        }
                })
            }
            else { //Control center in landscape.
                // First resize the webview
                self.controlCenterActiveInLandscape = true
                self.updateViewConstraints()
                
                UIView.animateWithDuration(0.12, animations: {
                    controlCenterVC.view.frame.origin.x = self.view.frame.size.width/2
                    }, completion: { (finished) in
                        if finished {
                            self.view.bringSubviewToFront(controlCenterVC.view)
                            self.controlCenterController?.visible = true
                        }
                })
            }

        }
        
	}
    
    func urlBarDidClearSearchField(urlBar: URLBarView, oldText: String?) {
        if let charCount = oldText?.characters.count {
            self.logToolbarDeleteSignal(charCount)
        }
        self.urlBar(urlBar, didEnterText: "")
    }

	func controlCenterViewWillClose(controlCenterView: UIView) {
        if self.controlCenterActiveInLandscape {
            self.controlCenterActiveInLandscape = false
            self.updateViewConstraints()
        }
        self.controlCenterController = nil
		//self.urlBar.enableAntitrackingButton(true)
		self.view.bringSubviewToFront(self.urlBar)
	}
    func reloadCurrentPage() {
        if let tab = self.tabManager.selectedTab, webView = tab.webView {
            webView.reload()
        }
    }

    func showAntiPhishingAlert(domainName: String) {
        let antiPhishingShowTime = NSDate.getCurrentMillis()
        
        let title = NSLocalizedString("Warning: deceptive website!", tableName: "Cliqz", comment: "Antiphishing alert title")
        let message = NSLocalizedString("CLIQZ has blocked access to %1$ because it has been reported as a phishing website.Phishing websites disguise as other sites you may trust in order to trick you into disclosing your login, password or other sensitive information", tableName: "Cliqz", comment: "Antiphishing alert message")
        let personnalizedMessage = message.replace("%1$", replacement: domainName)
        
        let alert = UIAlertController(title: title, message: personnalizedMessage, preferredStyle: .Alert)
        
        let backToSafeSiteButtonTitle = NSLocalizedString("Back to safe site", tableName: "Cliqz", comment: "Back to safe site buttun title in antiphishing alert title")
        alert.addAction(UIAlertAction(title: backToSafeSiteButtonTitle, style: .Default, handler: { (action) in
            // go back
            self.goBack()
            TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("click", "back", nil))
            let duration = Int(NSDate.getCurrentMillis()-antiPhishingShowTime)
            TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("hide", nil, duration))
        }))
        
        let continueDespiteWarningButtonTitle = NSLocalizedString("Continue despite warning", tableName: "Cliqz", comment: "Continue despite warning buttun title in antiphishing alert title")
        alert.addAction(UIAlertAction(title: continueDespiteWarningButtonTitle, style: .Destructive, handler: { (action) in
            TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("click", "continue", nil))
            let duration = Int(NSDate.getCurrentMillis()-antiPhishingShowTime)
            TelemetryLogger.sharedInstance.logEvent(.AntiPhishing("hide", nil, duration))
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
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
    func logToolbarDeleteSignal(charCount: Int) {
        logToolbarSignal("click", target: "delete", customData: ["char_count": charCount])
        
    }
    func logToolbarOverviewSignal() {
        let openTabs = self.tabManager.tabs.count
        logToolbarSignal("click", target: "overview", customData: ["open_tabs_count" :openTabs])
    }
    func logToolbarReaderModeSignal(state: Bool) {
        logToolbarSignal("click", target: "reader_mode", customData: ["state" :state])
    }
    
    private func logToolbarSignal(action: String, target: String, customData: [String: AnyObject]?) {
        if let isForgetMode = self.tabManager.selectedTab?.isPrivate,
            let view = getCurrentView() {
            TelemetryLogger.sharedInstance.logEvent(.Toolbar(action, target, view, isForgetMode, customData))
        }
    }
    
    //MARK - keyboard telemetry signals
    func keyboardWillShow(notification: NSNotification) {
        if let isForgetMode = self.tabManager.selectedTab?.isPrivate,
            let view = getCurrentView() {
            keyboardShowTime = NSDate.getCurrentMillis()
            TelemetryLogger.sharedInstance.logEvent(.Keyboard("show", view, isForgetMode, nil))
        }
    }
    func keyboardWillHide(notification: NSNotification) {
        if let isForgetMode = self.tabManager.selectedTab?.isPrivate,
            let view = getCurrentView(),
            let showTime = keyboardShowTime {
            let showDuration = Int(NSDate.getCurrentMillis() - showTime)
            TelemetryLogger.sharedInstance.logEvent(.Keyboard("hide", view, isForgetMode, showDuration))
            keyboardShowTime = nil
        }
    }
    
    //MARK - WebMenu signals
    func logWebMenuSignal(action: String, target: String) {
        if let isForgetMode = self.tabManager.selectedTab?.isPrivate {
            TelemetryLogger.sharedInstance.logEvent(.WebMenu(action, target, isForgetMode))
        }
    }

	func showHint(type: HintType) {
        if type == HintType.Antitracking && self.urlBar.isAntiTrackingButtonHidden(){
            return
        }
		let intro = InteractiveIntroViewController()
		intro.modalPresentationStyle = .OverFullScreen
		intro.showHint(type)
		self.presentViewController(intro, animated: true) { 
			InteractiveIntro.sharedInstance.updateHintPref(type, value: false)
		}
		
	}
}

