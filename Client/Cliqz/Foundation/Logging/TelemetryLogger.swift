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
    case ApplicationUsage   (String, String, String, Int, Double, String?, Double?, Double?)
    case NetworkStatus      (String, Int)
    case QueryInteraction   (String, Int)
    case Environment        (String, String, String, String, String, Int, Int, [String: AnyObject])
    case UrlFocusBlur       (String, String)
    case LayerChange        (String, String)
    case Onboarding         (String, Int)
    case PastTap            (String, Int, Double, Double, Double)
    case Navigation         (String, Int, Int, Double)
    case ResultEnter        (Int, Int, String?, Double, Double)
    case JavaScriptSignal   ([String: AnyObject])
	case LocationServicesStatus (String, String?)
    case HomeScreenShortcut (String, Int)
    case TabSignal          (String, String, Int?, Int)
    case NewsNotification   (String)
	case YoutubeVideoDownloader	(String, String, String, String)
}


class TelemetryLogger : EventsLogger {
    
    let dispatchQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    
    //MARK: - Singltone
    static let sharedInstance = TelemetryLogger()
    
    var privateMode = false
    
    init() {
        super.init(endPoint: "https://logging.cliqz.com")        
        loadTelemetrySeq()
    }
    
    
    //MARK: - Instant Variables
    var telemetrySeq: AtomicInt?
    private let telementrySequenceKey = "TelementrySequence"

    private func loadTelemetrySeq() {
        dispatch_sync(serialDispatchQueue) {
            if let lastStoredSeq = self.getLastStoredSeq() {
                self.telemetrySeq = AtomicInt(initialValue: lastStoredSeq)
            } else if let storedSeq = LocalDataStore.objectForKey(self.telementrySequenceKey) as? Int {
                self.telemetrySeq = AtomicInt(initialValue: storedSeq)
            } else {
                self.telemetrySeq = AtomicInt(initialValue: 0)
            }
        }
    }
    
    func storeCurrentTelemetrySeq() {
        LocalDataStore.setObject(telemetrySeq!.get(), forKey: self.telementrySequenceKey)
    }
    //MARK: - private mode
    func changePrivateMode(privateMode: Bool) {
        self.privateMode = privateMode
    }
    
    //MARK: - Presisting events and sequence
    internal func persistState() {
        self.storeCurrentTelemetrySeq()
        self.persistEvents()
    }
    
    //MARK: - Log events
    internal func logEvent(eventType: TelemetryLogEventType){
        // disable sending any signals during private mode
        guard privateMode == false else {
            return
        }
        
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
                
            case .Navigation(let action, let step, let urlLength, let displayTime):
                event = self.createNavigationEvent(action, step: step, urlLength: urlLength, displayTime: displayTime)
                
            case .ResultEnter(let queryLength, let autocompletedLength, let autocompletedUrl, let reactionTime, let urlbarTime):
                event = self.createResultEnterEvent(queryLength, autocompletedLength: autocompletedLength, autocompletedUrl: autocompletedUrl, reactionTime: reactionTime, urlbarTime: urlbarTime)
                
            case .JavaScriptSignal(let javaScriptSignal):
                event = self.creatJavaScriptSignalEvent(javaScriptSignal)
			
            case .LocationServicesStatus(let action, let status):
				event = self.createLocationServicesStatusEvent(action, status: status)
                
            case .HomeScreenShortcut(let targetType, let targetIndex):
                event = self.createHomeScreenShortcutEvent(targetType, targetIndex: targetIndex)
            
            case .TabSignal(let action, let mode, let tabIndex, let tabCount):
                event = self.createTabSignalEvent(action, mode: mode, tabIndex: tabIndex, tabCount: tabCount)
                
            case .NewsNotification(let action):
                event = self.createNewsNotificationEvent(action)
			
			case .YoutubeVideoDownloader(let type, let action, let statusKey, let statusValue):
				event = self.createYoutubeVideoDownloaderEvent(type, action: action, statusKey: statusKey, statusValue: statusValue)
            }
            
            // Always store the event
            self.storeEvent(event)
            
