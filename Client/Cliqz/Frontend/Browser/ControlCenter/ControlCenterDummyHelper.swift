//
//  ControlCenterDummyHelper.swift
//  Client
//
//  Created by Mahmoud Adam on 1/9/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class ControlCenterDummyHelper: NSObject {
    static private var adBlockerExceptions = [NSURL]()
    static private var antiTrackingExceptions = [NSURL]()
    
    
    class func isAdBlockerEnabledForURL(url: NSURL) -> Bool {
        return !adBlockerExceptions.contains(url)
    }
    
    class func toggleAdblockerForURL(url: NSURL){
        if let index = adBlockerExceptions.indexOf(url) {
            adBlockerExceptions.removeAtIndex(index)
        } else {
            adBlockerExceptions.append(url)
        }
    }
    
    
    class func isAntiTrakcingEnabledForURL(url: NSURL) -> Bool {
        return !antiTrackingExceptions.contains(url)
    }
    
    class func toggleAntiTrackingForURL(url: NSURL){
        if let index = antiTrackingExceptions.indexOf(url) {
            antiTrackingExceptions.removeAtIndex(index)
        } else {
            antiTrackingExceptions.append(url)
        }
    }
}
