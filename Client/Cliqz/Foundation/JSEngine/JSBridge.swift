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

    public typealias Callback = ([String: NSObject]) -> Void
    
    var registeredActions: Set<String> = []
    var actionCounter: NSInteger = 0
    // cache for responses from js
    var replyCache = [NSInteger: [String: NSObject]]()
    // semaphores waiting for replies from js
    var eventSemaphores = [NSInteger: dispatch_semaphore_t]()
    // callbacks waiting for replies from js
    var eventCallbacks = [NSInteger: Callback]()
    // Dictionary of actions waiting for a function to be registered before executing
    var awaitingRegistration = [String: Array<(Array<AnyObject>, Callback)>]()
    
    // serial queue for access to eventSemaphores and eventCallbacks
    private let semaphoresDispatchQueue = dispatch_queue_create("com.cliqz.jsbridge.sync", DISPATCH_QUEUE_SERIAL)
    // serial queue for access to actionCounter
    private let lockDispatchQueue = dispatch_queue_create("com.cliqz.jsbridge.lock", DISPATCH_QUEUE_SERIAL)
    // dispatch queue for executing action callbacks
    private let callbackDispatchQueue = dispatch_queue_create("com.cliqz.jsbridge.callback", DISPATCH_QUEUE_CONCURRENT)
    
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
    
    private func nextActionId() -> NSInteger {
        var nextId : NSInteger = 0
        dispatch_sync(lockDispatchQueue) {
            self.actionCounter += 1
            nextId = self.actionCounter
        }
        return nextId
    }
    
    
    /// Call an action over the JSBridge and return the result synchronously.
    ///
    /// - parameter functionName: String name of the function to call
    /// - parameter args:         arguments to pass to the function
    ///
    /// - returns: A Dictionary with keys "error" and "result". If an error occured "error" will contain a string
    /// description of the type of error which occured. This may be:
    ///  * "function not registered": the function is not known to the bridge.
    ///  * "timeout": timeout occured waiting for the reply
    ///  * "exception when running action": javascript exception when running this action (see JS logs for details)
    ///  * "invalid action": action was not known on the Javascript side
    public func callAction(functionName: String, args: Array<AnyObject>) -> [String: NSObject] {
        // check listener is registered on other end
        guard self.registeredActions.contains(functionName) else {
            return ["error": "function not registered"]
        }
        
        // create unique id
        let actionId = nextActionId()
        
        // create a semaphore for this action
        let sem = dispatch_semaphore_create(0)
        dispatch_sync(semaphoresDispatchQueue) {
            self.eventSemaphores[actionId] = sem
        }
        
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
    
    /// Call an action over the JSBridge and execute a callback with the result. Invokation of the callback is
    /// not guaranteed, for example if the function is never registered. Unlike the synchronous version, this
    /// function does not return an error for unregistered functions, instead caching the args and re-triggering
    /// the action once registration occurs.
    ///
    /// - parameter functionName: String name of the function to call
    /// - parameter args:         arguments to pass to the function
    /// - parameter callback:     Callback to invoke with the result
    public func callAction(functionName: String, args: Array<AnyObject>, callback: Callback) {
        guard self.registeredActions.contains(functionName) else {
            dispatch_sync(lockDispatchQueue) {
                if self.awaitingRegistration[functionName] == nil {
                    self.awaitingRegistration[functionName] = []
                }
                self.awaitingRegistration[functionName]! += [(args, callback)]
            }
            return
        }
        
        let actionId = nextActionId()
        
        dispatch_sync(semaphoresDispatchQueue) {
            self.eventCallbacks[actionId] = callback
        }
        // only send event - callback is handled in action reply
        self.sendEventWithName("callAction", body: ["id": actionId, "action": functionName, "args": args])
        
    }
    
    /// Publish an event to Javascript over the JSBridge
    ///
    /// - parameter eventName: String name of event
    /// - parameter args:      Array args to pass with the event
    public func publishEvent(eventName: String, args: Array<AnyObject>) {
        self.sendEventWithName("publishEvent", body: ["event": eventName, "args": args])
    }
    
    @objc(replyToAction:response:error:)
    func replyToAction(actionId: NSInteger, response: NSObject, error: String) {
        let result = ["result": response, "error": error]
        dispatch_async(semaphoresDispatchQueue) {
            // we should find either a semaphore or a callback for this action
            if let sem = self.eventSemaphores[actionId] {
                // place response in cache and signal on this semaphore
                self.replyCache[actionId] = result
                dispatch_semaphore_signal(sem)
            } else if let callback = self.eventCallbacks[actionId] {
                dispatch_async(self.callbackDispatchQueue) {
                    callback(result)
                }
                self.eventCallbacks[actionId] = nil
            }
        }
    }
    
    @objc(registerAction:)
    func registerAction(actionName: String) {
        self.registeredActions.insert(actionName)
        
        // check for actions waiting to be executed
        dispatch_async(lockDispatchQueue) {
            if let queued = self.awaitingRegistration[actionName] {
                // trigger each waiting action
                queued.forEach { (args, callback) in
                    dispatch_async(self.callbackDispatchQueue, {
                        self.callAction(actionName, args: args, callback: callback)
                    })
                }
                self.awaitingRegistration[actionName] = []
            }
        }
    }
    
}
