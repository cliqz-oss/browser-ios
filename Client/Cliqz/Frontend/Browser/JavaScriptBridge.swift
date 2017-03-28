//
//  JavaScriptBridge.swift
//  Client
//
//  Created by Mahmoud Adam on 12/23/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit
import Shared
import Crashlytics
import WebKit
import Storage

@objc protocol JavaScriptBridgeDelegate: class {
    
    func didSelectUrl(url: NSURL)
    func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?)

    optional func searchForQuery(query: String)

	optional func getFavorites(callback: String?)
	optional func getSearchHistory(offset:Int,limit:Int,callback: String?)
    optional func getSearchHistoryResults(callback: String?)
    optional func shareCard(cardURL: String)
    optional func autoCompeleteQuery(autoCompleteText: String)
    optional func isReady()
}

class JavaScriptBridge {
    weak var delegate: JavaScriptBridgeDelegate?
    var profile: Profile
    private let maxFrecencyLimit: Int = 30
    private let backgorundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

    init(profile: Profile) {
        self.profile = profile
        dispatch_async(backgorundQueue) {
            self.profile.history.setTopSitesCacheSize(Int32(self.maxFrecencyLimit))
        }
    }
    
    func publishEvent(eventName: String, parameters: AnyObject? = nil) {
        var evalScript = "CliqzEvents.pub('mobile-browser:\(eventName)'"
        if let serializedParameters =  serializeParameters(parameters) {
            evalScript += ",\(serializedParameters)"
        }
        evalScript += ")"
        
        self.delegate?.evaluateJavaScript(evalScript, completionHandler: nil)
    }
    
    func callJSMethod(methodName: String, parameter: AnyObject?, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        var parameterString: String = ""
        
        if let parameter = parameter {
            do {
                if NSJSONSerialization.isValidJSONObject(parameter) {
                    let json = try NSJSONSerialization.dataWithJSONObject(parameter, options: NSJSONWritingOptions(rawValue: 0))
                    parameterString = String(data:json, encoding: NSUTF8StringEncoding)!
                } else {
                    print("couldn't convert object \(parameter) to JSON because it is not valid JSON")
                }
            } catch let error as NSError {
                print("Json conversion is failed with error: \(error)")
            }
        }
        
        let javaScriptString = "\(methodName)(\(parameterString))"
        self.delegate?.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
    
    func handleJSMessage(message: WKScriptMessage) {
        
        switch message.name {
        case "jsBridge":
            if let input = message.body as? NSDictionary {
                if let action = input["action"] as? String {
                    handleJSAction(action, data: input["data"], callback: input["callback"] as? String)
                }
            } else {
                DebugingLogger.log("Unhandled JS Bridge message with name :\(message.name), and body: \(message.body) !!!")
            }
        default:
            DebugingLogger.log("Unhandled JS message with name : \(message.name) !!!")
            
        }
    }

	func setDefaultSearchEngine() {
        
        dispatch_async(backgorundQueue) {
            
            let searchComps = self.profile.searchEngines.defaultEngine.searchURLForQuery("queryString")?.absoluteString!.componentsSeparatedByString("=queryString")
            let searchEngineName = self.profile.searchEngines.defaultEngine.shortName
            let parameters = "'\(searchEngineName)', `\(searchComps![0])=`"
            
            dispatch_async(dispatch_get_main_queue()) {
                self.publishEvent("set-search-engine", parameters: parameters)
            }
        }
		
	}
    
    // Mark:- Private Helper Methods
    private func serializeParameters(parameters: AnyObject? = nil) -> String? {
        if let parameters = parameters as? String {
            return parameters
        } else if let parameters = parameters as? [String: AnyObject] {
            do {
                if NSJSONSerialization.isValidJSONObject(parameters) {
                    let json = try NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions(rawValue: 0))
                    return String(data:json, encoding: NSUTF8StringEncoding)!
                } else {
                    print("couldn't convert object \(parameters) to JSON because it is not valid JSON")
                }
            } catch let error as NSError {
                print("Json conversion is failed with error: \(error)")
            }
        }
        
        return nil
    }
    
