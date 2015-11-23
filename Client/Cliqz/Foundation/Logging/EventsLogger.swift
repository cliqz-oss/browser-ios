//
//  EventsLogger.swift
//  Client
//
//  Created by Mahmoud Adam on 11/4/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

class EventsLogger: NSObject {
    
    //MARK: - Constants
    private let batchSize = 5
    private let loggerEndPoint: String
    private let sessionIdKey = "SessionId"
    
    //MARK: - Instant Variables
    private var events = SynchronousArray()
    lazy var sessionId: String = self.getSessoinId()
    
    
    //MARK: - Dealing with SessionId
    private var source: String {
        get {
            #if DEBUG
                return "MI02" // Debug
            #else
                if AppStatus.sharedInstance.isRelease {
                    return "MI00" // Release
                } else {
                    return "MI01" // TestFlight
                }
            #endif
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
    
    
    //MARK: - Initialization
    init (endPoint: String){
        loggerEndPoint = endPoint
        super.init()
        LocalDataStore.setObject(self.sessionId, forKey: sessionIdKey)
    }
    
    //MARK: - Sending events to server
    internal func sendEvent(event: [String: AnyObject]){
        self.events.append(event)
        if self.shoudPublishEvents() {
            self.publishEvents()
            self.events.removeAll()
        }
    }
    
    //MARK: - Private methods
    private func shoudPublishEvents() -> Bool {
        // TODO: Check if internect connection (Wifi/3G/...)
        if let isReachable = NetworkReachability.sharedInstance.isReachable {
            if isReachable && self.events.count >= self.batchSize {
                return true
            }
        }
        
        return false;
    }
    
    private func publishEvents(){

        let publishedEvents = self.events.getContents()
        ConnectionManager.sharedInstance.sendPostRequest(loggerEndPoint, body: publishedEvents,
            onSuccess: { json in
                let jsonDict = json as! [String : AnyObject]
                if let newSessionId = jsonDict["new_session"] as? String {
                    self.storeSessoinId(newSessionId)
                }
                DebugLogger.log("push telemetry succeded: \(publishedEvents.count) elements ")
            },
            onFailure: { (data, error) in
                DebugLogger.log("push telemetry failed: \(publishedEvents.count) elements with error: \(error)")
                self.events.appendContentsOf(publishedEvents)
        })
    }
}
