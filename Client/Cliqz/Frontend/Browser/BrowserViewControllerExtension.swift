//
//  BrowserViewControllerExtension.swift
//  Client
//
//  Created by Sahakyan on 4/28/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import JavaScriptCore

extension BrowserViewController {
	
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
	
	func downloadVideoFromURL(url: String) {
		if let filepath = NSBundle.mainBundle().pathForResource("main", ofType: "js") {
			do {
				let jsString = try NSString(contentsOfFile:filepath, encoding: NSUTF8StringEncoding)
				let context = JSContext()
				let httpRequest = XMLHttpRequest()
				httpRequest.extendJSContext(context)
				context.exceptionHandler = { context, exception in
					print("JS Error: \(exception)")
				}
				context.evaluateScript(jsString as String)
				let callback: @convention(block)([AnyObject])->()  = { [weak self] (urls) in
					self?.downloadVideoOfSelectedFormat(urls)
				}
				let callbackName = "URLReceived"
				context.setObject(unsafeBitCast(callback, AnyObject.self), forKeyedSubscript: callbackName)
				context.evaluateScript("window.ytdownloader.getUrls('\(url)', \(callbackName))")
			} catch {
				print("Couldn't load file")
			}
		}
	}
	
	func downloadVideoOfSelectedFormat(urls: [AnyObject]) {
		if urls.count > 0 {
			TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("video_downloader", "page_load", "is_downloadable", "true"))
		} else {
			TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("video_downloader", "page_load", "is_downloadable", "false"))
		}
 		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
		for url in urls {
			if let f = url["label"] as? String, u = url["url"] as? String {
				actionSheet.addAction(UIAlertAction(title: f, style: .Default, handler: { _ in
					YoutubeVideoDownloader.downloadFromURL(u)
				}))
			}
		}
		actionSheet.addAction(UIAlertAction(title: UIConstants.CancelString, style: .Cancel, handler: nil))
		self.presentViewController(actionSheet, animated: true, completion: nil)
	}
	
	func SELBadRequestDetected(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) {
			var x = notification.object as? Int
			if x == nil {
				x = 0
			}
			if self.tabManager.selectedTab?.webView?.uniqueId == x {
				self.urlBar.updateTrackersCount((self.tabManager.selectedTab?.webView?.badRequests)!)
			}
		}
	}

	func urlBarDidClickAntitracking(urlBar: URLBarView) {
		if let tab = self.tabManager.selectedTab, webView = tab.webView {
			let antitrackingVC = AntitrackingViewController(webViewID: webView.uniqueId, privateMode: tab.isPrivate)
			antitrackingVC.delegate = self
			self.addChildViewController(antitrackingVC)
			var r = self.view.bounds
			r.origin.y = -r.size.height
			antitrackingVC.view.frame = r
			self.view.addSubview(antitrackingVC.view)
			UIView.animateWithDuration(0.5) {
				antitrackingVC.view.center = self.view.center
			}
		}
	}
    
    func showAntiPhishingAlert(domainName: String) {
        let title = NSLocalizedString("Warning: deceptive website!", tableName: "Cliqz", comment: "Antiphishing alert title")
        let message = NSLocalizedString("CLIQZ has blocked access to %1$ because it has been reported as a phishing website.Phishing websites disguise as other sites you may trust in order to trick you into disclosing your login, password or other sensitive information", tableName: "Cliqz", comment: "Antiphishing alert message")
        let personnalizedMessage = message.replace("%1$", replacement: domainName)
        
        let alert = UIAlertController(title: title, message: personnalizedMessage, preferredStyle: .Alert)
        
        let backToSafeSiteButtonTitle = NSLocalizedString("Back to safe site", tableName: "Cliqz", comment: "Back to safe site buttun title in antiphishing alert title")
        alert.addAction(UIAlertAction(title: backToSafeSiteButtonTitle, style: .Default, handler: { (action) in
            // go back
            self.goBack()
        }))
        
        let continueDespiteWarningButtonTitle = NSLocalizedString("Continue despite warning", tableName: "Cliqz", comment: "Continue despite warning buttun title in antiphishing alert title")
        alert.addAction(UIAlertAction(title: continueDespiteWarningButtonTitle, style: .Destructive, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }

}