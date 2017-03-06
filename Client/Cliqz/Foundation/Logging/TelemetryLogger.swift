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
    case Environment        (String, String, String, String, String, String, String, Int, Int, [String: AnyObject])
    case Onboarding         (String, Int, Int?)
    case Navigation         (String, Int, Int, Double)
    case ResultEnter        (Int, Int, String?, Double, Double)
    case JavaScriptSignal   ([String: AnyObject])
	case LocationServicesStatus (String, String?)
    case HomeScreenShortcut (String, Int)
    case NewsNotification   (String)
	case YoutubeVideoDownloader	(String, String, String)
    case Settings (String, String, String, String?, Int?)
    case Toolbar            (String, String, String, Bool?, Int?)
    case Keyboard            (String, String, Bool, Int?)
    case WebMenu            (String, String, Bool)
    case Attrack            (String, String?, Int?)
    case AntiPhishing            (String, String?, Int?)
    case ShareMenu            (String, String)
    case DashBoard            (String, String, String?, [String: AnyObject]?)
    case ContextMenu            (String, String)
    case QuerySuggestions        (String, [String: AnyObject]?)
}


class TelemetryLogger : EventsLogger {
    
    let dispatchQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    
    private var isForgetModeActivate = false
    private let preventedTypesInForgetMode = ["home", "cards", "web", "web_menu", "context_menu", "share_menu", "attrack", "anti_phishing", "video_downloader"]
    private let preventedActionsInForgetMode = ["result_enter", "key_stroke", "keystroke_del", "paste", "results", "result_click"]
    
    //MARK: - Singltone
    static let sharedInstance = TelemetryLogger()
    
    init() {
        super.init(endPoint: "https://logging.cliqz.com")        
        loadTelemetrySeq()
    }
    
