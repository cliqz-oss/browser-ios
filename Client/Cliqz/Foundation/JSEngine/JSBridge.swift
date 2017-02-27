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
    private let semaphoresDispatchQueue = dispatch_queue_create("com.cliqz.jsbridge.sync", DISPATCH_QUEUE_CONCURRENT)
    let ACTION_TIMEOUT : Int64 = 200000000 // 200ms
    
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
        dispatch_sync(semaphoresDispatchQueue) {
            self.eventSemaphores[actionId] = sem
        }
        
//        print("Dispatch \(actionId)")
        // dispatch event
        self.sendEventWithName("callAction", body: ["id": actionId, "action": functionName, "args": args])
        
        // wait for the semaphore
        let timeout = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, self.ACTION_TIMEOUT))

        var reply : [String: NSObject] = [:]
        // after signal the reply should be ready in the cache
        dispatch_sync(semaphoresDispatchQueue) {
            if timeout != 0 {
                print("action timeout \(actionId), \(functionName)")
                self.replyCache[actionId] = ["error": "timeout"]
            }
            reply = self.replyCache[actionId]!
        
            // clear semaphore and reply cache
            self.replyCache[actionId] = nil
            self.eventSemaphores[actionId] = nil
        }
        
        return reply
    }
    
    public func publishEvent(eventName: String, args: AnyObject) {
        self.sendEventWithName("publishEvent", body: ["event": eventName, "args": args])
    }
    
    @objc(replyToAction:response:error:)
    func replyToAction(actionId: NSInteger, response: NSDictionary, error: String) {
//        print("Response \(actionId)")
        
        dispatch_async(semaphoresDispatchQueue) {
            // lookup the semaphore for this action
            if let sem = self.eventSemaphores[actionId] {
                // place response in cache and signal on this semaphore
                self.replyCache[actionId] = ["result": response, "error": error]
                dispatch_semaphore_signal(sem)
            } else {
                print("disgarding action reply \(actionId)")
            }
        }
    }
    
    @objc(registerAction:)
    func registerAction(actionName: String) {
        self.registeredActions.insert(actionName)
    }
    
}
