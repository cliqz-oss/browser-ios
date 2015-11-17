//
//  LocalDataStore.swift
//  Client
//
//  Created by Mahmoud Adam on 11/9/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

class LocalDataStore {
    static let defaults = NSUserDefaults.standardUserDefaults()
    // wrtiting operation is done on Main thread because of a bug in FireFox that it is changing UI when any change is done to user defaults
    static let dispatchQueue = dispatch_get_main_queue()

    class func setObject(value: AnyObject?, forKey: String) {
        dispatch_async(dispatchQueue) {
            defaults.setObject(value, forKey: forKey)
            defaults.synchronize()
        }
    }
    
    class func objectForKey(key: String) -> AnyObject? {
        return defaults.objectForKey(key)
    }
    
    class func removeObjectForKey(key: String) {
        dispatch_async(dispatchQueue) {
            defaults.removeObjectForKey(key)
            defaults.synchronize()
        }
    }
}
