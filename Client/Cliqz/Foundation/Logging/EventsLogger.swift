//
//  EventsLogger.swift
//  Client
//
//  Created by Mahmoud Adam on 11/4/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation
import Crashlytics

class EventsLogger: NSObject {
    
    //MARK: - Constants
    private let batchSize = 25
    private let loggerEndPoint: String
    private let sessionIdKey = "SessionId"
    private let telemetryeventsKey = "TelemetryEvents"
    let serialDispatchQueue = dispatch_queue_create("com.cliqz.EventsLogger", DISPATCH_QUEUE_SERIAL);
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    //MARK: - Instant Variables
    private var events = SynchronousArray()
    lazy var sessionId: String = self.getSessoinId()
    
    
    //MARK: - Dealing with SessionId
    private var source: String {
        get {
            if AppStatus.sharedInstance.isDebug {
                return "MI02" // Debug
            } else if AppStatus.sharedInstance.isRelease {
                return "MI00" // Release
            } else {
                return "MI01" // TestFlight
            }
        }
    }
    
    private func getSessoinId() -> String {
        if let storedSessionId = LocalDataStore.objectForKey(sessionIdKey) as? String {
            return storedSessionId
        } else {
            return generateNewSessionId()
            
        }
    }
    
    private func generateNewSessionId () -> String {
        let randomString = String.generateRandomString(18)
        let randomNumbersString = String.generateRandomString(6, alphabet: "1234567890")
        
        let sessionId = "\(randomString + randomNumbersString)|\(NSDate.getDay())|\(source)"
        return sessionId
    }
    
    private func storeSessoinId(newSessoinId: String) {
        sessionId = newSessoinId
        LocalDataStore.setObject(sessionId, forKey: self.sessionIdKey)
    }
    
    func getInstallDay() -> Int? {
        guard sessionId.contains("|") else {
            return nil
        }
        let installDay = sessionId.componentsSeparatedByString("|")[1]
        return Int(installDay)
    }
    
    //MARK: - Initialization
    init (endPoint: String){
        loggerEndPoint = endPoint
        super.init()
        loadPersistedEvents()
        LocalDataStore.setObject(self.sessionId, forKey: sessionIdKey)
    }
    
    //MARK: - Storing events
    internal func storeEvent(event: [String: AnyObject]){
        events.append(event)
        if events.count % 10 == 0 {
            // periodically persist events to avoid loosing a lot of events in case of app crash
            persistEvents()
        }
        #if BETA
        // Dump telemetry signals only in Beta for testing purposes
        NSLog("[Telemetry]: %@", event)
        #endif
    }
    internal func persistEvents() {
        do {
            let eventsContents = events.getContents()
            if NSJSONSerialization.isValidJSONObject(eventsContents) {
                let eventsData = try NSJSONSerialization.dataWithJSONObject(eventsContents, options: [])
                LocalDataStore.setObject(eventsData, forKey: self.telemetryeventsKey)
            } else {
                Answers.logCustomEventWithName("SerializeInvalidTelemetrySignal", customAttributes: nil)
            }
        } catch let error as NSError {
            Answers.logCustomEventWithName("SerializeTelemetryError", customAttributes: ["error": error.localizedDescription])
        }
        
    }
    
    internal func clearPersistedEvents() {
        LocalDataStore.setObject(nil, forKey: self.telemetryeventsKey)
    }
    
    internal func loadPersistedEvents() {
        do {
            if let eventsData = LocalDataStore.objectForKey(self.telemetryeventsKey) as? NSData {
                let events = try NSJSONSerialization.JSONObjectWithData(eventsData, options: []) as! [AnyObject]
                self.events.appendContentsOf(events)
            }
        } catch let error as NSError {
            Answers.logCustomEventWithName("DeserializeTelemetryError", customAttributes: ["error": error.localizedDescription])
        }
    }
    
    
    internal func getLastStoredSeq() -> Int? {
        guard events.count > 0 else {
            return nil
        }
        
        let lastEvent = events.getContents()[events.count-1]
        let lastStoredSeq = lastEvent["seq"] as? Int
        return lastStoredSeq
    }
    //MARK: - background tasks
    internal func appDidEnterBackground() {
        registerBackgroundTask()
        
        TelemetryLogger.sharedInstance.persistState()
        
        if NetworkReachability.sharedInstance.isReachableViaWiFi() {
            dispatch_async(serialDispatchQueue) {
                self.publishCurrentEvents()
            }
        } else {
            endBackgroundTask()
        }
    }
    func registerBackgroundTask() {
        backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler {
            [unowned self] in
            self.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        if backgroundTask != UIBackgroundTaskInvalid {
            UIApplication.sharedApplication().endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }
    }
    
    //MARK: - Sending events to server
    internal func sendEvent(event: [String: AnyObject]){
        // dispatch_async in a serial thread so as not to send same events twice
        dispatch_async(serialDispatchQueue) {
            if self.shoudPublishEvents() {
                self.publishCurrentEvents()
            }
        }
    }
    
    //MARK: - Private methods
    private func shoudPublishEvents() -> Bool {
        if let isReachable = NetworkReachability.sharedInstance.isReachable {
            if isReachable && self.events.count >= self.batchSize {
                return true
            }
        }
        
        return false;
    }

    private func publishCurrentEvents() {
        let publishedEvents = self.events.getContents()
        self.events.removeAll()
        self.publishEvents(publishedEvents)
        self.clearPersistedEvents()
    }
    
    private func publishEvents(publishedEvents: [AnyObject]){

		ConnectionManager.sharedInstance.sendPostRequestWithBody(loggerEndPoint, body: publishedEvents, responseType: .JSONResponse, enableCompression: true, queue: self.serialDispatchQueue,
            onSuccess: { json in
                let jsonDict = json as! [String : AnyObject]
                if let newSessionId = jsonDict["new_session"] as? String {
                    self.storeSessoinId(newSessionId)
                }
                self.endBackgroundTask()
            },
            onFailure: { (data, error) in
                self.events.appendContentsOf(publishedEvents)
                self.persistEvents()
                self.endBackgroundTask()
        })
    }
}