    func updateForgetModeStatue(newStatus: Bool) {
        dispatch_async(dispatchQueue) {[weak self] in
            self?.isForgetModeActivate = newStatus
        }
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
    
    //MARK: - Presisting events and sequence
    internal func persistState() {
        self.storeCurrentTelemetrySeq()
        self.persistEvents()
    }
    
    //MARK: - Log events
    internal func logEvent(eventType: TelemetryLogEventType){
        
        dispatch_async(dispatchQueue) {
            var event: [String: AnyObject]
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

            case .Onboarding(let action, let index, let duration):
                event = self.createOnboardingEvent(action, index: index, duration: duration)
               
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
                
            case .Toolbar(let action, let target, let view, let isForgetMode?, let customData):
                event = self.createToolbarEvent(action, target: target, view: view, isForgetMode: isForgetMode, customData: customData)
                
            case .Keyboard(let action, let view, let isForgetMode, let showDuration):event = self.createKeyboardEvent(action, view: view, isForgetMode: isForgetMode, showDuration: showDuration)
                // disable sending event when there is interaciton with keyboars
                disableSendingEvent = true
                
            case .WebMenu(let action, let target, let isForgetMode):
                event = self.createWebMenuEvent(action, target: target, isForgetMode: isForgetMode)
            
            case .Attrack(let action, let target, let customData):
                event = self.createAttrackEvent(action, target: target, customData: customData)
                
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
                
                
            default:
                return
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

    private func shouldPreventEventInForgetMode(event: [String: AnyObject]) -> Bool {
        if let type = event["type"] as? String
            where preventedTypesInForgetMode.contains(type) {
            return true
        }
        
        if let action = event["action"] as? String
            where preventedActionsInForgetMode.contains(action) {
            return true
        }
        
        return false
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

    
    private func createLifeCycleEvent(action: String, distVersion: String) -> [String: AnyObject]{
        var event = createBasicEvent()
        
        event["type"] = "activity"
        event["action"] = action
        event["version_dist"] = distVersion

        return event
    }
    private func createApplicationUsageEvent(action: String, network: String, battery: Int, memory: Double, startupType: String?, startupTime: Double?, openDuration: Double?) -> [String: AnyObject]{
        var event = createBasicEvent()

        event["type"] = "app_state_change"
        event["state"] = action
        event["network"] = network
        event["battery"] = battery
        event["memory"] = NSNumber(longLong: Int64(memory))

        if let startupType = startupType {
            event["startup_type"] = startupType
        }
        
        if let startupTime = startupTime {
            event["startup_time"] = NSNumber(longLong: Int64(startupTime))
        }

        if let openDuration = openDuration {
            event["open_duration"] = openDuration
        }
        
        return event
    }
    private func createEnvironmentEvent(device: String, language: String, extensionVersion: String, distVersion: String, hostVersion: String, osVersion: String, defaultSearchEngine: String, historyUrls: Int, historyDays: Int, prefs: [String: AnyObject]) -> [String: AnyObject] {
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
    
    private func createOnboardingEvent(action: String, index: Int, duration: Int?) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "onboarding"
        event["action"] = action
		event["version"] = "1.0"
        event["index"] = index
        
        if action == "click" {
           event["target"] = "next"
        }
        
        if let showduration = duration {
            event["show_duration"] = showduration
		}
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
    
    private func createNewsNotificationEvent(action: String) -> [String: AnyObject] {
        var event = createBasicEvent()
        event["type"] = "news_notification"
        event["action"] = action
        return event
    }
	
	private func createYoutubeVideoDownloaderEvent(action: String, statusKey: String, statusValue: String) -> [String: AnyObject] {
		var event = createBasicEvent()
		event["type"] = "video_downloader"
		event["action"] = action
		event[statusKey] = statusValue
		return event
	}
    
    private func createSettingsEvent(view: String, action: String, target: String, state: String?, duration: Int?) -> [String: AnyObject] {
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
    
    private func createToolbarEvent(action: String, target: String, view: String, isForgetMode: Bool?, customData: Int?) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "toolbar"
        event["action"] = action
        event["target"] = target
        event["view"] = view
        
        if let isForgetMode = isForgetMode {
            event["is_forget"] = isForgetMode
        }
        
        if let customData = customData where target == "overview" {
            event["open_tabs_count"] = customData
        } else if let customData = customData where target == "delete" {
            event["char_count"] = customData
        } else if let customData = customData where target == "attack" {
            event["tracker_count"] = customData
        } else if let customData = customData where target == "reader_mode" {
            event["state"] = customData == 1 ? "true" : "false"
        } else if let customData = customData where view == "overview" {
            event["show_duration"] = customData == 1 ? "true" : "false"
        }
        
        return event
    }
    
    private func createKeyboardEvent(action: String, view: String, isForgetMode: Bool, showDuration: Int?) -> [String: AnyObject] {
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
    
    private func createWebMenuEvent(action: String, target: String, isForgetMode: Bool) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "web_menu"
        event["action"] = action
        event["target"] = target
        event["is_forget"] = isForgetMode
        
        return event
    }
    
    private func createAttrackEvent(action: String, target: String?, customData: Int?) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "attrack"
        event["action"] = action
        if let target = target {
            event["target"] = target
            if let customData = customData where target == "info_company" {
                event["index"] = customData
            }
        }
        
        if let customData = customData where action == "hide" {
            event["show_duration"] = customData
        }
        
        return event
    }
    
    private func createAntiPhishingEvent(action: String, target: String?, showDuration: Int?) -> [String: AnyObject] {
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
    
    private func createShareMenuEvent(action: String, target: String) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "share_menu"
        event["action"] = action
        event["target"] = target

        return event
    }
    
    
    private func createDashBoardEvent(type: String, action: String, target: String?, customData: [String: AnyObject]?) -> [String: AnyObject] {
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
    
    
    private func createContextMenuEvent(target: String, view: String) -> [String: AnyObject] {
        var event = createBasicEvent()
        
        event["type"] = "context_menu"
        event["action"] = "click"
        event["target"] = target
        event["view"] = view
        
        return event
    }
    
    private func createQuerySuggestionsEvent(action: String, customData: [String: AnyObject]?) -> [String: AnyObject] {
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
    
}
