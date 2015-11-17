//
//  TelemetryLogger.swift
//  Client
//
//  Created by Mahmoud Adam on 11/4/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

public enum TelemetryLogEventType {
    case LifeCycle          (String, String)
    case ApplicationUsage   (String, String, String, Float, Double)
    case NetworkChange      (String, String)
    case QueryInteraction   (String, Int)
    case Environment        (String, String, String, String, Int, Int, [String: AnyObject])
}


class TelemetryLogger : EventsLogger {
    
    let dispatchQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    
    //MARK: - Singltone
    static let sharedInstance = TelemetryLogger()
    
    init() {
        #if DEBUG
            super.init(endPoint: "http://localhost:8085/")
        #else
            super.init(endPoint: "https://logging.cliqz.com")
        #endif
        
        loadTelemetrySeq()
    }
    
    
    //MARK: - Instant Variables
    var telemetrySeq: AtomicInt?
    private let telementrySequenceKey = "TelementrySequence"

    private func loadTelemetrySeq() {
        dispatch_sync(dispatchQueue) {
            if let storedSeq = LocalDataStore.objectForKey(self.telementrySequenceKey) as? Int {
                self.telemetrySeq = AtomicInt(initialValue: storedSeq)
            } else {
                self.telemetrySeq = AtomicInt(initialValue: 0)
            }
        }
    }
    
    func storeCurrentTelemetrySeq() {
        LocalDataStore.setObject(telemetrySeq!.get(), forKey: self.telementrySequenceKey)
    }
    
    //MARK: - Log events
    internal func logEvent(eventType: TelemetryLogEventType){

        dispatch_async(dispatchQueue) {
            var event: [String: AnyObject]
            
            switch (eventType) {
                
            case .LifeCycle(let action, let version):
                event = self.createLifeCycleEvent(action, version: version)
                
            case .ApplicationUsage(let action, let network, let context, let battery, let timeUsed):
                event = self.createApplicationUsageEvent(action, network: network, context: context, battery: battery, timeUsed: timeUsed)
                
            case .NetworkChange(let action, let network):
                event = self.createNetworkChangeEvent(action, network: network)

            case .QueryInteraction(let action, let length):
                event = self.createQueryInteractionEvent(action, length: length)
                
            case .Environment(let device, let language, let version, let defaultSearchEngine, let historyUrls, let historyDays, let prefs):
                event = self.createEnvironmentEvent(device, language: language, version: version, defaultSearchEngine: defaultSearchEngine, historyUrls: historyUrls, historyDays: historyDays, prefs: prefs)
            }
            
            self.sendEvent(event)
        }
    }
    
    //MARK: - Private Helper methods
    
    internal func createBasicEvent() ->[String: AnyObject] {
        var event = [String: AnyObject]()
        
        event["session"] = self.sessionId
        event["telemetrySeq"] = telemetrySeq!.incrementAndGet()
        event["ts"] = NSDate.getCurrentMillis()
        
        if telemetrySeq!.get() % 10 == 0 {
            // periodically store the telemetrySeq
            storeCurrentTelemetrySeq()
        }
        return event
    }

    
    private func createLifeCycleEvent(action: String, version: String) -> [String: AnyObject]{
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = action
        event["version"] = version
        
        return event
    }
    private func createApplicationUsageEvent(action: String, network: String, context: String, battery: Float, timeUsed: Double) -> [String: AnyObject]{
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = action
        event["network"] = network
        event["context"] = context
        event["battery"] = battery
        event["timeUsed"] = timeUsed
        
        return event
    }
    private func createEnvironmentEvent(device: String, language: String, version: String, defaultSearchEngine: String, historyUrls: Int, historyDays: Int, prefs: [String: AnyObject]) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "environment"
        event["device"] = device
        event["language"] = language
        event["version"] = version
        event["defaultSearchEngine"] = defaultSearchEngine
        event["historyUrls"] = historyUrls
        event["historyDays"] = historyDays
        event["prefs"] = prefs
        
        return event
    }
    private func createNetworkChangeEvent(action: String, network: String) -> [String: AnyObject]{
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = action
        event["network"] = network
        
        return event
    }
    
    private func createQueryInteractionEvent(action: String, length: Int) -> [String: AnyObject]{
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = action
        event["current_length"] = length
        
        return event
    }
    
}
