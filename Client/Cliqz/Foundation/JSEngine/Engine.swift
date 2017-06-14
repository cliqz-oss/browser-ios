//
//  Engine.swift
//  jsengine
//
//  Created by Sam Macbeth on 21/02/2017.
//  Copyright © 2017 Cliqz GmbH. All rights reserved.
//

import Foundation
import React

open class Engine {
    
    //MARK: - Singleton
    static let sharedInstance = Engine()
    
    let bridge : RCTBridge
    open let rootView : RCTRootView
    
    //MARK: - Init
    public init() {
        #if React_Debug
            let jsCodeLocation = URL(string: "http://localhost:8081/index.ios.bundle?platform=ios")
        #else
            let jsCodeLocation = Bundle.main.url(forResource: "jsengine.bundle", withExtension: "js")
        #endif
        
        rootView = RCTRootView( bundleURL: jsCodeLocation, moduleName: "ExtensionApp", initialProperties: nil, launchOptions: nil )
        bridge = rootView.bridge
        ConnectManager.sharedInstance.refresh()
    }
    
    open func getBridge() -> JSBridge {
        return bridge.module(for: JSBridge.self) as! JSBridge
    }
    
    open func getWebRequest() -> WebRequest {
        return bridge.module(for: WebRequest.self) as! WebRequest
    }
    
    //MARK: - Public APIs
    open func isRunning() -> Bool {
        return true
    }
    
    open func startup(_ defaultPrefs: [String: AnyObject]? = [String: AnyObject]()) {
        
    }
    
    open func shutdown(_ strict: Bool? = false) throws {
        
    }
    
    func setPref(_ prefName: String, prefValue: Any) {
        self.getBridge().callAction("core:setPref", args: [prefName, prefValue as! NSObject])
    }
    
    func getPref(_ prefName: String) -> Any {
        let result = self.getBridge().callAction("core:getPref", args: [prefName])
        return result["result"]
    }
    
    open func parseJSON(_ dictionary: [String: AnyObject]) -> String {
        if JSONSerialization.isValidJSONObject(dictionary) {
            do {
                let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
                let jsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                return jsonString
            } catch let error as NSError {
                DebugingLogger.log("<< Error while parsing the dictionary into JSON: \(error)")
            }
        }
        return "{}"
    }
    
    //MARK: - Connect
    func requestPairingData() {
        self.getBridge().callAction("mobile-pairing:requestPairingData", args: [])
    }
    
    func receiveQRValue(_ qrCode: String) {
        self.getBridge().callAction("mobile-pairing:receiveQRValue", args: [qrCode])
    }
    
    func unpairDevice(_ deviceId: String) {
        self.getBridge().callAction("mobile-pairing:unpairDevice", args: [deviceId])
    }
    
    func renameDevice(_ peerId: String, newName: String) {
        self.getBridge().callAction("mobile-pairing:renameDevice", args: [peerId, newName])
    }
}
