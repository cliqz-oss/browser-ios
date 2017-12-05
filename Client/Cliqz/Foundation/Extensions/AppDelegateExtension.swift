//
//  AppDelegateExtension.swift
//  Client
//
//  Created by Mahmoud Adam on 2/2/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit
import Shared
import Crashlytics


// Cliqz: handel home screen quick actions
extension AppDelegate {

    // identifier for the shortcuts
    var lastWebsiteIdentifier   : String { get { return "com.cliqz.LastWebsite" } }
    var topNewsIdentifier       : String { get { return "com.cliqz.TopNews"     } }
    var topSitesIdentifier      : String { get { return "com.cliqz.TopSites"    } }

    var topNewsURL              : String { get { return "https://newbeta.cliqz.com/api/v2/rich-header?path=/map&bmresult=rotated-top-news.cliqz.com&locale=\(Locale.current.identifier)"    } }
	
	// MARK:- Delegate methods
	// Handeling user action when opening the app from home quick action
	@available(iOS 9.0, *)
	func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		
        completionHandler(self.handleShortcut(shortcutItem))
	}
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		if let notificationData = (userInfo["aps"] as? NSDictionary),
			let urlString = (notificationData.value(forKey: "url") as? String) {
			self.browserViewController.initialURL = urlString
		}
		completionHandler(.noData)
	}

    // MARK:- Public API
    // configure the dynamic shortcuts
//    @available(iOS 9.0, *)
//    func configureHomeShortCuts() {
//        var shortcutItems = [UIApplicationShortcutItem]()
//        
//        // last website shortcut
//        let lastWebsiteTitle = NSLocalizedString("Last site", tableName: "Cliqz", comment: "Title for `Last site` home shortcut.")
//        let lastWebsiteIcon =  UIApplicationShortcutIcon(templateImageName: "lastVisitedSite")
//        let lastWebsiteShortcutItem = UIApplicationShortcutItem(type: lastWebsiteIdentifier, localizedTitle: lastWebsiteTitle, localizedSubtitle: nil, icon: lastWebsiteIcon, userInfo: nil)
//        shortcutItems.append(lastWebsiteShortcutItem)
//        
//        // top news shortcut
//        let topNewsTitle = NSLocalizedString("Top news", tableName: "Cliqz", comment: "Title for `Top news` home shortcut.")
//        let topNewsIcon =  UIApplicationShortcutIcon(templateImageName: "topNews")
//        let topNewsShortcutItem = UIApplicationShortcutItem(type: topNewsIdentifier, localizedTitle: topNewsTitle, localizedSubtitle: nil, icon: topNewsIcon, userInfo: nil)
//        shortcutItems.append(topNewsShortcutItem)
//        
//        if self.profile!.history.count() > 0 {
//            // add shortcuts for 2 top-sites
//            appendTopSitesWithLimit(2, shortcutItems: shortcutItems)
//        } else {
//            // assign the applicaiton shortcut items
//            UIApplication.shared.shortcutItems = shortcutItems
//            
//        }
//    }
    // Cliqz: Change the status bar style and color
    static func changeStatusBarStyle(_ statusBarStyle: UIStatusBarStyle, backgroundColor: UIColor) {
        UIApplication.shared.setStatusBarStyle(statusBarStyle, animated: false)
		UIApplication.shared.delegate?.window??.backgroundColor = backgroundColor
	}

    // getting the domain name of the url to be used as title for the shortcut
    fileprivate func extractDomainName(_ urlString: String) -> String? {
        if let url = URL(string: urlString),
            let domain = url.host {
                return domain.replace("www.", replacement: "")
        }
        return nil
    }
    
    // get the domain url of the top site url to navigate to when user selects this quick action
    fileprivate func extractDomainUrl(_ urlString: String) -> String? {
        if let url = URL(string: urlString),
            let domain = url.host {
                return "http://\(domain)"
        }
        return nil
    }

    // handel shortcut action
	@available(iOS 9.0, *)
    fileprivate func handleShortcut(_ shortcutItem:UIApplicationShortcutItem) -> Bool {
        let index = UIApplication.shared.shortcutItems?.index(of: shortcutItem)
        var succeeded = false
        
        if shortcutItem.type == lastWebsiteIdentifier {
            // open last website
            browserViewController.navigateToLastWebsite()
            TelemetryLogger.sharedInstance.logEvent(.HomeScreenShortcut("last_site", index!))
            succeeded = true
        } else if shortcutItem.type == topNewsIdentifier {
            // open random top news
            navigateToRandomTopNews()
            TelemetryLogger.sharedInstance.logEvent(.HomeScreenShortcut("top_news", index!))
            succeeded = true
        } else if shortcutItem.type == topSitesIdentifier {
            if let topSiteURL = shortcutItem.userInfo?["url"] as? String {
                browserViewController.initialURL = topSiteURL
                TelemetryLogger.sharedInstance.logEvent(.HomeScreenShortcut("top_site", index!))
                succeeded = true
            }
        } else {
            let eventAttributes = ["title" : shortcutItem.localizedTitle, "type" : shortcutItem.type]
            Answers.logCustomEvent(withName: "UnhandledHomeScreenAction", customAttributes: eventAttributes)
        }
        
        return succeeded
    }
    
    fileprivate func navigateToRandomTopNews() {
        ConnectionManager.sharedInstance.sendRequest(.get, url: topNewsURL, parameters: nil, responseType: .jsonResponse, queue: DispatchQueue.main,
            onSuccess: { json in
                let jsonDict = json as! [String : AnyObject]
                let results = jsonDict["results"] as! [[String : AnyObject]]
                let articles = results[0]["articles"] as! [AnyObject]
                let randomIndex = Int(arc4random_uniform(UInt32(articles.count)))
                let randomArticle  = articles[randomIndex] as! [String : AnyObject]
                let randomURl = randomArticle["url"] as! String
                self.browserViewController.initialURL = randomURl
                self.browserViewController.loadInitialURL()
            },
            onFailure: { (data, error) in
                let eventAttributes = ["url" : self.topNewsURL, "error" : "\(error)"]
                Answers.logCustomEvent(withName: "TopNewsError", customAttributes: eventAttributes)
        })

    }

}
