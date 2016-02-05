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
@available(iOS 9.0, *)
extension AppDelegate {

    // identifier for the shortcuts
    var lastWebsiteIdentifier   : String { get { return "com.cliqz.LastWebsite" } }
    var topNewsIdentifier       : String { get { return "com.cliqz.TopNews"     } }
    var topSitesIdentifier      : String { get { return "com.cliqz.TopSites"    } }

    var topNewsURL              : String { get { return "https://newbeta.cliqz.com/api/v1/rich-header?path=/map&bmresult=rotated-top-news.cliqz.com"    } }
    
    
    // MARK:- configure Home actions
    // configure the dynamic shortcuts
    func configureHomeShortCuts() {
        var shortcutItems = [UIApplicationShortcutItem]()
        
        // last website shortcut
        let lastWebsiteTitle = NSLocalizedString("Last site", tableName: "Cliqz", comment: "Title for `Last site` home shortcut.")
        let lastWebsiteIcon =  UIApplicationShortcutIcon(templateImageName: "lastVisitedSite")
        let lastWebsiteShortcutItem = UIApplicationShortcutItem(type: lastWebsiteIdentifier, localizedTitle: lastWebsiteTitle, localizedSubtitle: nil, icon: lastWebsiteIcon, userInfo: nil)
        shortcutItems.append(lastWebsiteShortcutItem)
        
        // top news shortcut
        let topNewsTitle = NSLocalizedString("Top news", tableName: "Cliqz", comment: "Title for `Top news` home shortcut.")
        let topNewsIcon =  UIApplicationShortcutIcon(templateImageName: "topNews")
        let topNewsShortcutItem = UIApplicationShortcutItem(type: topNewsIdentifier, localizedTitle: topNewsTitle, localizedSubtitle: nil, icon: topNewsIcon, userInfo: nil)
        shortcutItems.append(topNewsShortcutItem)
        
        if self.profile!.history.count() > 0 {
            // add shortcuts for 2 top-sites
            appendTopSitesWithLimit(2, shortcutItems: shortcutItems)
        } else {
            // assign the applicaiton shortcut items
            UIApplication.sharedApplication().shortcutItems = shortcutItems
            
        }
    }
    
    // append top sites shortcuts to the application shortcut items
    private func appendTopSitesWithLimit(limit: Int, var shortcutItems: [UIApplicationShortcutItem]) -> Success {
        let topSitesIcon =  UIApplicationShortcutIcon(templateImageName: "topSites")

        return self.profile!.history.getTopSitesWithLimit(limit).bindQueue(dispatch_get_main_queue()) { result in
            if let r = result.successValue {
                for site in r {
                    // top news shortcut
                    if let url = site?.url,
                        let domainURL = self.extractDomainUrl(url),
                        let domainName = self.extractDomainName(url) {
                            let userInfo = ["url" : domainURL]
                            let topSiteShortcutItem = UIApplicationShortcutItem(type: self.topSitesIdentifier, localizedTitle: domainName, localizedSubtitle: nil, icon: topSitesIcon, userInfo: userInfo)
                            shortcutItems.append(topSiteShortcutItem)
                    }
                }
            }
            
            // assign the applicaiton shortcut items
            UIApplication.sharedApplication().shortcutItems = shortcutItems
            return succeed()
        }
    }
    
    // getting the domain name of the url to be used as title for the shortcut
    private func extractDomainName(urlString: String) -> String? {
        if let url = NSURL(string: urlString),
            let domain = url.host {
                return domain.replace("www.", replacement: "")
        }
        return nil
    }
    
    // get the domain url of the top site url to navigate to when user selects this quick action
    private func extractDomainUrl(urlString: String) -> String? {
        if let url = NSURL(string: urlString),
            let domain = url.host {
                return "http://\(domain)"
        }
        return nil
    }
    
    // MARK:- Handle Home actions
    // Handeling user action when opening the app from home quick action
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        
        var delay = 0.0
        if application.applicationState == .Inactive {
            // if the app is inactive we add delay to be sure that UI is ready to handel the action
            delay = 0.5 * Double(NSEC_PER_SEC)
        }
        
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), {
            completionHandler(self.handleShortcut(shortcutItem))
        })
    }
    
    // handel shortcut action
    private func handleShortcut(shortcutItem:UIApplicationShortcutItem) -> Bool {
        let index = UIApplication.sharedApplication().shortcutItems?.indexOf(shortcutItem)
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
            if let url = shortcutItem.userInfo?["url"] as? String,
                let topSiteURL = NSURL(string: url) {
                    browserViewController.navigateToURL(topSiteURL)
                    TelemetryLogger.sharedInstance.logEvent(.HomeScreenShortcut("top_site", index!))
                succeeded = true
            }
        } else {
            let eventAttributes = ["title" : shortcutItem.localizedTitle, "type" : shortcutItem.type]
            Answers.logCustomEventWithName("UnhandledHomeScreenAction", customAttributes: eventAttributes)
        }
        
        return succeeded
    }
    
    private func navigateToRandomTopNews() {
        ConnectionManager.sharedInstance.sendGetRequest(topNewsURL, parameters: nil,
            onSuccess: { json in
                let jsonDict = json as! [String : AnyObject]
                let results = jsonDict["results"] as! [[String : AnyObject]]
                let articles = results[0]["articles"] as! [AnyObject]
                let randomIndex = Int(arc4random_uniform(UInt32(articles.count)))
                let randomArticle  = articles[randomIndex] as! [String : AnyObject]
                let urlString = randomArticle["url"] as! String
                let randomURl = NSURL(string: urlString)
                self.browserViewController.navigateToURL(randomURl!)
            },
            onFailure: { (data, error) in
                let eventAttributes = ["url" : self.topNewsURL, "error" : "\(error)"]
                Answers.logCustomEventWithName("TopNewsError", customAttributes: eventAttributes)
        })

    }
}
