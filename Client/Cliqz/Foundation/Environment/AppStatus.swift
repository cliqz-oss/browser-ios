//
//  AppStatus.swift
//  Client
//
//  Created by Mahmoud Adam on 11/12/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation
import Crashlytics

class AppStatus {

    //MARK constants
    let versionDescriptorKey = "VersionDescriptor"
    let buildNumberDescriptorKey = "BuildNumberDescriptor"
    let dispatchQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
    
    
    //MARK Instance variables
    var versionDescriptor: (String, String)?
    var lastOpenedDate: Date?
    var lastEnvironmentEventDate: Date?
    
    lazy var extensionVersion: String = {
        
        if let path = Bundle.main.path(forResource: "cliqz", ofType: "json", inDirectory: "Extension/build/mobile/search"),
            let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) as Data,
            let jsonResult: NSDictionary = try! JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
            
                if let extensionVersion : String = jsonResult["EXTENSION_VERSION"] as? String {
                    return extensionVersion
                }
        }
        return ""
    }()
    
    lazy var distVersion: String = {
        let versionDescription = self.getVersionDescriptor()
        return self.getAppVersion(versionDescription)
    }()
    
    lazy var hostVersion: String = {
        // Firefox version
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
            let infoDict = NSDictionary(contentsOfFile: path),
            let hostVersion = infoDict["HostVersion"] as? String {
                return hostVersion
        }
        return ""
    }()
    
    func isRelease() -> Bool {
        #if BETA
            return false
        #else
            return true
        #endif
    }
    
    func isDebug() -> Bool {
        return _isDebugAssertConfiguration()
    }
    
    func getAppVersion(_ versionDescriptor: (version: String, buildNumber: String)) -> String {
            return "\(versionDescriptor.version.trim()) (\(versionDescriptor.buildNumber))"
    }
    
    func batteryLevel() -> Int {
        return Int(UIDevice.current.batteryLevel * 100)
    }

    //MARK: - Singltone
    static let sharedInstance = AppStatus()

    fileprivate init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    //MARK:- pulbic interface
    internal func appWillFinishLaunching() {
        
        lastOpenedDate = Date()
        NetworkReachability.sharedInstance.startMonitoring()
        
    }

    internal func appDidFinishLaunching() {
        
        dispatchQueue.async {
            
            let (version, buildNumber) = self.getVersionDescriptor()
            if let (storedVersion, storedBuildNumber) = self.loadStoredVersionDescriptor() {
                
                if version > storedVersion || buildNumber > storedBuildNumber {
                    // new update
                    self.logLifeCycleEvent("update")
                }
                
            } else {
                // new Install
                self.logLifeCycleEvent("install")
            }
            
            //store current version descriptor
            self.updateVersionDescriptor((version, buildNumber))
        }
    }
    
    internal func appWillEnterForeground() {
        
        SessionState.sessionResumed()
        lastOpenedDate = Date()
    }
    
    internal func appDidBecomeActive(_ profile: Profile) {
        
        NetworkReachability.sharedInstance.refreshStatus()
        logApplicationUsageEvent("Active")
        logEnvironmentEventIfNecessary(profile)

    }
    
    internal func appDidBecomeResponsive(_ startupType: String) {
        let startupTime = Date.milliSecondsSinceDate(lastOpenedDate)
        logApplicationUsageEvent("Responsive", startupType: startupType, startupTime: startupTime, openDuration: nil)
    }
    
    internal func appWillResignActive() {
        
        let openDuration = Date.milliSecondsSinceDate(lastOpenedDate)
        logApplicationUsageEvent("Inactive", startupType:nil, startupTime: nil, openDuration: openDuration)
        NetworkReachability.sharedInstance.logNetworkStatusEvent()
        
        TelemetryLogger.sharedInstance.persistState()
        
    }
    
    internal func appDidEnterBackground() {
        SessionState.sessionPaused()
        
        let openDuration = Date.milliSecondsSinceDate(lastOpenedDate)
        logApplicationUsageEvent("Background", startupType:nil, startupTime: nil, openDuration: openDuration)

        TelemetryLogger.sharedInstance.appDidEnterBackground()

        NewsNotificationPermissionHelper.sharedInstance.onAppEnterBackground()
	}

    internal func appWillTerminate() {
        
        logApplicationUsageEvent("Terminate")
        
        TelemetryLogger.sharedInstance.persistState()
    }
    
    //MARK:- Private Helper Methods
    //MARK: VersionDescriptor
    fileprivate func getVersionDescriptor() -> (version: String, buildNumber: String) {

        var version = "0"
        var buildNumber = "0"
        
        if let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            version = shortVersion
        }
        if let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            buildNumber = bundleVersion
        }
        
        return (version, buildNumber)
    }
    
    fileprivate func loadStoredVersionDescriptor() -> (version: String, buildNumber: String)? {
        
        if let storedVersion = LocalDataStore.objectForKey(self.versionDescriptorKey) as? String {
            if let storedBuildNumber = LocalDataStore.objectForKey(self.buildNumberDescriptorKey) as? String {
                return (storedVersion, storedBuildNumber)

            }
        }
        // otherwise return nil
        return nil
    }
    
    fileprivate func updateVersionDescriptor(_ versionDescriptor: (version: String, buildNumber: String)) {
        self.versionDescriptor = versionDescriptor
        LocalDataStore.setObject(versionDescriptor.version, forKey: self.versionDescriptorKey)
        LocalDataStore.setObject(versionDescriptor.buildNumber, forKey: self.buildNumberDescriptorKey)
    }
    
    //MARK: application life cycle event
    fileprivate func logLifeCycleEvent(_ action: String) {
        TelemetryLogger.sharedInstance.logEvent(.LifeCycle(action, distVersion))
    }
    
    //MARK: application usage event
    
    fileprivate func logApplicationUsageEvent(_ action: String) {
        logApplicationUsageEvent(action, startupType: nil, startupTime: nil, openDuration: nil)
    }
    
    fileprivate func logApplicationUsageEvent(_ action: String, startupType: String?, startupTime: Double?, openDuration: Double?) {
        dispatchQueue.async {
            let network = NetworkReachability.sharedInstance.networkReachabilityStatus?.description
            let battery = self.batteryLevel()
            let memory = self.getMemoryUsage()
            
            TelemetryLogger.sharedInstance.logEvent(TelemetryLogEventType.ApplicationUsage(action, network!, battery, memory, startupType, startupTime, openDuration))
        }
    }
    //MARK: application Environment event
    fileprivate func logEnvironmentEventIfNecessary(_ profile: Profile) {
        if let lastdate = lastEnvironmentEventDate {
            let timeSinceLastEvent = Date().timeIntervalSince(lastdate)
            if timeSinceLastEvent < 3600 {
                //less than an hour since last sent event
                return
            }
        }
        
        dispatchQueue.async {
            self.lastEnvironmentEventDate = Date()
            let device: String = UIDevice.current.modelName
            let language = self.getAppLanguage()
            let extensionVersion = self.extensionVersion
            let distVersion = self.distVersion
            let hostVersion = self.hostVersion
            let osVersion = UIDevice.current.systemVersion
            let defaultSearchEngine = profile.searchEngines.defaultEngine.shortName
            let historyUrls = profile.history.count()
            let historyDays = self.getHistoryDays(profile)
            //TODO `prefs`
            let prefs = self.getEnvironmentPrefs(profile)
            
            TelemetryLogger.sharedInstance.logEvent(TelemetryLogEventType.Environment(device, language, extensionVersion, distVersion, hostVersion, osVersion, defaultSearchEngine, historyUrls, historyDays, prefs))

        }
    }
    fileprivate func getEnvironmentPrefs(_ profile: Profile) -> [String: AnyObject] {
        var prefs = [String: AnyObject]()
        prefs["block_popups"] = SettingsPrefs.getBlockPopupsPref() as AnyObject?
        prefs["block_explicit"] = SettingsPrefs.getBlockExplicitContentPref() as AnyObject?
        prefs["block_ads"] = SettingsPrefs.getAdBlockerPref() as AnyObject?
        prefs["fair_blocking"] = SettingsPrefs.getFairBlockingPref() as AnyObject?
        prefs["human_web"] = SettingsPrefs.getHumanWebPref() as AnyObject?
        prefs["country"]   = SettingsPrefs.getDefaultRegion() as AnyObject?
        if let abTests = ABTestsManager.getABTests(), JSONSerialization.isValidJSONObject(abTests) {
            do {
                let data = try JSONSerialization.data(withJSONObject: abTests, options: [])
                let stringifiedAbTests = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
                prefs["ABTests"]   = stringifiedAbTests
            } catch let error as NSError {
                Answers.logCustomEvent(withName: "stringifyABTests", customAttributes: ["error": error.localizedDescription])
            }
        }
        
        return prefs
    }
    fileprivate func getAppLanguage() -> String {
        let languageCode = (Locale.current as NSLocale).object(forKey: .countryCode)
        let countryCode = (Locale.current as NSLocale).object(forKey: .countryCode)
        return "\(languageCode!)-\(countryCode!)"
    }
    
    fileprivate func getHistoryDays(_ profile: Profile) -> Int {
        var historyDays = 0
        if let oldestVisitDate = profile.history.getOldestVisitDate() {
            historyDays = Date().daysSinceDate(oldestVisitDate)
        }
        return historyDays
    }
    
    func getMemoryUsage()-> Double {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info))/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
			$0.withMemoryRebound(to: integer_t.self, capacity: 1) {
				task_info(mach_task_self_,
					task_flavor_t(TASK_BASIC_INFO),
					$0,
					&count)
			}
        }
        
        if kerr == KERN_SUCCESS {
            let memorySize = Double(info.resident_size) / 1048576.0
            return memorySize
        }
        else {
            return -1
        }
    }
    
    
}
