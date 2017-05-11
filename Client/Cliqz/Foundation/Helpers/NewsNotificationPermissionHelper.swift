//
//  NewsNotificationPermissionHelper.swift
//  Client
//
//  Created by Mahmoud Adam on 5/27/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class NewsNotificationPermissionHelper: NSObject {
    
    //MARK: - Constants
    fileprivate let minimumNumberOfOpenings = 4
    fileprivate let minimumNumberOfDays     = 8
    
    fileprivate let askedBeforeKey          = "askedBefore"
    fileprivate let lastAskDayKey           = "lastAskDay"
    fileprivate let disableAskingKey        = "disableAsking"
    fileprivate let newInstallKey           = "newInstall"
    fileprivate let installDayKey           = "installDay"
    fileprivate let numberOfOpeningsKey     = "numberOfOpenings"
    
    fileprivate var askingDisabled: Bool?
    //MARK: - Singltone & init
    static let sharedInstance = NewsNotificationPermissionHelper()
    
    
    //MARK: - Public APIs
    
    func onAppEnterBackground() {
        return
		// TODO: Commented till push notifications will be available
		/*
        let numberOfOpenings = getNumerOfOpenings()
        LocalDataStore.setObject(numberOfOpenings + 1, forKey: numberOfOpeningsKey)
        askingDisabled = LocalDataStore.objectForKey(disableAskingKey) as? Bool
		*/
    }
    
    func onAskForPermission() {
        LocalDataStore.setObject(true, forKey: askedBeforeKey)
        LocalDataStore.setObject(0, forKey: numberOfOpeningsKey)
        LocalDataStore.setObject(Date.getDay(), forKey: lastAskDayKey)
        
    }
    
    func isAksedForPermissionBefore() -> Bool {
        guard let askedBefore = LocalDataStore.objectForKey(askedBeforeKey) as? Bool else {
            return false
        }
        return askedBefore
    }
    
    func disableAskingForPermission () {
        askingDisabled = true
        LocalDataStore.setObject(askingDisabled, forKey: disableAskingKey)
    }
    
    func isAskingForPermissionDisabled () -> Bool {
        guard let isDisabled = askingDisabled else {
            return false
        }
        
        return isDisabled
    }
    
    func shouldAskForPermission() -> Bool {
        return false

		// TODO: Commented till push notifications will be available
		/*
        if isAskingForPermissionDisabled() || UIApplication.sharedApplication().isRegisteredForRemoteNotifications()  {
            return false
        }
        
        var shouldAskForPermission = true
        
        if isNewInstall() || isAksedForPermissionBefore() {
            if getNumberOfDaysSinceLastAction() < minimumNumberOfDays || getNumerOfOpenings() < minimumNumberOfOpenings {
                shouldAskForPermission = false
            }
        }
        
        return shouldAskForPermission
		*/
    }
    
    
    func enableNewsNotifications() {
        let notificationSettings = UIUserNotificationSettings(types: [UIUserNotificationType.badge, UIUserNotificationType.sound, UIUserNotificationType.alert], categories: nil)
        UIApplication.shared.registerForRemoteNotifications()
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        TelemetryLogger.sharedInstance.logEvent(.NewsNotification("enable"))
    }
    
    func disableNewsNotifications() {
        UIApplication.shared.unregisterForRemoteNotifications()
        TelemetryLogger.sharedInstance.logEvent(.NewsNotification("disalbe"))
    }
    
    //MARK: - Private APIs
    fileprivate func isNewInstall() -> Bool {
        var isNewInstall = false
        
        // check if it is calcualted before
        if let isNewInstall = LocalDataStore.objectForKey(newInstallKey) as? Bool {
            return isNewInstall;
        }
        
        // compare today's day with install day to determine whether it is update or new install
        let todaysDay = Date.getDay()
        if let installDay = TelemetryLogger.sharedInstance.getInstallDay(), todaysDay == installDay {
            isNewInstall = true
            LocalDataStore.setObject(todaysDay, forKey: installDayKey)
        }
        
        LocalDataStore.setObject(isNewInstall, forKey: newInstallKey)
        
        return isNewInstall
    }
    
    fileprivate func getNumberOfDaysSinceLastAction() -> Int {
        
        if isNewInstall() && !isAksedForPermissionBefore() {
            return getNumberOfDaysSinceInstall()
        } else {
            return getNumberOfDaysSinceLastAsk()
        }
    }
    
    fileprivate func getNumberOfDaysSinceInstall() -> Int {
        
        guard let installDay = LocalDataStore.objectForKey(installDayKey) as? Int else {
            return 0
        }
        
        let daysSinceInstal = Date.getDay() - installDay
        return daysSinceInstal
    }
    
    
    fileprivate func getNumberOfDaysSinceLastAsk() -> Int {
        
        guard let lastAskDay = LocalDataStore.objectForKey(lastAskDayKey) as? Int else {
            return 0
        }
        
        let daysSinceLastAsk = Date.getDay() - lastAskDay
        return daysSinceLastAsk
    }
    
    fileprivate func getNumerOfOpenings() -> Int {
        guard let numberOfOpenings = LocalDataStore.objectForKey(numberOfOpeningsKey) as? Int else {
            return 0
        }
        return numberOfOpenings
    }
}
