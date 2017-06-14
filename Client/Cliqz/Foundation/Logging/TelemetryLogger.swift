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
    case ApplicationUsage   (String, String, Int, Double, String?, Double?, Double?)
    case NetworkStatus      (String, Int)
    case QueryInteraction   (String, Int)
    case Environment        (String, String, String, String, String, String, String, Int, Int, [String: Any])
    case Onboarding         (String, [String: Any]?)
    case Navigation         (String, Int, Int, Double)
    case ResultEnter        (Int, Int, String?, Double, Double)
    case JavaScriptSignal   ([String: Any])
	case LocationServicesStatus (String, String?)
    case HomeScreenShortcut (String, Int)
    case NewsNotification   (String)
	case YoutubeVideoDownloader	(String, String, String)
    case Settings (String, String, String, String?, Int?)
    case Toolbar            (String, String, String, Bool?, [String: Any]?)
    case Keyboard            (String, String, Bool, Int?)
    case WebMenu            (String, String, Bool)
    case AntiPhishing            (String, String?, Int?)
    case ShareMenu            (String, String)
    case DashBoard            (String, String, String?, [String: Any]?)
    case ContextMenu            (String, String)
    case QuerySuggestions        (String, [String: Any]?)
    case ControlCenter         (String, String?, String?, [String: Any]?)
	case FreshTab (String, String?, [String: Any]?)
}


class TelemetryLogger : EventsLogger {
    
    let dispatchQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
    
    fileprivate var isForgetModeActivate = false
    fileprivate let preventedTypesInForgetMode = ["home", "cards", "web", "web_menu", "context_menu", "share_menu", "attrack", "anti_phishing", "video_downloader"]
    fileprivate let preventedActionsInForgetMode = ["result_enter", "key_stroke", "keystroke_del", "paste", "results", "result_click"]
    
    //MARK: - Singltone
    static let sharedInstance = TelemetryLogger()
    
    init() {
        super.init(endPoint: "https://logging.cliqz.com")        
        loadTelemetrySeq()
        ABTestsManager.checkABTests(sessionId)
    }
    
    func updateForgetModeStatue(_ newStatus: Bool) {
        dispatchQueue.async {[weak self] in
            self?.isForgetModeActivate = newStatus
        }
    }
    
    //MARK: - Instant Variables
    var telemetrySeq: AtomicInt?
    fileprivate let telementrySequenceKey = "TelementrySequence"

