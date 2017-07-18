//
//  CIReminderManager.swift
//  Client
//
//  Created by Tim Palade on 6/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import UserNotifications

extension UILocalNotification {
    func isExpired() -> Bool {
        if self.fireDate?.compare(Date.init(timeIntervalSinceNow: 0)) == ComparisonResult.orderedDescending {
            return true
        }
        return false
    }
}

class CIReminderManager: NSObject {
    
    //ATTENTION ONLY 64 REMINDERS ARE ALLOWED
    
    //Copy is the set of all reminders that have not fired yet + reminders that have fired but were not pressed (viewed).
    //fired reminders are stored in user defaults
    //Add rule: 1. when a reminder is fired and not touched 2. on init, check expired reminders
    //Scenario to think about. App is dead. Reminder fires. It is pressed. App opens. Fired Reminders are built. The fired reminder that was pressed is expired and thus it will be added to the fired reminders. reminderPressed is called. reminder is removed from fired reminders.
    //3 stores: System, Copy, and Fired Reminders. Copy is a snapshot of the system reminders before the app is closed. 
    //Copy is used to find the reminders that fired while the app was dead. 
    //Fired reminders keeps track of all the reminders that have fired but were not opened.
    
    //Rules for Fired reminders
    //Add: When app opens and there are fired reminders
    //Add: When app is active, reminder fireed, but it is not pressed (use reminder fired in combination with reminder pressed)
    
    //TO DO:
    // 0. Write interface for read/write firedReminders and Copy.
    // 1. Test fired reminders - Here
    // 2. Make an api for it
    // 3. Link with React
    
    enum RemindersChanged {
        case True
        case False
        case Unknown
    }
    
    //these are reminders that were not pressed when triggered
    struct ReminderStruct: Equatable, Hashable {
        let url: String
        let date: Date
        var hashValue: Int {
            return url.hashValue ^ date.hashValue
        }
        static func == (lhs: ReminderStruct, rhs: ReminderStruct) -> Bool {
            return lhs.url == rhs.url && lhs.date == rhs.date
        }
        
        func dict() -> [String: Any] {
            return ["url":url, "date": date]
        }
    }
    
    typealias Reminder = [String : Any]
    typealias Host = String
    typealias Url  = String
    
    var didRemindersChange: RemindersChanged = .Unknown
    
    private var rem_cache: [Reminder] = []
    
    private var firedReminders: [ReminderStruct] = []
    
    //instead of a hashmap I could build a trie tree, where the first layer of nodes is host names, and then attached to them path components
    private var url_hash_map: [Host : [Url]] = [:]
    
    static let sharedInstance = CIReminderManager()
    
    private let copyKey = "CopyKey_1234"
    private let firedKey = "Fired_1234"
    
    override init() {
        super.init()
        url_hash_map = buildUrlHashMap(reminders: allValidReminders())
        firedReminders = loadFiredReminders()
        let new_fired_reminders = remindersFired()
        for reminder in new_fired_reminders {
            addToFiredReminders(reminder: reminder)
        }
    }
    
    deinit {
        saveState()
    }
    
    func saveState() {
        makeCopy()
        saveFiredReminders()
    }
    
    func remindersFired() -> Set<ReminderStruct> {
        //here have an interface for creating the reminders_defaults
        guard let reminders_system = UIApplication.shared.scheduledLocalNotifications else {return Set()}
        let fired_and_notfired = readCopy()
        let unfired = localNotifications2Set(notifications: reminders_system)
        return fired_and_notfired.subtracting(unfired)
    }
    
    func registerReminder(url: String, title: String, date: Date) {

        let userInfo = ["url": url, "title": title, "date": date, "isReminder": true] as [String : Any]
        
        let notification = UILocalNotification()
        notification.alertBody = "\(title) (Reminder)" // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = date // todo item due date (when notification will be fired) notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.userInfo = userInfo // assign a unique identifier to the notification so that we can retrieve it later
        
        UIApplication.shared.scheduleLocalNotification(notification)
        
        didRemindersChange = .True
        url_hash_map = addUrlToHashMap(map: url_hash_map, url_str: url)
        
    }
    
