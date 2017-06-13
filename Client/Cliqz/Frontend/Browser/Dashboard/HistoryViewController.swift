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
    
    func didSelectURL(_ url: URL)
    func didSelectQuery(_ query: String)
}

class HistoryViewController: CliqzExtensionViewController {

    weak var delegate: HistoryDelegate?
	
	override init(profile: Profile) {
		super.init(profile: profile, viewType: "history")

		NotificationCenter.default.addObserver(self, selector: #selector(clearQueries as (Notification) -> Void), name: NSNotification.Name(rawValue: NotificationPrivateDataClearQueries), object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationPrivateDataClearQueries), object: nil)
    }
	
	override func mainRequestURL() -> String {
		return NavigationExtension.historyURL
	}
}


extension HistoryViewController {
    
    override func didSelectUrl(_ url: URL) {
		self.delegate?.didSelectURL(url)
    }

    func searchForQuery(_ query: String) {
		self.delegate?.didSelectQuery(query)
    }

    func getSearchHistory(_ offset:Int,limit:Int,callback: String?) {
		if let c = callback {
            self.profile.history.getHistoryVisits(offset, limit: limit).uponQueue(DispatchQueue.main) { result in
				if let sites = result.successValue {
					var historyResults = [[String: Any]]()
					for site in sites {
						var d = [String: Any]()
						d["id"] = site!.id
						d["url"] = site!.url
						d["title"] = site!.title
						d["timestamp"] = Double(site!.latestVisit!.date) / 1000.0
						historyResults.append(d)
					}
					self.javaScriptBridge.callJSMethod(c, parameter: historyResults, completionHandler: nil)
				}
			}
		}
	}

    override func isReady() {
        super.isReady()
    }

    // MARK: - Clear History
	@objc func clearQueries(notification notification: Notification) {
        let includeFavorites: Bool = (notification.object as? Bool) ?? false
		self.clearQueries(includeFavorites)
	}

	@objc func clearQueries(_ favorites: Bool) {
        //Cliqz: [IB-946][WORKAROUND] call `jsAPI` directly instead of publishing events because the event is executed when the history is opened next time not immediately
        //TODO: Queries will be stored in native side not in JavaScript
        if favorites == true {
//            self.javaScriptBridge.publishEvent("clear-favorites")
            self.javaScriptBridge.callJSMethod("jsAPI.clearFavorites()", parameter: nil, completionHandler: nil)
        } else {
//            self.javaScriptBridge.publishEvent("clear-history")
            self.javaScriptBridge.callJSMethod("jsAPI.clearHistory()", parameter: nil, completionHandler: nil)
        }
    }

}

