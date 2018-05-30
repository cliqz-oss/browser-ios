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

}