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
    
    func didSelectUrl(_ url: URL)
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?)

    @objc optional func searchForQuery(_ query: String)

	@objc optional func getFavorites(_ callback: String?)
	@objc optional func getSearchHistory(_ offset:Int,limit:Int,callback: String?)
	@objc optional func getSearchHistoryResults(_ query: String?, _ callback: String?)
    @objc optional func shareCard(_ cardURL: String)
    @objc optional func autoCompeleteQuery(_ autoCompleteText: String)
    @objc optional func isReady()
}

class JavaScriptBridge {
    weak var delegate: JavaScriptBridgeDelegate?
    var profile: Profile
    fileprivate let maxFrecencyLimit: Int = 30
    fileprivate let backgorundQueue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)

    init(profile: Profile) {
        self.profile = profile
        (backgorundQueue).async {
            self.profile.history.setTopSitesCacheSize(Int32(self.maxFrecencyLimit))
        }
    }
    
    func publishEvent(_ eventName: String, parameters: Any? = nil) {
        var evalScript = "CliqzEvents.pub('mobile-browser:\(eventName)'"
        if let serializedParameters =  serializeParameters(parameters) {
            evalScript += ",\(serializedParameters)"
        }
        evalScript += ")"
        
        self.delegate?.evaluateJavaScript(evalScript, completionHandler: nil)
    }
    
    func callJSMethod(_ methodName: String, parameter: Any?, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        var parameterString: String = ""
        
        if let parameter = parameter {
            do {
                if JSONSerialization.isValidJSONObject(parameter) {
                    let json = try JSONSerialization.data(withJSONObject: parameter, options: JSONSerialization.WritingOptions(rawValue: 0))
                    parameterString = String(data:json, encoding: String.Encoding.utf8)!
                } else {
					parameterString = "[]"
                    debugPrint("couldn't convert object \(parameter) to JSON because it is not valid JSON")
                }
            } catch let error as NSError {
				parameterString = "[]"
                debugPrint("Json conversion is failed with error: \(error)")
            }
        }
        
        let javaScriptString = "\(methodName)(\(parameterString))"
        self.delegate?.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
    
    func handleJSMessage(_ message: WKScriptMessage) {
        
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
        
        backgorundQueue.async {
            
            let searchComps = self.profile.searchEngines.defaultEngine.searchURLForQuery("queryString")?.absoluteString.components(separatedBy: "=queryString")
            let searchEngineName = self.profile.searchEngines.defaultEngine.shortName
            let parameters = "'\(searchEngineName)', `\(searchComps![0])=`"
            
            DispatchQueue.main.async {
                self.publishEvent("set-search-engine", parameters: parameters)
            }
        }
		
	}
    
    // Mark:- Private Helper Methods
    fileprivate func serializeParameters(_ parameters: Any? = nil) -> String? {
        if let parameters = parameters as? String {
            return parameters
        } else if let parameters = parameters as? [String: AnyObject] {
            do {
                if JSONSerialization.isValidJSONObject(parameters) {
                    let json = try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions(rawValue: 0))
                    return String(data:json, encoding: String.Encoding.utf8)!
                } else {
                    debugPrint("couldn't convert object \(parameters) to JSON because it is not valid JSON")
                }
            } catch let error as NSError {
                debugPrint("Json conversion is failed with error: \(error)")
            }
        }
        
        return nil
    }
    
    fileprivate func handleJSAction(_ action: String, data: Any?, callback: String?) {
        switch action {
            
        case "openLink":
            if let urlString = data as? String {
                if let url = URL(string: urlString) {
                    delegate?.didSelectUrl(url)
                } else if let url = URL(string: urlString.escapeURL()) {
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
			delegate?.getSearchHistoryResults?(data as? String, callback)
			
		case "getHistoryItems":
            if let actionData = data as? [String: AnyObject],let limit = actionData["limit"] as? Int,let offset = actionData["offset"] as? Int{
                delegate?.getSearchHistory?(offset,limit:limit,callback: callback)
            }
            
		case "getFavorites":
			delegate?.getFavorites?(callback)
			
        case "browserAction":
            if let actionData = data as? [String: AnyObject], let actionType = actionData["type"] as? String {
                if let phoneNumber = actionData["data"] as? String, actionType == "phoneNumber" {
                    self.callPhoneNumber(phoneNumber)
                } else if let mapURL = actionData["data"] as? String, actionType == "map" {
                    self.openGoogleMaps(mapURL)
                }
            }
            
        case "pushTelemetry":
            if let telemetrySignal = data as? [String: AnyObject] {
                if JSONSerialization.isValidJSONObject(telemetrySignal) {
                    TelemetryLogger.sharedInstance.logEvent(.JavaScriptSignal(telemetrySignal))
                } else {
                    var customAttributes = [String: AnyObject]()
                    
                    if let action = telemetrySignal["action"],
                        let type = telemetrySignal["type"] {
                            customAttributes = ["acion": action,"type": type]
                    }
                    Answers.logCustomEvent(withName: "InvalidJavaScriptTelemetrySignal", customAttributes: customAttributes)
                }
            }
            
        case "copyResult":
            if let result = data as? String {
                UIPasteboard.general.string = result
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
            
        case "showQuerySuggestions":
            if let suggestionsData = data as? [String: AnyObject] {
                NotificationCenter.default.post(name: QuerySuggestions.ShowSuggestionsNotification, object: suggestionsData)
            }
        default:
			debugPrint("Unhandles JS action")
        }
    }
    
    // Mark: Helper methods
	
	fileprivate func setFavorites(_ data: Any?) {
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

	fileprivate func addURLToBookmarks(_ url: String?, title: String?, bookmarkedDate: NSNumber?) {
		if let u = url, let t = title, let d = bookmarkedDate {
			self.profile.bookmarks.modelFactory >>== {
				$0.isBookmarked(u).uponQueue(DispatchQueue.main) { result in
					guard let bookmarked = result.successValue else {
						return
					}
					if !bookmarked {
						let shareItem = CliqzShareItem(url: u, title: t, favicon: nil, bookmarkedDate: d.uint64Value)
						self.profile.bookmarks.shareItem(shareItem)
						NotificationCenter.default.post(name: Notification.Name(rawValue: BookmarkStatusChangedNotification), object: u, userInfo:["added": true])
					}
				}
			}
		}
	}

	fileprivate func removeURLFromBookmarks(_ url: String?) {
		if let u = url {
			profile.bookmarks.modelFactory >>== {
				$0.removeByURL(u)
			}
			NotificationCenter.default.post(name: Notification.Name(rawValue: BookmarkStatusChangedNotification), object: u, userInfo:["added": false])
		}
	}

    fileprivate func refreshTopSites(_ frecencyLimit: Int, callback: String) {
        // Reload right away with whatever is in the cache, then check to see if the cache is invalid. If it's invalid,
        // invalidate the cache and requery. This allows us to always show results right away if they are cached but
        // also load in the up-to-date results asynchronously if needed
        reloadTopSitesWithLimit(frecencyLimit, callback: callback) >>> {
            return self.profile.history.updateTopSitesCacheIfInvalidated() >>== { result in
                return result ? self.reloadTopSitesWithLimit(frecencyLimit, callback: callback) : succeed()
            }
        }
    }
    
    fileprivate func reloadTopSitesWithLimit(_ limit: Int, callback: String) -> Success {
        return self.profile.history.getTopSitesWithLimit(limit).bindQueue(DispatchQueue.main) { result in
            var results = [[String: String]]()
            if let r = result.successValue {
                for site in r {
                    var d = Dictionary<String, String>()
                    d["url"] = site!.url
                    d["title"] = site!.title
                    results.append(d)
                }
            }
            self.callJSMethod(callback, parameter: results as AnyObject, completionHandler: nil)
            return succeed()
        }
	}

    fileprivate func callPhoneNumber(_ phoneNumber: String) {
        let trimmedPhoneNumber = phoneNumber.removeWhitespaces()
        if let url = URL(string: "tel://\(trimmedPhoneNumber)") {
            UIApplication.shared.openURL(url)
        }
    }

    fileprivate func openGoogleMaps(_ url: String) {
        if let mapURL = URL(string:url) {
            delegate?.didSelectUrl(mapURL)
        }
	}

}