    func unregisterReminder(url: String, title: String, date: Date) {
        
        if let notifications = UIApplication.shared.scheduledLocalNotifications {
            for notification in notifications {
                if let dict = notification.userInfo {
                    if (dict["url"] as? String) == url && (dict["title"] as? String) == title && (dict["date"] as? Date) == date {
                        self.unregisterReminder(reminder: notification)
                        break
                    }
                }
            }
        }
        
    }
    
    func unregisterReminder(reminder: UILocalNotification) {
        
        UIApplication.shared.cancelLocalNotification(reminder)
        if let url = reminder.userInfo?["url"] as? String {
            url_hash_map = removeUrlFromHashMap(map: url_hash_map, url_str: url)
            //remove from Copy
            removeFromFiredReminders(url: url)
        }
        
    }
    
    func remindersWith(url: String, title: String? = nil) -> [UILocalNotification] {
        
        var array: [UILocalNotification] = []
        
        if let notifications = UIApplication.shared.scheduledLocalNotifications {
            for notification in notifications {
                if let dict = notification.userInfo {
                    if let title = title{
                        if (dict["url"] as? String) == url && (dict["title"] as? String) == title {
                            array.append(notification)
                        }
                    }
                    else if (dict["url"] as? String) == url {
                        array.append(notification)
                    }
                }
            }
        }
        
        return array
    }
    
    
    func allValidReminders() -> [Reminder] {
        
        //Caching mechanism
        //There are 2 ways reminders are modified:
        //Added when registered
        //Removed when they fire
        //Keep a cache of all reminders, and a flag "didRemindersChange"
        //if didRemindersChange == false return cache, else query
        
        if didRemindersChange == .False {
            return rem_cache
        }

        if let notifications = UIApplication.shared.scheduledLocalNotifications {
            let reminders = notifications.map({ (notification) -> Reminder in
                return notification.userInfo as! Reminder
            })
            rem_cache = reminders
            didRemindersChange = .False
            return reminders
        }
        else {
            return []
        }

    }
    
    func isUrlRegistered(url_str: Url) -> Bool {
        if let host = URL(string: url_str)?.host {
            if let array = url_hash_map[host] {
                if array.contains(url_str) {
                    return true
                }
            }
        }
        return false
    }
    
    func reminderFired(url_str: String, date: Date?) {
        //add to FiredReminders
        addToFiredReminders(url: url_str, date: date ?? Date())
    }
    
    func reminderPressed(url_str: String) {
        url_hash_map = removeUrlFromHashMap(map: url_hash_map, url_str: url_str)
        //remove from FiredReminders
        removeFromFiredReminders(url: url_str)
    }
    
    private func buildUrlHashMap(reminders: [Reminder]) -> [Host : [Url]] {
        
        var return_dict: [Host : [Url]] = [:]
        for reminder in reminders {
            let url_str = reminder["url"] as! String
            return_dict = addUrlToHashMap(map: return_dict, url_str: url_str)
        }
        
        return return_dict
    }
    
    private func addUrlToHashMap(map: [Host : [Url]], url_str: Url) -> [Host:[Url]] {
        
        var map_copy = map
        
        if let url = URL(string: url_str), let host = url.host {
            if var array = map_copy[host] {
                array.append(url_str)
                map_copy[host] = array
            }
            else {
                map_copy[host] = [url_str]
            }
        }
        else {
            //this is an invalid url. We ignore it
        }
        
        return map_copy
        
    }
    
