//
//  Engine.swift
//  jsengine
//
//  Created by Sam Macbeth on 21/02/2017.
//  Copyright © 2017 Cliqz GmbH. All rights reserved.
//

import Foundation
import JavaScriptCore
import React

public class Engine {
    
    //MARK: - Singleton
    static let sharedInstance = Engine()
    
    let bridge : RCTBridge
    public let rootView : RCTRootView
    
    //MARK: - Init
    public init() {
        #if React_Debug
            let jsCodeLocation = NSURL(string: "http://localhost:8081/index.ios.bundle?platform=ios")
        #else
            let jsCodeLocation = NSBundle.mainBundle().URLForResource("jsengine.bundle", withExtension: "js")
        #endif
        
        rootView = RCTRootView( bundleURL: jsCodeLocation, moduleName: "ExtensionApp", initialProperties: nil, launchOptions: nil )
        bridge = rootView.bridge
    }
    
    public func getBridge() -> JSBridge {
        return bridge.moduleForClass(JSBridge) as! JSBridge
    }
    
    public func getWebRequest() -> WebRequest {
        return bridge.moduleForClass(WebRequest) as! WebRequest
    }
    
    //MARK: - Public APIs
    public func isRunning() -> Bool {
        return true
    }
    
    public func startup(defaultPrefs: [String: AnyObject]? = [String: AnyObject]()) {
        
    }
    
    public func shutdown(strict: Bool? = false) throws {
        
    }
    
    func setPref(prefName: String, prefValue: Any) {
        self.getBridge().callAction("setPref", args: [prefName, prefValue as! NSObject])
    }
    
    func getPref(prefName: String) -> Any {
        let result = self.getBridge().callAction("getPref", args: [prefName])
        return result["result"]
    }
    
    public func parseJSON(dictionary: [String: AnyObject]) -> String {
        if NSJSONSerialization.isValidJSONObject(dictionary) {
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(dictionary, options: [])
                let jsonString = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
                return jsonString
            } catch let error as NSError {
                DebugLogger.log("<< Error while parsing the dictionary into JSON: \(error)")
            }
        }
        return "{}"
    }
}
