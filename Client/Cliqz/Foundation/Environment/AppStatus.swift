//
//  AppStatus.swift
//  Client
//
//  Created by Mahmoud Adam on 11/12/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation

class AppStatus {

    //MARK constants
    let versionDescriptorKey = "VersionDescriptor"
    let buildNumberDescriptorKey = "BuildNumberDescriptor"
    let dispatchQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    
    
    //MARK Instance variables
    var versionDescriptor: (String, String)?
    var lastOpenedDate: NSDate?
    var lastEnvironmentEventDate: NSDate?
    
    lazy var isRelease: Bool  = self.isReleasedVersion()
    lazy var isDebug: Bool  = false//_isDebugAssertConfiguration()
    
    private func isReleasedVersion() -> Bool {
//        let infoDict = NSBundle.mainBundle().infoDictionary;
//        if let isRelease = infoDict!["Release"] {
//            return isRelease.boolValue
//        }
//        return false
        return true
    }
    
    func getAppVersion(versionDescriptor: (version: String, buildNumber: String)) -> String {
            return "\(versionDescriptor.version.trim()) (\(versionDescriptor.buildNumber))"
    }

	func getCurrentAppVersion() -> String {
        return getAppVersion(getVersionDescriptor())
    }

    func batteryLevel() -> Float {
        return UIDevice.currentDevice().batteryLevel
    }

    //MARK: - Singltone
    static let sharedInstance = AppStatus()

    private init() {
        UIDevice.currentDevice().batteryMonitoringEnabled = true
    }

    //MARK:- pulbic interface
    internal func appWillFinishLaunching() {
		TelemetryLogger.sharedInstance.logEvent(.AppStateChange("will_finish_launch"))
        
        lastOpenedDate = NSDate()
        NetworkReachability.sharedInstance.startMonitoring()
        
    }

    internal func appDidFinishLaunching() {
        TelemetryLogger.sharedInstance.logEvent(.AppStateChange("did_finish_launch"))
        
        dispatch_async(dispatchQueue) {
            
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
        
        TelemetryLogger.sharedInstance.logEvent(.AppStateChange("will_enter_foreground"))
        
        lastOpenedDate = NSDate()
    }
    
    internal func appDidBecomeActive(profile: Profile) {
        TelemetryLogger.sharedInstance.logEvent(.AppStateChange("did_become_active"))
        
        NetworkReachability.sharedInstance.refreshStatus()
        logApplicationUsageEvent("Active")
        logEnvironmentEventIfNecessary(profile)
        
         dispatch_async(dispatchQueue) {
            // Alter Visits Table to add `favorite` column if it does not exit
            profile.history.alterVisitsTableAddFavoriteColumn()
        }
    }
    
    internal func appDidBecomeResponsive(startupType: String) {
        let startupTime = NSDate.milliSecondsSinceDate(lastOpenedDate)
        logApplicationUsageEvent("Responsive", startupType: startupType, startupTime: startupTime, timeUsed: nil)
    }
    
    internal func appWillResignActive() {
        TelemetryLogger.sharedInstance.logEvent(.AppStateChange("will_resign_active"))
        
        logApplicationUsageEvent("Inactive")
        NetworkReachability.sharedInstance.logNetworkStatusEvent()
    }
    
    internal func appDidEnterBackground() {
        SessionState.sessionPaused()
        
        TelemetryLogger.sharedInstance.logEvent(.AppStateChange("did_enter_background"))
        
        let timeUsed = NSDate.milliSecondsSinceDate(lastOpenedDate)
        logApplicationUsageEvent("Background", startupType:nil, startupTime: nil, timeUsed: timeUsed)
        TelemetryLogger.sharedInstance.storeCurrentTelemetrySeq()
        TelemetryLogger.sharedInstance.persistEvents()
	}

    internal func appWillTerminate() {
        TelemetryLogger.sharedInstance.logEvent(.AppStateChange("will_terminate"))
        
        logApplicationUsageEvent("Terminate")
    }
    
    //MARK:- Private Helper Methods
    //MARK: VersionDescriptor
    private func getVersionDescriptor() -> (version: String, buildNumber: String) {

        var version = "0"
        var buildNumber = "0"
        
        if let shortVersion = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            version = shortVersion
        }
        if let bundleVersion = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
            buildNumber = bundleVersion
        }
        
