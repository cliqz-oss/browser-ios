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
    
    lazy var extensionVersion: String = {
        
        if let path = NSBundle.mainBundle().pathForResource("cliqz", ofType: "json", inDirectory: "Extension/build/mobile/search"),
            let jsonData = try? NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe) as NSData,
            let jsonResult: NSDictionary = try! NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
            
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
        if let path = NSBundle.mainBundle().pathForResource("Info", ofType: "plist"),
            let infoDict = NSDictionary(contentsOfFile: path),
            let hostVersion = infoDict["HostVersion"] as? String {
                return hostVersion
        }
        return ""
    }()
    
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
    
    func batteryLevel() -> Int {
        return Int(UIDevice.currentDevice().batteryLevel * 100)
    }

    //MARK: - Singltone
    static let sharedInstance = AppStatus()

    private init() {
        UIDevice.currentDevice().batteryMonitoringEnabled = true
    }

    //MARK:- pulbic interface
    internal func appWillFinishLaunching() {
        
        lastOpenedDate = NSDate()
        NetworkReachability.sharedInstance.startMonitoring()
        
    }

    internal func appDidFinishLaunching() {
        
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
        lastOpenedDate = NSDate()
    }
    
    internal func appDidBecomeActive(profile: Profile) {
        
        NetworkReachability.sharedInstance.refreshStatus()
        logApplicationUsageEvent("Active")
        logEnvironmentEventIfNecessary(profile)

    }
    
    internal func appDidBecomeResponsive(startupType: String) {
        let startupTime = NSDate.milliSecondsSinceDate(lastOpenedDate)
        logApplicationUsageEvent("Responsive", startupType: startupType, startupTime: startupTime, openDuration: nil)
    }
    
    internal func appWillResignActive() {
        
        let openDuration = NSDate.milliSecondsSinceDate(lastOpenedDate)
        logApplicationUsageEvent("Inactive", startupType:nil, startupTime: nil, openDuration: openDuration)
        NetworkReachability.sharedInstance.logNetworkStatusEvent()
        
        TelemetryLogger.sharedInstance.persistState()
        
    }
    
    internal func appDidEnterBackground() {
        SessionState.sessionPaused()
        
        let openDuration = NSDate.milliSecondsSinceDate(lastOpenedDate)
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
        TelemetryLogger.sharedInstance.logEvent(.LifeCycle(action, extensionVersion, distVersion, hostVersion))
    }
    
    //MARK: application usage event
    
    private func logApplicationUsageEvent(action: String) {
        logApplicationUsageEvent(action, startupType: nil, startupTime: nil, openDuration: nil)
    }
    
    private func logApplicationUsageEvent(action: String, startupType: String?, startupTime: Double?, openDuration: Double?) {
        dispatch_async(dispatchQueue) {
            let network = NetworkReachability.sharedInstance.networkReachabilityStatus?.description
            let battery = self.batteryLevel()
            let memory = self.getMemoryUsage()
            
            TelemetryLogger.sharedInstance.logEvent(TelemetryLogEventType.ApplicationUsage(action, network!, battery, memory, startupType, startupTime, openDuration))
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
            let device: String = UIDevice.currentDevice().deviceType
            let language = self.getAppLanguage()
            let extensionVersion = self.extensionVersion
            let distVersion = self.distVersion
            let hostVersion = self.hostVersion
            let osVersion = UIDevice.currentDevice().systemVersion
            let defaultSearchEngine = profile.searchEngines.defaultEngine.shortName
            let historyUrls = profile.history.count()
            let historyDays = self.getHistoryDays(profile)
            //TODO `prefs`
            let prefs = self.getEnvironmentPrefs(profile)
            
            TelemetryLogger.sharedInstance.logEvent(TelemetryLogEventType.Environment(device, language, extensionVersion, distVersion, hostVersion, osVersion, defaultSearchEngine, historyUrls, historyDays, prefs))

        }
    }
    private func getEnvironmentPrefs(profile: Profile) -> [String: AnyObject] {
        var prefs = [String: AnyObject]()
        prefs["block_popups"] = profile.prefs.boolForKey("blockPopups")
        prefs["block_explicit"] = SettingsPrefs.getBlockExplicitContentPref()
        prefs["block_ads"] = SettingsPrefs.getAdBlockerPref()
        prefs["fair_blocking"] = SettingsPrefs.getFairBlockingPref()
        prefs["human_web"] = SettingsPrefs.getHumanWebPref()
        prefs["clear_on_exit"] = SettingsPrefs.getClearDataOnTerminatingPref()
        
        return prefs
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