    private func removeUrlFromHashMap(map: [Host : [Url]], url_str: Url) -> [Host:[Url]] {
        
        var map_copy = map
        
        //delete just the first instance of the url. There might be multiple instances of the same url in the array.
        if let url = URL(string: url_str), let host = url.host {
            if var array = map_copy[host] {
                for i in 0..<array.count {
                    let url_array = array[i]
                    if url_array == url_str {
                        array.remove(at: i)
                        break
                    }
                }
                if array.isEmpty {
                    map_copy[host] = nil
                }
                else {
                    map_copy[host] = array
                }

            }
            else {
                //since the host is not here, the url is not either. Nothing to remove.
            }
        }
        else {
            //this is an invalid url. We ignore it.
            //this is fine since we do not add invalid urls in the first place.
        }
        
        return map_copy
        
    }
    
    private func loadFiredReminders() -> [ReminderStruct] {
        
        func transformToReminders(array:[[String: Any]]) -> [ReminderStruct] {
            var ret_array:[ReminderStruct] = []
            for elem in array {
                if let url = elem["url"] as? String, let date = elem["date"] as? Date {
                    ret_array.append(ReminderStruct(url: url, date: date))
                }
            }
            return ret_array
        }
        
        if let array = UserDefaults.standard.value(forKey: firedKey) as? [[String:Any]] {
            return transformToReminders(array: array)
        }
        return []
    }
    
    //TO DO: interface for fired reminders
    private func saveFiredReminders(){
        
        func tansformReminders(reminders: [ReminderStruct]) -> [[String: Any]] {
            var array: [[String: Any]] = []
            for reminder in reminders {
                let date = reminder.date
                let url = reminder.url
                array.append(["url":url, "date":date])
            }
            return array
        }
        
        UserDefaults.standard.set(tansformReminders(reminders: firedReminders), forKey: firedKey)
        UserDefaults.standard.synchronize()
    }
    
    private func addToFiredReminders(url: String, date: Date) {
        addToFiredReminders(reminder: ReminderStruct(url: url, date: date))
    }
    
    private func addToFiredReminders(reminder: ReminderStruct) {
        firedReminders.append(reminder)
    }
    
    private func removeFromFiredReminders(url: String) {
        //the url is the unique identifier. Only one reminder per url.
        var index = 0
        for reminder in firedReminders {
            if reminder.url == url {
                firedReminders.remove(at: index)
                break
            }
            index = index + 1
        }
    }
    
    private func localNotifications2Set(notifications: [UILocalNotification]) -> Set<ReminderStruct> {
        var set: Set<ReminderStruct> = Set.init()
        for notification in notifications {
            if let date = notification.fireDate, let url = notification.userInfo?["url"] as? String {
                set.insert(ReminderStruct(url: url, date: date))
            }
        }
        return set
    }
    
//    private func localNotifications2Set(notifications: [UILocalNotification]) -> Set<[String: Any]> {
//        var set: Set<[String: Any]> = Set.init()
//        for notification in notifications {
//            if let date = notification.fireDate, let url = notification.userInfo?["url"] as? String {
//                set.insert(["url":url, "date":date])
//            }
//        }
//        return set
//    }
    
    private func makeCopy() {
        func tansformNotifications(notifications: [UILocalNotification]) -> [[String: Any]] {
            var array: [[String: Any]] = []
            for notification in notifications {
                if let date = notification.fireDate, let url = notification.userInfo?["url"] as? String {
                    array.append(["url":url, "date":date])
                }
            }
            return array
        }
        
        guard let notifications = UIApplication.shared.scheduledLocalNotifications else {return}
        let array = tansformNotifications(notifications: notifications)
        UserDefaults.standard.set(array, forKey: copyKey)
        UserDefaults.standard.synchronize()
    }
    
    private func readCopy() -> Set<ReminderStruct>{
        guard let array = UserDefaults.standard.value(forKey: copyKey) as? [[String: Any]] else {return Set()}
        var set: Set<ReminderStruct> = Set()
        for elem in array {
            if let url = elem["url"] as? String, let date = elem["date"] as? Date {
                set.insert(ReminderStruct(url: url, date: date))
            }
        }
        return set
    }
}

