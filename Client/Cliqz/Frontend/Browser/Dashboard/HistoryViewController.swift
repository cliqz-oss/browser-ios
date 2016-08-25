//
//  SearchHistoryViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 11/25/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import UIKit
import Shared

protocol HistoryDelegate: class {
    
    func didSelectURL(url: NSURL)
    func didSelectQuery(query: String)
}

class HistoryViewController: CliqzExtensionViewController {

    weak var delegate: HistoryDelegate?
    let QueryLimit = 100
	
	override init(profile: Profile) {
		super.init(profile: profile)

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(clearQueries as (NSNotification) -> Void), name: NotificationPrivateDataClearQueries, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationPrivateDataClearQueries, object: nil)
    }
	
	override func mainRequestURL() -> String {
		return NavigationExtension.historyURL
	}
}


extension HistoryViewController {
    
    override func didSelectUrl(url: NSURL) {
		self.delegate?.didSelectURL(url)
    }

    func searchForQuery(query: String) {
		self.delegate?.didSelectQuery(query)
    }

	func getSearchHistory(callback: String?) {
		if let c = callback {
			self.profile.history.getHistoryVisits(QueryLimit).uponQueue(dispatch_get_main_queue()) { result in
				if let sites = result.successValue {
					var historyResults = [[String: AnyObject]]()
					for site in sites {
						var d = [String: AnyObject]()
						d["id"] = site!.id
						d["url"] = site!.url
						d["title"] = site!.title
						d["timestamp"] = Double(site!.latestVisit!.date) / 1000.0
						historyResults.append(d)
					}
					self.javaScriptBridge.callJSMethod(c, parameter: historyResults.reverse(), completionHandler: nil)
				}
			}
		}
	}

    override func isReady() {
        super.isReady()
        
        guard NSUserDefaults.standardUserDefaults().boolForKey(IsAppTerminated) ?? false else {
            return
        }
        guard let profile = self.profile where (profile.prefs.boolForKey(ClearDataOnTerminatingPrefKey) ?? false) == true && profile.historyTypeShouldBeCleared() != .None else {
            return
        }
        clearQueries(includeFavorites: profile.historyTypeShouldBeCleared() == .All)
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: IsAppTerminated)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    // MARK: - Clear History
	@objc func clearQueries(notification: NSNotification) {
        let includeFavorites: Bool = (notification.object as? Bool) ?? false
		self.clearQueries(includeFavorites: includeFavorites)
	}

	func clearQueries(includeFavorites includeFavorites: Bool) {
        if includeFavorites == true {
            self.evaluateJavaScript("jsAPI.clearFavorites()", completionHandler: nil)
        } else {
            self.evaluateJavaScript("jsAPI.clearHistory()", completionHandler: nil)
        }
    }

}

