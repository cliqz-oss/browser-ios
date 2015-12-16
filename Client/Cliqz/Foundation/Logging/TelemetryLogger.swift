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
    case ApplicationUsage   (String, String, String, Float, Double, String?, Double?, Double?)
    case NetworkStatus      (String, Int)
    case QueryInteraction   (String, Int)
    case Environment        (String, String, String, String, String, Int, Int, [String: AnyObject])
    case UrlFocusBlur       (String, String)
    case LayerChange        (String, String)
    case Onboarding         (String, Int)
    case PastTap            (String, Int, Double, Double, Double)
    case JavaScriptsignal   ([String: AnyObject])
    
    //TODO: to be removed as it was added for testing
    case AppStateChange      (String)
}


class TelemetryLogger : EventsLogger {
    
    let dispatchQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    
    //MARK: - Singltone
    static let sharedInstance = TelemetryLogger()
    
    init() {
        super.init(endPoint: "https://logging.cliqz.com")        
        loadTelemetrySeq()
    }
    
    
    //MARK: - Instant Variables
    var telemetrySeq: AtomicInt?
    private let telementrySequenceKey = "TelementrySequence"

    private func loadTelemetrySeq() {
        dispatch_sync(serialDispatchQueue) {
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
            var disableSendingEvent = false

            switch (eventType) {
                
            case .LifeCycle(let action, let version):
                event = self.createLifeCycleEvent(action, version: version)
                
            case .ApplicationUsage(let action, let network, let context, let battery, let memory, let startupType, let startupTime, let timeUsed):
                event = self.createApplicationUsageEvent(action, network: network, context: context, battery: battery, memory: memory, startupType: startupType, startupTime: startupTime, timeUsed: timeUsed)
                
            case .NetworkStatus(let network, let duration):
                event = self.createNetworkStatusEvent(network, duration:duration)

            case .QueryInteraction(let action, let currentLength):
                event = self.createQueryInteractionEvent(action, currentLength: currentLength)
                // disable sending event when there is query interaction
                disableSendingEvent = true
                
            case .Environment(let device, let language, let version, let osVersion, let defaultSearchEngine, let historyUrls, let historyDays, let prefs):
                event = self.createEnvironmentEvent(device, language: language, version: version, osVersion: osVersion, defaultSearchEngine: defaultSearchEngine, historyUrls: historyUrls, historyDays: historyDays, prefs: prefs)
                
            case .UrlFocusBlur(let action, let context):
                event = self.createUrlFocusBlurEvent(action, context: context)
                // disable sending event when there is interaction with the search bar (user is about to type or about to navigate to url)
                disableSendingEvent = true

            case .LayerChange(let currentLayer, let nextLayer):
                event = self.createLayerChangeEvent(currentLayer, nextLayer: nextLayer)
                
            case .Onboarding(let action, let page):
                event = self.createOnboardingEvent(action, page: page)
               
            case .PastTap(let pastType, let querylength, let positionAge, let lengthAge, let displayTime):
                event = self.createPastTabEvent(pastType, querylength: querylength, positionAge: positionAge, lengthAge: lengthAge, displayTime: displayTime)
                
            case .JavaScriptsignal(let javaScriptSignal):
                event = self.creatJavaScriptSignalEvent(javaScriptSignal)
            
            case .AppStateChange(let transition):
                event = self.createAppStateChangeEvent(transition)
            }
            
            // Always store the event
            self.storeEvent(event)
            
            // try to send the event only if there is no query interactions
            if !disableSendingEvent {
                self.sendEvent(event)
            }
        }
    }
    
    //MARK: - Private Helper methods
    
    internal func createBasicEvent() ->[String: AnyObject] {
        var event = [String: AnyObject]()
        
        event["session"] = self.sessionId
        event["telemetrySeq"] = getNextTelemetrySeq()
        event["ts"] = NSDate.getCurrentMillis()
        
        if telemetrySeq!.get() % 10 == 0 {
            // periodically store the telemetrySeq
            storeCurrentTelemetrySeq()
        }
        return event
    }
    
    private func getNextTelemetrySeq() -> Int {
        let nextTelemetrySeq = telemetrySeq!.incrementAndGet()

        // periodically store the telemetrySeq
        if nextTelemetrySeq % 10 == 0 {
            storeCurrentTelemetrySeq()
        }
        
        return nextTelemetrySeq
    }

    
    private func createLifeCycleEvent(action: String, version: String) -> [String: AnyObject]{
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = action
        event["version"] = version
        
        return event
    }
    private func createApplicationUsageEvent(action: String, network: String, context: String, battery: Float, memory: Double, startupType: String?, startupTime: Double?, timeUsed: Double?) -> [String: AnyObject]{
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = action
        event["network"] = network
        event["context"] = context
        event["battery"] = battery
        event["memory"] = memory

        if startupType != nil {
            event["startup_type"] = startupType
        }
        
        if startupTime != nil {
            event["startup_time"] = startupTime
        }

        if timeUsed != nil {
            event["time_used"] = timeUsed
        }
        
        return event
    }
    private func createEnvironmentEvent(device: String, language: String, version: String, osVersion: String, defaultSearchEngine: String, historyUrls: Int, historyDays: Int, prefs: [String: AnyObject]) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "environment"
        event["device"] = device
        event["language"] = language
        event["version"] = version
        event["os_version"] = osVersion
        event["defaultSearchEngine"] = defaultSearchEngine
        event["historyUrls"] = historyUrls
        event["historyDays"] = historyDays
        event["prefs"] = prefs
        
        return event
    }
    private func createNetworkStatusEvent(network: String, duration: Int) -> [String: AnyObject]{
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = "network_status"
        event["network"] = network
        event["duration"] = duration
        
        return event
    }
    
    private func createQueryInteractionEvent(action: String, currentLength: Int) -> [String: AnyObject]{
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = action
        event["current_length"] = currentLength
        
        return event
    }
    
    private func createUrlFocusBlurEvent(action: String, context: String) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = action
        if !context.isEmpty {
            event["context"] = context
        }
        
        return event
    }
    
    private func createLayerChangeEvent(currentLayer: String, nextLayer: String) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = "layer_change"
        event["current_layer"] = currentLayer
        event["next_layer"] = nextLayer
        event["display_time"] = event["ts"]
        
        return event
    }
    
    private func createOnboardingEvent(action: String, page: Int) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "onboarding"
        event["action"] = action
        event["page"] = page
        if action == "hide" {
            event["display_time"] = event["ts"]
        }

        return event
    }
    private func createPastTabEvent(pastType: String, querylength: Int, positionAge: Double, lengthAge: Double, displayTime: Double) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = "past_tap"
        event["query_length"] = querylength
        event["position_age"] = positionAge
        event["length_age"] = lengthAge
        event["display_time"] = displayTime
        
        return event
    }
    
    private func creatJavaScriptSignalEvent(javaScriptSignal: [String: AnyObject]) -> [String: AnyObject] {
        var event = javaScriptSignal
        
        event["session"] = self.sessionId
        event["telemetrySeq"] = getNextTelemetrySeq()

        return event
    }

    
    //TODO: to be removed as it was added for testing
    private func createAppStateChangeEvent(transition: String) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = "AppStateChange"
        event["transition"] = transition
        
        return event
    }
    
}
