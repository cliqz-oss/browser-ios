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
    fileprivate let batchSize = 25
    fileprivate let loggerEndPoint: String
    fileprivate let sessionIdKey = "SessionId"
    fileprivate let telemetryeventsKey = "TelemetryEvents"
    let serialDispatchQueue = DispatchQueue(label: "com.cliqz.EventsLogger", attributes: []);
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    //MARK: - Instant Variables
    fileprivate var events = SynchronousArray()
    lazy var sessionId: String = self.getSessoinId()
    
    
    //MARK: - Dealing with SessionId
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
    
    fileprivate func getSessoinId() -> String {
        if let storedSessionId = LocalDataStore.objectForKey(sessionIdKey) as? String {
            return storedSessionId
        } else {
            return generateNewSessionId()
            
        }
    }
    
    fileprivate func generateNewSessionId () -> String {
        let randomString = String.generateRandomString(18)
        let randomNumbersString = String.generateRandomString(6, alphabet: "1234567890")
        
        let sessionId = "\(randomString + randomNumbersString)|\(Date.getDay())|\(source)"
        return sessionId
    }
    
    fileprivate func storeSessoinId(_ newSessoinId: String) {
        sessionId = newSessoinId
        LocalDataStore.setObject(sessionId, forKey: self.sessionIdKey)
    }
    
    func getInstallDay() -> Int? {
        guard sessionId.contains("|") else {
            return nil
        }
        let installDay = sessionId.components(separatedBy: "|")[1]
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
    internal func storeEvent(_ event: [String: Any]){
        events.append(event)
        if events.count % 10 == 0 {
            // periodically persist events to avoid loosing a lot of events in case of app crash
            persistEvents()
        }
        
        #if BETA
        if SettingsPrefs.getLogTelemetryPref() {
            // Dump telemetry signals only in Beta for testing purposes
            NSLog("[Telemetry]: %@", event)
            print("[Telemetry]: \(event)")
        }
        #endif
    }
    internal func persistEvents() {
        do {
            let eventsContents = events.getContents()
            if JSONSerialization.isValidJSONObject(eventsContents) {
                let eventsData = try JSONSerialization.data(withJSONObject: eventsContents, options: [])
                LocalDataStore.setObject(eventsData, forKey: self.telemetryeventsKey)
            } else {
                Answers.logCustomEvent(withName: "SerializeInvalidTelemetrySignal", customAttributes: nil)
            }
        } catch let error as NSError {
            Answers.logCustomEvent(withName: "SerializeTelemetryError", customAttributes: ["error": error.localizedDescription])
        }
        
    }
    
    internal func clearPersistedEvents() {
        LocalDataStore.setObject(nil, forKey: self.telemetryeventsKey)
    }
    
    internal func loadPersistedEvents() {
        do {
            if let eventsData = LocalDataStore.objectForKey(self.telemetryeventsKey) as? Data {
                let events = try JSONSerialization.jsonObject(with: eventsData, options: []) as! [AnyObject]
                self.events.appendContentsOf(events)
            }
        } catch let error as NSError {
            Answers.logCustomEvent(withName: "DeserializeTelemetryError", customAttributes: ["error": error.localizedDescription])
        }
    }
    
    
    internal func getLastStoredSeq() -> Int? {
        guard events.count > 0 else {
            return nil
        }
        
		if let lastEvent = events.getContents()[events.count-1] as? [String: Any] {
			let lastStoredSeq = lastEvent["seq"] as? Int
			return lastStoredSeq
		}
		return nil
    }

    //MARK: - background tasks
    internal func appDidEnterBackground() {
        registerBackgroundTask()
        
        TelemetryLogger.sharedInstance.persistState()
        
        if NetworkReachability.sharedInstance.isReachableViaWiFi() {
            serialDispatchQueue.async {
                self.publishCurrentEvents()
            }
        } else {
            endBackgroundTask()
        }
    }
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask (expirationHandler: {
            [unowned self] in
            self.endBackgroundTask()
        })
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        if backgroundTask != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }
    }
    
    //MARK: - Sending events to server
    internal func sendEvent(_ event: [String: Any]){
        // dispatch_async in a serial thread so as not to send same events twice
        serialDispatchQueue.async {
            if self.shoudPublishEvents() {
                self.publishCurrentEvents()
            }
        }
    }
    
    //MARK: - Private methods
    fileprivate func shoudPublishEvents() -> Bool {
        if let isReachable = NetworkReachability.sharedInstance.isReachable {
            if isReachable && self.events.count >= self.batchSize {
                return true
            }
        }
        
        return false;
    }

    fileprivate func publishCurrentEvents() {
        let publishedEvents = self.events.getContents()
        self.events.removeAll()
        self.publishEvents(publishedEvents)
        self.clearPersistedEvents()
    }
    
    fileprivate func publishEvents(_ publishedEvents: [Any]){

		ConnectionManager.sharedInstance.sendPostRequestWithBody(loggerEndPoint, body: publishedEvents, responseType: .jsonResponse, enableCompression: true, queue: self.serialDispatchQueue,
            onSuccess: { json in
                let jsonDict = json as! [String : Any]
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
