//
//  CIReminderManager.swift
//  Client
//
//  Created by Tim Palade on 6/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import UserNotifications

class CIReminderManager: NSObject {
    
    //ATTENTION ONLY 64 REMINDERS ARE ALLOWED
    
    enum RemindersChanged {
        case True
        case False
        case Unknown
    }
    
    typealias Reminder = [String : Any]
    typealias Host = String
    typealias Url  = String
    
    var didRemindersChange: RemindersChanged = .Unknown
    
    private var rem_cache: [Reminder] = []
    
    //instead of a hashmap I could build a trie tree, where the first layer of nodes is host names, and then attached to them path components
    private var url_hash_map: [Host : [Url]] = [:]
    
    static let sharedInstance = CIReminderManager()
    
    override init() {
        super.init()
        url_hash_map = buildUrlHashMap(reminders: allValidReminders())
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
    
    func reminderFired(url_str: String) {
        url_hash_map = removeUrlFromHashMap(map: url_hash_map, url_str: url_str)
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
                map_copy[host] = array
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
    
}

