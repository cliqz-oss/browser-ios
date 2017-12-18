//
//  CIReminderManager.swift
//  Client
//
//  Created by Tim Palade on 6/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import UserNotifications
import Shared

final class CIReminderManager: NSObject {
    
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
    //Add: When app is active, reminder fired, but it is not pressed (use reminder fired in combination with reminder pressed)
    
    //I would like to get the fired reminders by host.
    
    //TO DO:
    // 0. Write interface for read/write firedReminders and Copy. - Done
    // 1. Test fired reminders - Done
    // 2. Make an api for it - Done
    // 3. Link with React - Done
    
    //Two types of reminders:
    //1. Unfired reminders
    //2. Fired reminders
    
    //Unfired reminders are kept by the system
    //Fired reminders are kept in a persistent data structure
    
    static let notification_update = NSNotification.Name(rawValue: "NotificationRemindersChanged")
    static let notification_fired = NSNotification.Name(rawValue: "NotificationReminderFired")
    
    enum RemindersChanged {
        case True
        case False
        case Unknown
    }
    
    //these are reminders that were not pressed when triggered
    struct ReminderStruct: Equatable, Hashable {
        let url: String
        let date: Date
        let title: String
        var hashValue: Int {
            return url.hashValue ^ date.hashValue
        }
        
        static func == (lhs: ReminderStruct, rhs: ReminderStruct) -> Bool {
            return lhs.url == rhs.url
        }
        
        func dict() -> [String: Any] {
            return ["url":url, "date": date, "title": title]
        }
        
        func reminder() -> Reminder {
            return ["url":url, "date": date, "title": title]
        }
    }
    
    typealias Reminder = [String : Any]
    typealias Host = String
    typealias Url  = String
    typealias FiredReminders = [String: [ReminderStruct]]
    
    var didRemindersChange: RemindersChanged = .Unknown
    
    private var rem_cache: [Reminder] = []
    
    private var firedReminders: FiredReminders = [:]
    
    //instead of a hashmap I could build a trie tree, where the first layer of nodes is host names, and then attached to them path components
    //url_hash_map is a copy of the scheduled reminders. It is used to identify reminders that were fired while the app is inactive.
    private var url_hash_map: [Host : [Url]] = [:]
    
    static let sharedInstance = CIReminderManager()
    
    private let copyKey = "CopyKey_1234"
    private let firedKey = "Fired_1234"
    
    private var batchUpdate = false
    
    private func freezeStateUpdate() {
        batchUpdate = true
    }
    
    private func unfreezeStateUpdate() {
        batchUpdate = false
    }
    
    override init() {
        super.init()
        buildState()
    }
    