        return (version, buildNumber)
    }
    
    private func loadStoredVersionDescriptor() -> (version: String, buildNumber: String)? {
        
        if let storedVersion = LocalDataStore.objectForKey(self.versionDescriptorKey) as? String {
            if let storedBuildNumber = LocalDataStore.objectForKey(self.buildNumberDescriptorKey) as? String {
                return (storedVersion, storedBuildNumber)

            }
        }
        // otherwise return nil
        return nil
    }
    
    private func updateVersionDescriptor(versionDescriptor: (version: String, buildNumber: String)) {
        self.versionDescriptor = versionDescriptor
        LocalDataStore.setObject(versionDescriptor.version, forKey: self.versionDescriptorKey)
        LocalDataStore.setObject(versionDescriptor.buildNumber, forKey: self.buildNumberDescriptorKey)
    }
    
    //MARK: application life cycle event
    private func logLifeCycleEvent(action: String) {
        let version = getCurrentAppVersion()
        TelemetryLogger.sharedInstance.logEvent(.LifeCycle(action, version))
    }
    
    //MARK: application usage event
    
    private func logApplicationUsageEvent(action: String) {
        logApplicationUsageEvent(action, startupType: nil, startupTime: nil, timeUsed: nil)
    }
    
    private func logApplicationUsageEvent(action: String, startupType: String?, startupTime: Double?, timeUsed: Double?) {
        dispatch_async(dispatchQueue) {
            let network = NetworkReachability.sharedInstance.networkReachabilityStatus?.description
            let battery = self.batteryLevel()
            let memory = self.getMemoryUsage()
            //TODO `context`
            let context = ""
            
            TelemetryLogger.sharedInstance.logEvent(.ApplicationUsage(action, network!, context, battery, memory, startupType, startupTime, timeUsed))
            
        }
    }
    //MARK: application Environment event
    private func logEnvironmentEventIfNecessary(profile: Profile) {
        if let lastdate = lastEnvironmentEventDate {
            let timeSinceLastEvent = NSDate().timeIntervalSinceDate(lastdate)
            if timeSinceLastEvent < 3600 {
                //less than an hour since last sent event
                return
            }
        }
        
        dispatch_async(dispatchQueue) {
            self.lastEnvironmentEventDate = NSDate()
            let device: Model = UIDevice.currentDevice().deviceType
            let language = self.getAppLanguage()
            let version = self.getCurrentAppVersion()
            let osVersion = UIDevice.currentDevice().systemVersion
            let defaultSearchEngine = profile.searchEngines.defaultEngine.shortName
            let historyUrls = profile.history.count()
            let historyDays = self.getHistoryDays(profile)
            //TODO `prefs`
            let prefs = [String: AnyObject]()
            
            TelemetryLogger.sharedInstance.logEvent(TelemetryLogEventType.Environment(device.rawValue, language, version, osVersion, defaultSearchEngine, historyUrls, historyDays, prefs))

        }
    }
    
    private func getAppLanguage() -> String {
        let languageCode = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode)
        let countryCode = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode)
        return "\(languageCode!)-\(countryCode!)"
    }
    
    private func getHistoryDays(profile: Profile) -> Int {
        var historyDays = 0
        if let oldestVisitDate = profile.history.getOldestVisitDate() {
            historyDays = NSDate().daysSinceDate(oldestVisitDate)
        }
        return historyDays
    }
    
    func getMemoryUsage()-> Double {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(sizeofValue(info))/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(&info) {
            
            task_info(mach_task_self_,
                task_flavor_t(TASK_BASIC_INFO),
                task_info_t($0),
                &count)
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
