//
//  UserAgentConstants.swift
//  Client
//
//  Created by Sam Macbeth on 10/10/2017.
//  Copyright © 2017 Cliqz GmbH. All rights reserved.
//

import Foundation
import React

@objc(UserAgentConstants)
open class UserAgentConstants : RCTEventEmitter {
    
    fileprivate var source: String {
        get {
            if AppStatus.sharedInstance.isDebug() {
                return "MI02" // Debug
            } else if AppStatus.sharedInstance.isRelease() {
                return "MI00" // Release
            } else {
                return "MI01" // TestFlight
            }
        }
    }
    
    fileprivate var appVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    
    open override static func moduleName() -> String! {
        return "UserAgentConstants"
    }
    
    override open func constantsToExport() -> [AnyHashable : Any]! { return ["channel": self.source, "appVersion": self.appVersion] }
    
}