    fileprivate func loadTelemetrySeq() {
        serialDispatchQueue.sync {
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
    
    //MARK: - Presisting events and sequence
    internal func persistState() {
        self.storeCurrentTelemetrySeq()
        self.persistEvents()
    }
    
    //MARK: - Log events
    internal func logEvent(_ eventType: TelemetryLogEventType) {
        
        dispatchQueue.async {
            var event: [String: Any]
            var disableSendingEvent = false

            switch (eventType) {
                
            case .LifeCycle(let action, let distVersion):
                event = self.createLifeCycleEvent(action, distVersion: distVersion)
                
            case .ApplicationUsage(let action, let network, let battery, let memory, let startupType, let startupTime, let openDuration):
                event = self.createApplicationUsageEvent(action, network: network, battery: battery, memory: memory, startupType: startupType, startupTime: startupTime, openDuration: openDuration)
                
            case .NetworkStatus(let network, let duration):
                event = self.createNetworkStatusEvent(network, duration:duration)

            case .QueryInteraction(let action, let currentLength):
                event = self.createQueryInteractionEvent(action, currentLength: currentLength)
                // disable sending event when there is query interaction
                disableSendingEvent = true
                
            case .Environment(let device, let language, let extensionVersion, let distVersion, let hostVersion, let osVersion, let defaultSearchEngine, let historyUrls, let historyDays, let prefs):
                event = self.createEnvironmentEvent(device, language: language, extensionVersion: extensionVersion, distVersion: distVersion, hostVersion: hostVersion, osVersion: osVersion, defaultSearchEngine: defaultSearchEngine, historyUrls: historyUrls, historyDays: historyDays, prefs: prefs)

            case .Onboarding(let action, let customData):
                event = self.createOnboardingEvent(action, customData: customData)
               
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
            
            case .NewsNotification(let action):
                event = self.createNewsNotificationEvent(action)
			
			case .YoutubeVideoDownloader(let action, let statusKey, let statusValue):
				event = self.createYoutubeVideoDownloaderEvent(action, statusKey: statusKey, statusValue: statusValue)
                
            case .Settings(let view, let action, let target, let state, let duration):
                event = self.createSettingsEvent(view, action: action, target: target, state: state, duration: duration)
                
            case .Toolbar(let action, let target, let view, let isForgetMode, let customData):
                event = self.createToolbarEvent(action, target: target, view: view, isForgetMode: isForgetMode, customData: customData)
                
            case .Keyboard(let action, let view, let isForgetMode, let showDuration):event = self.createKeyboardEvent(action, view: view, isForgetMode: isForgetMode, showDuration: showDuration)
                // disable sending event when there is interaciton with keyboars
                disableSendingEvent = true
                
            case .WebMenu(let action, let target, let isForgetMode):
                event = self.createWebMenuEvent(action, target: target, isForgetMode: isForgetMode)
            
            case .AntiPhishing(let action, let target, let showDuration):
                event = self.createAntiPhishingEvent(action, target: target, showDuration: showDuration)
            
                
            case .ShareMenu (let action, let target):
                event = self.createShareMenuEvent(action, target: target)
                
            case .DashBoard (let type, let action, let target, let customData):
                event = self.createDashBoardEvent(type, action: action, target: target, customData: customData)
                
                
            case .ContextMenu (let target, let view):
                event = self.createContextMenuEvent(target, view: view)
            
            case .QuerySuggestions (let action, let customData):
                event = self.createQuerySuggestionsEvent(action, customData: customData)
                
            case .ControlCenter (let action, let view, let target, let customData):
                event = self.createControlCenterEvent(action, view: view, target: target, customData: customData)
			case .FreshTab(let action, let target, let customData):
                event = self.createFreshTabEvent(action, target: target, customData: customData)
            }
            
            if self.isForgetModeActivate && self.shouldPreventEventInForgetMode(event) {
                return
            }
            
            // Always store the event
            self.storeEvent(event)
            
            // try to send the event only if there is no query interactions
            if !disableSendingEvent {
                self.sendEvent(event)
            }
        }
    }

    fileprivate func shouldPreventEventInForgetMode(_ event: [String: Any]) -> Bool {
        if let type = event["type"] as? String, preventedTypesInForgetMode.contains(type) {
            return true
        }
        
        if let action = event["action"] as? String, preventedActionsInForgetMode.contains(action) {
            return true
        }
        
        return false
    }
    // MARK: - Private Helper methods

    internal func createBasicEvent() ->[String: Any] {
        var event = [String: Any]()

        event["session"] = self.sessionId
        event["seq"] = getNextTelemetrySeq()
        event["ts"] = NSNumber(value: Int64(Date.getCurrentMillis()) as Int64)

        if telemetrySeq!.get() % 10 == 0 {
            // periodically store the telemetrySeq
            storeCurrentTelemetrySeq()
        }
        return event
    }
    
    fileprivate func getNextTelemetrySeq() -> Int {
        let nextTelemetrySeq = telemetrySeq!.incrementAndGet()

        // periodically store the telemetrySeq
        if nextTelemetrySeq % 10 == 0 {
            storeCurrentTelemetrySeq()
        }
        
        return nextTelemetrySeq
    }

    
    fileprivate func createLifeCycleEvent(_ action: String, distVersion: String) -> [String: Any]{
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = action
        event["version_dist"] = distVersion

        return event
    }

    fileprivate func createApplicationUsageEvent(_ action: String, network: String, battery: Int, memory: Double, startupType: String?, startupTime: Double?, openDuration: Double?) -> [String: Any]{
        var event = createBasicEvent()

        event["type"] = "app_state_change"
        event["state"] = action
        event["network"] = network
        event["battery"] = battery
        event["memory"] = NSNumber(value: Int64(memory) as Int64)

        if let startupType = startupType {
            event["startup_type"] = startupType
        }
        
        if let startupTime = startupTime {
            event["startup_time"] = NSNumber(value: Int64(startupTime) as Int64)
        }

        if let openDuration = openDuration {
            event["open_duration"] = openDuration
        }
        
        return event
    }
    fileprivate func createEnvironmentEvent(_ device: String, language: String, extensionVersion: String, distVersion: String, hostVersion: String, osVersion: String, defaultSearchEngine: String, historyUrls: Int, historyDays: Int, prefs: [String: Any]) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "environment"
        event["device"] = device
        event["language"] = language
        event["version"] = extensionVersion
        event["version_dist"] = distVersion
        event["version_host"] = hostVersion
        event["os_version"] = osVersion
        event["defaultSearchEngine"] = defaultSearchEngine
        event["historyUrls"] = historyUrls
        event["historyDays"] = historyDays
        event["prefs"] = prefs
        
        return event
    }
    fileprivate func createNetworkStatusEvent(_ network: String, duration: Int) -> [String: Any]{
        var event = createBasicEvent()
        
        event["type"] = "network_status"
        event["network"] = network
        event["duration"] = duration
        
        return event
    }
    
    fileprivate func createQueryInteractionEvent(_ action: String, currentLength: Int) -> [String: Any]{
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = action
        event["current_length"] = currentLength
        
        return event
    }
    
    fileprivate func createOnboardingEvent(_ action: String, customData: [String: Any]?) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "onboarding"
        event["action"] = action
        
        if let customData = customData {
            for (key, value) in customData {
                event[key] = value
            }
        }
        return event
    }
    
    fileprivate func createNavigationEvent(_ action: String, step: Int, urlLength: Int, displayTime: Double) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "navigation"
        event["action"] = action
        event["step"] = step
        event["url_length"] = urlLength
        event["display_time"] = displayTime
        
