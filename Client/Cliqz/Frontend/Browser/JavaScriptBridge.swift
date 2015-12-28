//
//  JavaScriptBridge.swift
//  Client
//
//  Created by Mahmoud Adam on 12/23/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit
import Shared

@objc protocol JavaScriptBridgeDelegate: class {
    
    func didSelectUrl(url: NSURL)
    func evaluateJavaScript(javaScriptString: String)

    optional func searchForQuery(query: String)
    optional func getSearchHistoryResults(callback: String?)
}

class JavaScriptBridge {
    weak var delegate: JavaScriptBridgeDelegate?
    var profile: Profile
    
    init(profile: Profile) {
        self.profile = profile
    }
    
    func callJSMethod(methodName: String, parameter: AnyObject?) {
        var parameterString: String = ""
        
        if parameter != nil {
            do {
                if NSJSONSerialization.isValidJSONObject(parameter!) {
                    let json = try NSJSONSerialization.dataWithJSONObject(parameter!, options: NSJSONWritingOptions(rawValue: 0))
                    parameterString = String(data:json, encoding: NSUTF8StringEncoding)!
                } else {
                    print("couldn't convert object \(parameter!) to JSON because it is not valid JSON")
                }
            } catch let error as NSError {
                print("Json conversion is failed with error: \(error)")
            }
        }
        
        let javaScriptString = "\(methodName)(\(parameterString))"
        self.delegate?.evaluateJavaScript(javaScriptString)
    }
    
    
    func handleJSMessage(message: WKScriptMessage) {
        
        switch message.name {
        case "jsBridge":
            if let input = message.body as? NSDictionary {
                if let action = input["action"] as? String {
                    handleJSAction(action, data: input["data"], callback: input["callback"] as? String)
                }
            } else {
                DebugLogger.log("Unhandled JS Bridge message with name :\(message.name), and body: \(message.body) !!!")
            }
        default:
            DebugLogger.log("Unhandled JS message with name : \(message.name) !!!")
            
        }
    }
    
    // Mark: Handle JavaScript Action
    private func handleJSAction(action: String, data: AnyObject?, callback: String?) {
        switch action {
            
        case "openLink":
            if let url = data as? String {
                delegate?.didSelectUrl(NSURL(string: url)!)
            }
            
        case "notifyQuery":
            if let queryData = data as? [String: AnyObject],
                let query = queryData["q"] as? String {
                    delegate?.searchForQuery?(query)
            }
            
        case "getTopSites":
            if let limit = data as? Int {
                reloadTopSitesWithLimit(limit, callback: callback!)
            }
            
        case "searchHistory":
            delegate?.getSearchHistoryResults?(callback)
            
        case "browserAction":
            if let actionData = data as? [String: AnyObject], let actionType = actionData["type"] as? String {
                if actionType == "phoneNumber" {
                    self.callPhoneNumber(actionData["data"])
                }
            }
            
        case "pushTelemetry":
            if let telemetrySignal = data as? [String: AnyObject] {
                TelemetryLogger.sharedInstance.logEvent(.JavaScriptsignal(telemetrySignal))
            }
            
        case "copyResult":
            if let result = data as? String {
                UIPasteboard.generalPasteboard().string = result
            }
        default:
            print("Unhandles JS action: \(action), with data: \(data)")
        }
    }
    
    func reloadTopSitesWithLimit(limit: Int, callback: String) -> Success {
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
            self.callJSMethod(callback, parameter: results)
            return succeed()
        }
    }
    
    // Mark: Helper methods
    private func callPhoneNumber(data: AnyObject?) {
        if let phoneNumber = data as? String {
            let trimmedPhoneNumber = phoneNumber.removeWhitespaces()
            if let url = NSURL(string: "tel://\(trimmedPhoneNumber)") {
                UIApplication.sharedApplication().openURL(url)
            }
        }
    }
    
}
