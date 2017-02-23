//
//  JSBridge.swift
//  Client
//
//  Created by Sam Macbeth on 21/02/2017.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import React

@objc(JSBridge)
public class JSBridge : RCTEventEmitter {

    var registeredActions: Set<String> = []
    var actionCounter: NSInteger = 0
    var replyCache = [NSInteger: [String: NSObject]]()
    var eventSemaphores = [NSInteger: dispatch_semaphore_t]()
    
    public override init() {
        super.init()
    }
    
    public override static func moduleName() -> String! {
        return "JSBridge"
    }
    
    override public func supportedEvents() -> [String]! {
        return ["callAction", "publishEvent"]
    }
    
    public func callAction(functionName: String, args: AnyObject) -> [String: NSObject] {
        // check listener is registered on other end
        guard self.registeredActions.contains(functionName) else {
            return ["error": "function not registered"]
        }
        
        // create unique id
        actionCounter += 1
        let actionId = actionCounter
        
        // create a semaphore for this action
        let sem = dispatch_semaphore_create(0)
        self.eventSemaphores[actionId] = sem
        
        // dispatch event
        self.sendEventWithName("callAction", body: ["id": actionId, "action": functionName, "args": args])
        
        // wait for the semaphore
        let timeout = dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)

        // after signal the reply should be ready in the cache
        if timeout != 0 {
            print("action timeout \(actionId), \(functionName)")
            self.replyCache[actionId] = ["error": "timeout"]
        }
        let reply = self.replyCache[actionId]!
        
        // clear semaphore and reply cache
        self.replyCache[actionId] = nil
        self.eventSemaphores[actionId] = nil
        
        return reply
    }
    
    public func publishEvent(eventName: String, args: AnyObject) {
        self.sendEventWithName("publishEvent", body: ["event": eventName, "args": args])
    }
    
    @objc(replyToAction:response:error:)
    func replyToAction(actionId: NSInteger, response: NSDictionary, error: String) {
        // lookup the semaphore for this action
        if let sem = self.eventSemaphores[actionId] {
            // place response in cache and signal on this semaphore
            self.replyCache[actionId] = ["result": response, "error": error]
            dispatch_semaphore_signal(sem)
        } else {
            print("disgarding action reply \(actionId)")
        }
    }
    
    @objc(registerAction:)
    func registerAction(actionName: String) {
        self.registeredActions.insert(actionName)
    }
    
}