            // try to send the event only if there is no query interactions
            if !disableSendingEvent {
                self.sendEvent(event)
            }
        }
    }

    // MARK: - Private Helper methods

    internal func createBasicEvent() ->[String: AnyObject] {
        var event = [String: AnyObject]()

        event["session"] = self.sessionId
        event["seq"] = getNextTelemetrySeq()
        event["ts"] = NSNumber(longLong: Int64(NSDate.getCurrentMillis()))

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
    private func createApplicationUsageEvent(action: String, network: String, context: String, battery: Int, memory: Double, startupType: String?, startupTime: Double?, timeUsed: Double?) -> [String: AnyObject]{
        var event = createBasicEvent()

        event["type"] = "app_state_change"
        event["state"] = action
        event["network"] = network
        event["context"] = context
        event["battery"] = battery
        event["memory"] = NSNumber(longLong: Int64(memory))

        if startupType != nil {
            event["startup_type"] = startupType
        }
        
        if let s = startupTime {
            event["startup_time"] = NSNumber(longLong: Int64(s))
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
        
        event["type"] = "network_status"
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
        event["action_target"] = page
		event["product"] = "cliqz_ios"
		event["version"] = "1.0"
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
    private func createNavigationEvent(action: String, step: Int, urlLength: Int, displayTime: Double) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "navigation"
        event["action"] = action
        event["step"] = step
        event["url_length"] = urlLength
        event["display_time"] = displayTime
        
        return event
    }
    
    private func createResultEnterEvent(queryLength: Int, autocompletedLength: Int, autocompletedUrl: String?, reactionTime: Double, urlbarTime: Double) -> [String: AnyObject] {
        var event = createBasicEvent()
        // This handel three types of signals: AutoComplete, DirectURL, and Google search
        event["type"] = "activity"
        event["action"] = "result_enter"
        event["query_length"] = queryLength
        event["reaction_time"] = reactionTime
        event["urlbar_time"] = urlbarTime
        
        if autocompletedLength > queryLength {
            event["autocompleted_length"] = autocompletedLength
            event["autocompleted"] = "url"
            event["inner_link"] = true
        } else {
            event["inner_link"] = false
        }
        
        if  autocompletedUrl == nil {
            event["position_type"] = ["inbar_query"]
        } else {
            event["position_type"] = ["inbar_url"]
        }
        
        // fixed values so as not to conflict with desktop version
        event["current_position"] = -1
        
        event["extra"] = nil
        event["search"] = false
        event["has_image"] = false
        event["clustering_override"] = false
        event["new_tab"] = false
        
        return event
    }

    private func creatJavaScriptSignalEvent(javaScriptSignal: [String: AnyObject]) -> [String: AnyObject] {
        var event = javaScriptSignal
        
        event["session"] = self.sessionId
        event["seq"] = getNextTelemetrySeq()

        return event
    }

	private func createLocationServicesStatusEvent(action: String, status: String?) -> [String: AnyObject]{
		var event = createBasicEvent()
		event["type"] = "location_access"
		event["action"] = action
		if let s = status {
			event["status"] = s
		}
		return event
	}
    
    private func createHomeScreenShortcutEvent(targetType: String, targetIndex: Int) -> [String: AnyObject]{
        var event = createBasicEvent()
        event["type"] = "home_screen"
        event["action"] = "click"
        event["target_type"] = targetType
        event["target_index"] = targetIndex
        return event
    }
    
    private func createTabSignalEvent(action: String, mode: String, tabIndex: Int?, tabCount: Int) -> [String: AnyObject] {
        var event = createBasicEvent()
        event["type"] = "tab"
        event["action"] = action
        event["mode"] = mode
        if let index = tabIndex {
            event["tab_index"] = index
        }
        event["tab_count"] = tabCount
        return event
    }
    
    private func createNewsNotificationEvent(action: String) -> [String: AnyObject] {
        var event = createBasicEvent()
        event["type"] = "news_notification"
        event["action"] = action
        return event
    }
	
	private func createYoutubeVideoDownloaderEvent(type: String, action: String, statusKey: String, statusValue: String) -> [String: AnyObject] {
		var event = createBasicEvent()
		event["type"] = type
		event["action"] = action
		event[statusKey] = statusValue
		return event
	}
}
