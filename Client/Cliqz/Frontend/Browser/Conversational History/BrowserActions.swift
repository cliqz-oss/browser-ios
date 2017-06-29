//
//  ReactHomeViewController.swift
//  Client
//
//  Created by Sahakyan on 5/18/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import React

@objc(BrowserActions)
public class BrowserActions: NSObject {
	
	@objc(openLink:)
	public func openLink(url: NSString) {
		print("Hello React")
		if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let u = URL(string:url as String) {
			appDelegate.openUrlInWebView(url: u)
		}
	}
	
	@objc(queryCliqz:)
	public func queryCliqz(url: NSString) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.searchInWebView(text: (url as String))
        }
	}

	@objc(getOpenTabs:reject:)
	public func getOpenTabs(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
		let openTabs = NSMutableArray()
		if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
			for tab in appDelegate.tabManager.tabs {
                if let id = tab.webView?.uniqueId, let url = tab.url?.absoluteString {
                    let tabData = NSMutableDictionary()
                    tabData["id"] = NSInteger(id)
                    tabData["url"] = NSString(string: url)
                    tabData["title"] = NSString(string: tab.displayTitle)
                    openTabs.add(tabData)
                }
			}
		}
		resolve(openTabs)
	}

	@objc(openTab:)
	public func openTab(tabID: NSInteger) {
		if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
			appDelegate.openTab(tabID: tabID as Int)
		}
	}
    
    @objc(getReminders:resolve:reject:)
    public func getReminders(domain:NSString, resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock){
        
        let processed_domain = domain as String
        
        var reminders = CIReminderManager.sharedInstance.allValidReminders()
        
        if !domain.isEqual(to: "All") {
            reminders = reminders.filter({ (reminder) -> Bool in
                let url_str = reminder["url"] as! String
                
                if let host = URL(string: url_str)?.host {
                    return host.contains(processed_domain) //check if host contains the domain
                }
                
                let condition = url_str.contains(processed_domain) //weakness: what if the processed_domain is passed as an argument in the url. - Solve...use the host
                return condition
            })
        }
        
        resolve(reminders)
        
        //resolve([["url": "" as AnyObject, "title": "First" as AnyObject, "timestamp": 1234564323456754 as AnyObject],["url": "" as AnyObject, "title": "Second" as AnyObject, "timestamp": 12345654323456 as AnyObject]])
    }
}
