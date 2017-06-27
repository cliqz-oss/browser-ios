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
        
        CIReminderManager.sharedInstance.allValidReminders { (reminders) in
            
            var processed_array = reminders
            
            if !domain.isEqual(to: "All") {
                processed_array = reminders.filter({ (reminder) -> Bool in
                    if let url = URL(string: reminder.url)?.host {
                        return url.contains(processed_domain)
                    }
                    let condition = reminder.url.contains(processed_domain) //weakness: what if the processed_domain is passed as an argument in the url. - Solve...use the host
                    return condition
                })
            }
            
            let array = processed_array.map({ (reminder) -> [String:AnyObject] in
                return ["url": reminder.url as AnyObject, "title": reminder.title as AnyObject, "timestamp": Int(reminder.date.timeIntervalSince1970 * 1000000) as AnyObject]
            })
            
            resolve(array)
        }
        
        //resolve([["url": "" as AnyObject, "title": "First" as AnyObject, "timestamp": 1234564323456754 as AnyObject],["url": "" as AnyObject, "title": "Second" as AnyObject, "timestamp": 12345654323456 as AnyObject]])
        
    }
}