        return event
    }
    
    fileprivate func createResultEnterEvent(_ queryLength: Int, autocompletedLength: Int, autocompletedUrl: String?, reactionTime: Double, urlbarTime: Double) -> [String: Any] {
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

    fileprivate func creatJavaScriptSignalEvent(_ javaScriptSignal: [String: Any]) -> [String: Any] {
        var event = javaScriptSignal
        
        event["session"] = self.sessionId
        event["seq"] = getNextTelemetrySeq()

        return event
    }

	fileprivate func createLocationServicesStatusEvent(_ action: String, status: String?) -> [String: Any]{
		var event = createBasicEvent()
		event["type"] = "location_access"
		event["action"] = action
		if let s = status {
			event["status"] = s
		}
		return event
	}
    
    fileprivate func createHomeScreenShortcutEvent(_ targetType: String, targetIndex: Int) -> [String: Any]{
        var event = createBasicEvent()
        event["type"] = "home_screen"
        event["action"] = "click"
        event["target_type"] = targetType
        event["target_index"] = targetIndex
        return event
    }
    
    fileprivate func createNewsNotificationEvent(_ action: String) -> [String: Any] {
        var event = createBasicEvent()
        event["type"] = "news_notification"
        event["action"] = action
        return event
    }
	
	fileprivate func createYoutubeVideoDownloaderEvent(_ action: String, statusKey: String, statusValue: String) -> [String: Any] {
		var event = createBasicEvent()
		event["type"] = "video_downloader"
		event["action"] = action
		event[statusKey] = statusValue
		return event
	}
    
    fileprivate func createSettingsEvent(_ view: String, action: String, target: String, state: String?, duration: Int?) -> [String: Any] {
        var event = createBasicEvent()
        event["type"] = "settings"
        event["view"] = view
        event["action"] = action
        event["target"] = target
        if let state = state {
            event["state"] = state
        }
        if let duration = duration {
            event["show_duration"] = duration
        }
        return event
    }
    
    fileprivate func createToolbarEvent(_ action: String, target: String, view: String, isForgetMode: Bool?, customData: [String: Any]?) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "toolbar"
        event["action"] = action
        event["target"] = target
        event["view"] = view
        
        if let isForgetMode = isForgetMode {
            event["is_forget"] = isForgetMode
        }
        
        if let customData = customData {
            for (key, value) in customData {
                event[key] = value
            }
        }
        
        return event
    }
    
    fileprivate func createKeyboardEvent(_ action: String, view: String, isForgetMode: Bool, showDuration: Int?) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "keyboard"
        event["action"] = action
        event["view"] = view
        event["is_forget"] = isForgetMode
        
        if let showDuration = showDuration {
            event["show _duration"] = showDuration
        }
        
        return event
    }
    
    fileprivate func createWebMenuEvent(_ action: String, target: String, isForgetMode: Bool) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "web_menu"
        event["action"] = action
        event["target"] = target
        event["is_forget"] = isForgetMode
        
        return event
    }
    
    fileprivate func createAntiPhishingEvent(_ action: String, target: String?, showDuration: Int?) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "anti_phishing"
        event["action"] = action
        if let target = target {
            event["target"] = target
        }
        
        if let showDuration = showDuration {
            event["show_duration"] = showDuration
        }
        return event
    }
    
    fileprivate func createShareMenuEvent(_ action: String, target: String) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "share_menu"
        event["action"] = action
        event["target"] = target

        return event
    }
    
    
    fileprivate func createDashBoardEvent(_ type: String, action: String, target: String?, customData: [String: Any]?) -> [String: Any] {
        var event = createBasicEvent()
    
        event["type"] = type
        event["action"] = action
        
        if let target = target {
            event["target"] = target
        }
        if let customData = customData {
            for (key, value) in customData {
                event[key] = value
            }
        }
        
        return event
    }
    
    
    fileprivate func createContextMenuEvent(_ target: String, view: String) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "context_menu"
        event["action"] = "click"
        event["target"] = target
        event["view"] = view
        
        return event
    }
    
    fileprivate func createQuerySuggestionsEvent(_ action: String, customData: [String: Any]?) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "query_suggestions"
        event["action"] = action
        
        if let customData = customData {
            for (key, value) in customData {
                event[key] = value
            }
        }
        
        return event
    }
    
    
    fileprivate func createControlCenterEvent(_ action: String, view: String?, target: String?, customData: [String: Any]?) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "control_center"
        event["action"] = action
        
        
        if let view = view {
            event["view"] = view
        }

        if let target = target {
            event["target"] = target
        }

        if let customData = customData {
            for (key, value) in customData {
                event[key] = value
            }
        }
        
        return event
    }
    
    private func createFreshTabEvent(_ action: String, target: String?, customData: [String: Any]?) -> [String: Any] {
        var event = createBasicEvent()
        
        event["type"] = "home"
        event["action"] = action
        
        if let target = target {
            event["target"] = target
        }
        
        if let customData = customData {
            for (key, value) in customData {
                event[key] = value
            }
        }
        return event
    }
    
    
}
