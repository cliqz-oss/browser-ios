//
//  BrowserViewControllerExtension.swift
//  Client
//
//  Created by Sahakyan on 4/28/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

extension BrowserViewController {
	
	func loadInitialURL() {
		if let urlString = self.initialURL,
		   let url = NSURL(string: urlString) {
			self.navigateToURL(url)
		}
	}

    func askForNewsNotificationPermissionIfNeeded() {
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

	func invalidateCache() {
		let invalidateCacheKey = "invalidateCache"
		
		guard LocalDataStore.objectForKey(invalidateCacheKey) == nil else {
			return
		}
		let cacheClearable = CacheClearable(tabManager: tabManager)
		cacheClearable.clear()
		LocalDataStore.setObject(true, forKey: invalidateCacheKey)
	}
}