    private func handleJSAction(action: String, data: AnyObject?, callback: String?) {
        switch action {
            
        case "openLink":
            if let urlString = data as? String {
                if let url = NSURL(string: urlString) {
                    delegate?.didSelectUrl(url)
                } else if let url = NSURL(string: urlString.escapeURL()) {
                    delegate?.didSelectUrl(url)
                }
            }
            
        case "notifyQuery":
            if let queryData = data as? [String: AnyObject],
                let query = queryData["q"] as? String {
                    delegate?.searchForQuery?(query)
            }
            
        case "getTopSites":
            if let limit = data as? Int {
                refreshTopSites(limit, callback: callback!)
            }
            
        case "searchHistory":
            delegate?.getSearchHistoryResults?(callback)
			
		case "getHistoryItems":
            if let actionData = data as? [String: AnyObject],let limit = actionData["limit"] as? Int,let offset = actionData["offset"] as? Int{
                delegate?.getSearchHistory?(offset,limit:limit,callback: callback)
            }
            
		case "getFavorites":
			delegate?.getFavorites?(callback)
			
        case "browserAction":
            if let actionData = data as? [String: AnyObject], let actionType = actionData["type"] as? String {
                if let phoneNumber = actionData["data"] as? String where actionType == "phoneNumber" {
                    self.callPhoneNumber(phoneNumber)
                } else if let mapURL = actionData["data"] as? String where actionType == "map" {
                    self.openGoogleMaps(mapURL)
                }
            }
            
        case "pushTelemetry":
            if let telemetrySignal = data as? [String: AnyObject] {
                if NSJSONSerialization.isValidJSONObject(telemetrySignal) {
                    TelemetryLogger.sharedInstance.logEvent(.JavaScriptSignal(telemetrySignal))
                } else {
                    var customAttributes = [String: AnyObject]()
                    
                    if let action = telemetrySignal["action"],
                        let type = telemetrySignal["type"] {
                            customAttributes = ["acion": action,"type": type]
                    }
                    Answers.logCustomEventWithName("InvalidJavaScriptTelemetrySignal", customAttributes: customAttributes)
                }
            }
            
        case "copyResult":
            if let result = data as? String {
                UIPasteboard.generalPasteboard().string = result
            }
            
        case "shareCard":
            if let cardURL = data as? String {
                delegate?.shareCard?(cardURL)
            }
            
        case "autocomplete":
            if let autoCompleteText = data as? String {
                delegate?.autoCompeleteQuery?(autoCompleteText)
            }
            
        case "setFavorites":
			setFavorites(data)
			
        case "removeHistoryItems":
            if let ids = data as? [Int] {
                self.profile.history.removeHistory(ids)
            }
        
        case "isReady":
            delegate?.isReady?()
        
        case "shareLocation":
            LocationManager.sharedInstance.shareLocation()
            
        default:
			print("Unhandles JS action")
        }
    }
    
    // Mark: Helper methods
	
	private func setFavorites(data: AnyObject?) {
		if let bookmarkedData = data as? [String: AnyObject],
			let favorites = bookmarkedData["favorites"] as? [[String: AnyObject]],
			let value = bookmarkedData["value"] as? Bool {
			for item in favorites {
				let url = item["url"] as? String
				let title = item["title"] as? String
				let timestamp = item["timestamp"] as? NSNumber
				if (value) {
					addURLToBookmarks(url, title: title, bookmarkedDate: timestamp)
				} else {
					removeURLFromBookmarks(url)
				}
			}
		}
	}

	private func addURLToBookmarks(url: String?, title: String?, bookmarkedDate: NSNumber?) {
		if let u = url, t = title, d = bookmarkedDate {
			self.profile.bookmarks.modelFactory >>== {
				$0.isBookmarked(u).uponQueue(dispatch_get_main_queue()) { result in
					guard let bookmarked = result.successValue else {
						return
					}
					if !bookmarked {
						let shareItem = CliqzShareItem(url: u, title: t, favicon: nil, bookmarkedDate: d.unsignedLongLongValue)
						self.profile.bookmarks.shareItem(shareItem)
						NSNotificationCenter.defaultCenter().postNotificationName(BookmarkStatusChangedNotification, object: u, userInfo:["added": true])
					}
				}
			}
		}
	}

	private func removeURLFromBookmarks(url: String?) {
		if let u = url {
			profile.bookmarks.modelFactory >>== {
				$0.removeByURL(u)
			}
			NSNotificationCenter.defaultCenter().postNotificationName(BookmarkStatusChangedNotification, object: u, userInfo:["added": false])
		}
	}

    private func refreshTopSites(frecencyLimit: Int, callback: String) {
        // Reload right away with whatever is in the cache, then check to see if the cache is invalid. If it's invalid,
        // invalidate the cache and requery. This allows us to always show results right away if they are cached but
        // also load in the up-to-date results asynchronously if needed
        reloadTopSitesWithLimit(frecencyLimit, callback: callback) >>> {
            return self.profile.history.updateTopSitesCacheIfInvalidated() >>== { result in
                return result ? self.reloadTopSitesWithLimit(frecencyLimit, callback: callback) : succeed()
            }
        }
    }
    
    private func reloadTopSitesWithLimit(limit: Int, callback: String) -> Success {
        return self.profile.history.getTopSitesWithLimit(limit).bindQueue(dispatch_get_main_queue()) { result in
            var results = [[String: String]]()
            if let r = result.successValue {
                for site in r {
                    var d = Dictionary<String, String>()
                    d["url"] = site!.url
                    d["title"] = site!.title
                    results.append(d)
                }
            }
            self.callJSMethod(callback, parameter: results, completionHandler: nil)
            return succeed()
        }
	}

    private func callPhoneNumber(phoneNumber: String) {
        let trimmedPhoneNumber = phoneNumber.removeWhitespaces()
        if let url = NSURL(string: "tel://\(trimmedPhoneNumber)") {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    private func openGoogleMaps(url: String) {
        if let mapURL = NSURL(string:url) {
            delegate?.didSelectUrl(mapURL)
        }
	}

}
