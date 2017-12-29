//
//  SubscriptionModule.swift
//  Client
//
//  Created by Tim Palade on 12/29/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import React

@objc(SubscriptionModule)
open class SubscriptionModule: RCTEventEmitter {

    @objc(isSubscribedBatch:resolve:reject:)
    func isSubscribedBatch(batch: NSArray, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        debugPrint("isSubscribedBatch")
    }
    
    @objc(isSubscribed:subType:identifier:resolve:reject:)
    func isSubscribed(type: NSString, subType: NSString, identifier: NSString, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        debugPrint("isSubscribed")
    }
    
    @objc(subscribeToNotifications:subType:identifier:resolve:reject:)
    func subscribeToNotifications(type: NSString, subType: NSString, identifier: NSString, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        debugPrint("subscribeToNotifications")
    }
    
    @objc(unsubscribeToNotifications:subType:identifier:resolve:reject:)
    func unsubscribeToNotifications(type: NSString, subType: NSString, identifier: NSString, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        debugPrint("unsubscribeToNotifications")
    }
    
}
