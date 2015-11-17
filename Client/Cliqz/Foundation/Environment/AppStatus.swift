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
    //TODO: use userdefined
    private func isReleasedVersion() -> Bool {
        let infoDict = NSBundle.mainBundle().infoDictionary;
        if let isRelease = infoDict!["Release"] {
            return isRelease.boolValue
        }
        return false
    }
    
    func getAppVersion(versionDescriptor: (version: String, buildNumber: String)) -> String {
        var version = "B-\(versionDescriptor.version.trim()) (\(versionDescriptor.buildNumber))"
        if isRelease {
            version = "\(versionDescriptor.version.trim()) (\(versionDescriptor.buildNumber))"
        }
        return version
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
    internal func appStarted(){
        NetworkReachability.sharedInstance.startMonitoring()
        
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
    
    
    internal func appDidBecomeActive(profile: Profile) {
        lastOpenedDate = NSDate()
        logApplicationUsageEvent("Active")
        logEnvironmentEventIfNecessary(profile)
    }
    internal func appDidBecomeInactive() {
        logApplicationUsageEvent("Inactive")
    }
    internal func appDidEnterBackground() {
        logApplicationUsageEvent("background")
        TelemetryLogger.sharedInstance.storeCurrentTelemetrySeq()
    }
    internal func appWillTerminate() {
        logApplicationUsageEvent("terminate")
        TelemetryLogger.sharedInstance.storeCurrentTelemetrySeq()
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
        dispatch_async(dispatchQueue) {
            var timeUsed = 0.0
            if let lastOpenedDate = self.lastOpenedDate {
                timeUsed = NSDate().timeIntervalSinceDate(lastOpenedDate) * 1000
            }
            let network = NetworkReachability.sharedInstance.networkReachabilityStatus?.description
            //TODO `context`
            let context = ""
            let battery = self.batteryLevel()
            
            TelemetryLogger.sharedInstance.logEvent(.ApplicationUsage(action, network!, context, battery, timeUsed))
            
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
            let language = NSLocale.preferredLanguages()[0]
            let version = self.getCurrentAppVersion()
            let defaultSearchEngine = profile.searchEngines.defaultEngine.shortName
            //TODO get history, and prefs
            let historyUrls = -1
            let historyDays = -1
            let prefs = [String: AnyObject]()

            print(device.rawValue)
            
            TelemetryLogger.sharedInstance.logEvent(TelemetryLogEventType.Environment(device.rawValue, language, version, defaultSearchEngine, historyUrls, historyDays, prefs))

        }
        
    }
    
}