    private func buildState() {
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
    
    func refresh() {
        buildState()
    }
    
    func saveState() {
        makeCopy()
        saveFiredReminders()
    }
    
    func registerReminder(url: String, title: String, date: Date) {

        let userInfo = ["url": url, "title": title, "date": date, "isReminder": true] as [String : Any]
        
        let notification = UILocalNotification()
        notification.alertBody = CIReminderManager.alertBody(url: url, title: title) // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = date // todo item due date (when notification will be fired) notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.userInfo = userInfo // assign a unique identifier to the notification so that we can retrieve it later
        
        UIApplication.shared.scheduleLocalNotification(notification)
        
        addUrlToHashMap(map: &url_hash_map, url_str: url)
        
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
        
        //it might be that this reminder is already fired.
        removeFiredReminder(url_str: url)
        
    }
    
    //unregister for reminders that are not yet fired, since fired reminders are no longer UILocalNotifications.
    func unregisterReminder(reminder: UILocalNotification) {
        
        UIApplication.shared.cancelLocalNotification(reminder)
        if let url = reminder.userInfo?["url"] as? String {
            //remove from Copy
            self.freezeStateUpdate()
            removeFromFiredReminders(url: url)
            self.unfreezeStateUpdate()
            debugPrint("remove from url_hash_map")
            removeUrlFromHashMap(map: &url_hash_map, url_str: url)
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
    
    func allValidRemindersAscending() -> [Reminder] {
        return sortRemindersAscending(reminders: self.allValidReminders())
    }
    
    //valid reminders + fired reminders
    func allReminders() -> [Reminder] {
        return sortRemindersAscending(reminders: self.allValidReminders() + firedRemindersToArray())
    }
    
    func isUrlRegistered(url_str: Url) -> Bool {
        if let host = URL(string: url_str)?.normalizedHost() {
            if let array = url_hash_map[host] {
                if array.contains(url_str) {
                    return true
                }
            }
        }
        return false
    }
    
    func reminderFired(url_str: String, date: Date?, title: String?) {
        //add to FiredReminders
        self.freezeStateUpdate()
        addToFiredReminders(url: url_str, date: date ?? Date(), title: title ?? "")
        self.unfreezeStateUpdate()
        removeUrlFromHashMap(map: &url_hash_map, url_str: url_str)
        
        ReminderNotificationManager.shared.reminderFired(host: URL(string: url_str)?.normalizedHost())
        NotificationCenter.default.post(name: CIReminderManager.notification_fired, object: nil)
    }
    
    func reminderPressed(url_str: String) {
        removeFiredReminder(url_str: url_str)
    }

    func getFiredReminders(host: String) -> [[String: Any]] {
        if let array = firedReminders[host] {
            return transformRemindersStruct2Dict(reminders: array)
        }
        return []
    }
    
    //Private Methods -----------------------------------------------------------------------------
    
    private func removeFiredReminder(url_str: String) {
        ReminderNotificationManager.shared.reminderPressed(host: URL(string: url_str)?.normalizedHost())
        removeFromFiredReminders(url: url_str)
    }
    
    private func sortRemindersAscending(reminders: [Reminder]) -> [Reminder] {
        return reminders.sorted(by: { (a, b) -> Bool in
            if let date_a = a["date"] as? Date, let date_b = b["date"] as? Date {
                return date_a < date_b
            }
            return false
        })
    }
    
    private func firedRemindersToArray() -> [Reminder] {
        return self.firedReminders.flatMap { (arg) -> [Reminder] in
            let (_, value) = arg
            return value.map({ $0.reminder() })
        }
    }
    
    private func buildUrlHashMap(reminders: [Reminder]) -> [Host : [Url]] {
        
        var return_dict: [Host : [Url]] = [:]
        for reminder in reminders {
            let url_str = reminder["url"] as! String
            addUrlToHashMap(map: &return_dict, url_str: url_str)
        }
        
        return return_dict
    }
    
    private func keyGenerator_URL(elem: String) -> String? {
        if let url = URL(string: elem), let host = url.normalizedHost() {
            return host
        }
        return nil
    }
    
    private func addUrlToHashMap(map: inout [Host : [Url]], url_str: Url) {
        addToHashMap(map: &map, element: url_str, keyGenerator: keyGenerator_URL)
    }
    
    private func removeUrlFromHashMap(map: inout [Host : [Url]], url_str: Url) {
        removeFromHashMap(map: &map, element: url_str, keyGenerator: keyGenerator_URL)
    }
    
    private func loadFiredReminders() -> FiredReminders {
        
        if let dict = UserDefaults.standard.value(forKey: firedKey) as? [String: [[String:Any]]] {
            return transformToFiredReminders(dict: dict)
        }
        return [:]
    }
    
    private func saveFiredReminders(){
        
        var morphed_firedReminders: [String: [[String: Any]]] = [:]
        
        for key in firedReminders.keys {
            morphed_firedReminders[key] = transformRemindersStruct2Dict(reminders: firedReminders[key]!)
        }
        
        UserDefaults.standard.set(morphed_firedReminders, forKey: firedKey)
        UserDefaults.standard.synchronize()
    }
    
    private func addToFiredReminders(url: String, date: Date, title: String) {
        addToFiredReminders(reminder: ReminderStruct(url: url, date: date, title: title))
    }
    
    private func addToFiredReminders(reminder: ReminderStruct) {
        addToHashMap(map: &firedReminders, element: reminder, keyGenerator: keyGenerator_ReminderStruct)
    }
    
    private func removeFromFiredReminders(url: String) {
        //the url is the unique identifier. Only one reminder per url.
        removeFromHashMap(map: &firedReminders, element: ReminderStruct(url:url, date:Date(), title:""), keyGenerator: keyGenerator_ReminderStruct)
    }
    
    private func remindersFired() -> Set<ReminderStruct> {
        //here have an interface for creating the reminders_defaults
        let fired_and_notfired = readCopy()
        //in case there are no reminders from the system, return the fired_and_notfired. In this case fire_and_notfired contains only the fired notifications.
        guard let reminders_system = UIApplication.shared.scheduledLocalNotifications else {return fired_and_notfired}
        let unfired = transformToNotificationsSet(notifications: reminders_system)
        return fired_and_notfired.subtracting(unfired)
    }
    
    private func makeCopy() {
        guard let notifications = UIApplication.shared.scheduledLocalNotifications else {return}
        let array = transformToNotificationsDict(notifications: notifications)
        UserDefaults.standard.set(array, forKey: copyKey)
        UserDefaults.standard.synchronize()
    }
    
    private func readCopy() -> Set<ReminderStruct>{
        guard let array = UserDefaults.standard.value(forKey: copyKey) as? [[String: Any]] else {return Set()}
        return transformToRemindersSet(array: array)
    }
    
    private func keyGenerator_ReminderStruct(elem: ReminderStruct) -> String? {
        return self.keyGenerator_URL(elem: elem.url)
    }
    
    private func transformToFiredReminders(dict: [String: [[String: Any]]]) -> [String: [ReminderStruct]] {
        var ret_dict:[String: [ReminderStruct]] = [:]
        for key in dict.keys {
            ret_dict[key] = transformRemindersDict2Struct(reminders: dict[key]!)
        }
        return ret_dict
    }
    
    private func transformToRemindersSet(array: [[String: Any]]) -> Set<ReminderStruct> {
        var set: Set<ReminderStruct> = Set()
        for elem in array {
            if let url = elem["url"] as? String, let date = elem["date"] as? Date, let title = elem["title"] as? String {
                set.insert(ReminderStruct(url: url, date: date, title: title))
            }
        }
        return set
    }
    
    private func transformToNotificationsDict(notifications: [UILocalNotification]) -> [[String: Any]] {
        var array: [[String: Any]] = []
        for notification in notifications {
            if let date = notification.fireDate, let url = notification.userInfo?["url"] as? String, let title = notification.userInfo?["title"] as? String {
                array.append(["url":url, "title":title, "date":date])
            }
        }
        return array
    }
    
    private func transformToNotificationsSet(notifications: [UILocalNotification]) -> Set<ReminderStruct> {
        var set: Set<ReminderStruct> = Set.init()
        for notification in notifications {
            if let date = notification.fireDate, let url = notification.userInfo?["url"] as? String, let title = notification.userInfo?["title"] as? String {
                set.insert(ReminderStruct(url: url, date: date, title: title))
            }
        }
        return set
    }
    
    private func transformRemindersStruct2Dict(reminders: [ReminderStruct]) -> [[String: Any]] {
        var array: [[String: Any]] = []
        for reminder in reminders {
            let date = reminder.date
            let url = reminder.url
            let title = reminder.title
            array.append(["url":url, "date":date, "title": title])
        }
        return array
    }
    
    private func transformRemindersDict2Struct(reminders: [[String: Any]]) -> [ReminderStruct] {
        var array: [ReminderStruct] = []
        for elem in reminders {
            if let url = elem["url"] as? String, let date = elem["date"] as? Date, let title = elem["title"] as? String {
                array.append(ReminderStruct(url: url, date: date, title: title))
            }
        }
        return array
    }
    
    private func addToHashMap<A>(map: inout [String: [A]], element: A, keyGenerator: ((A) -> String?)) {
        var map_copy = map
        
        if let key = keyGenerator(element) {
            if var array = map_copy[key] {
                array.append(element)
                map_copy[key] = array
            }
            else {
                map_copy[key] = [element]
            }
        }
        
        map = map_copy
        
        stateChanged()
    }
    
    private func removeFromHashMap<A:Equatable>(map: inout [String : [A]], element: A, keyGenerator:((A) -> String?)) {
        
        var map_copy = map
    
        if let key = keyGenerator(element) {
            if var array = map_copy[key] {
                for i in 0..<array.count {
                    let other_elem = array[i]
                    if other_elem == element {
                        array.remove(at: i)
                        break
                    }
                }
                if array.isEmpty {
                    map_copy[key] = nil
                }
                else {
                    map_copy[key] = array
                }
            }
            else {
                //Nothing to remove.
            }
        }
        else {
            //this is an invalid key
        }
        
        map = map_copy
        
        stateChanged()
    }
    
    private func stateChanged() {
        if batchUpdate == false {
            didRemindersChange = .True
            postRefreshNotification()
        }
    }
    
    private func postRefreshNotification() {
        NotificationCenter.default.post(name: CIReminderManager.notification_update, object: nil)
    }
}

extension CIReminderManager {
    
    class func alertBody(url: String, title: String) -> String {
        var host = ""
        
        if let h = URL(string: url)?.normalizedHost() {
            host = h
        }
        
        return host != "" ? "\u{1F514} Reminder (\(host)): \n\(title)" : "\(title) (Reminder)"
    }
    
}

