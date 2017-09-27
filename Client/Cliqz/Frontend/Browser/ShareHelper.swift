//
//  ShareHelper.swift
//  Client
//
//  Created by Tim Palade on 9/5/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class ShareHelper: NSObject {
    
    class func presentActivityViewController(/*_ url: URL, tab: Tab? = nil, sourceView: UIView?, sourceRect: CGRect, arrowDirection: UIPopoverArrowDirection*/) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        guard let tab = appDelegate.tabManager.selectedTab else {
            return
        }
        
        guard let url = tab.url else {
            return
        }
        
        var activities = [UIActivity]()
        
        // Cliqz: Added settings activity to sharing menu
//        let settingsActivity = SettingsActivity() {
//            //self.openSettings()
//            // Cliqz: log telemetry signal for share menu
//            TelemetryLogger.sharedInstance.logEvent(.ShareMenu("click", "settings"))
//        }
//        
//        activities.append(settingsActivity)
        
        let reminderActivity = ReminderActivity() {
            Router.shared.action(action: Action(data: nil, type: .remindersPressed))
        }
        
        activities.append(reminderActivity)
        
        // Cliqz: Added Activity for Youtube video downloader from sharing menu
//        if (YoutubeVideoDownloader.isYoutubeURL(url)) {
//            let youtubeDownloader = YoutubeVideoDownloaderActivity() {
//                TelemetryLogger.sharedInstance.logEvent(.YoutubeVideoDownloader("click", "target_type", "download_page"))
//                //self.downloadVideoFromURL(url.absoluteString, sourceRect: sourceRect)
//            }
//            activities.append(youtubeDownloader)
//        }
//        
        
        
//        let findInPageActivity = FindInPageActivity() { _ in
////            self.updateFindInPageVisibility(visible: true)
////            // Cliqz: log telemetry signal for share menu
//            TelemetryLogger.sharedInstance.logEvent(.ShareMenu("click", "search_page"))
//        }
//        activities.append(findInPageActivity)
        
        // Cliqz: disable Desktop/Mobile website option
        #if !CLIQZ
            if #available(iOS 9.0, *) {
                if let tab = tab, (tab.getHelper(ReaderMode.name()) as? ReaderMode)?.state != .Active {
                    let requestDesktopSiteActivity = RequestDesktopSiteActivity(requestMobileSite: tab.desktopSite) { [unowned tab] in
                        tab.toggleDesktopSite()
                    }
                    activities.append(requestDesktopSiteActivity)
                }
            }
        #endif
        
        let helper = ShareExtensionHelper(url: url, tab: tab, activities: activities)
        
        let controller = helper.createActivityViewController { (completed) in
            // After dismissing, check to see if there were any prompts we queued up
            //            self.showQueuedAlertIfAvailable()
            
            // Usually the popover delegate would handle nil'ing out the references we have to it
            // on the BVC when displaying as a popover but the delegate method doesn't seem to be
            // invoked on iOS 10. See Bug 1297768 for additional details.
            //            self.displayedPopoverController = nil
            //            self.updateDisplayedPopoverProperties = nil
            
            //if completed {
                // We don't know what share action the user has chosen so we simply always
                // update the toolbar and reader mode bar to reflect the latest status.
                //                if let tab = tab {
                //                    self.updateURLBarDisplayURL(tab)
                //                }
                //                self.updateReaderModeBar()
            //} else {
                // Cliqz: log telemetry signal for share menu
                //TelemetryLogger.sharedInstance.logEvent(.ShareMenu("click", "cancel"))
            //}
        }
        
        appDelegate.presentContollerOnTop(controller: controller)
        
    }
}
