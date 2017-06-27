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
    
    var didRemindersChange: RemindersChanged = .Unknown
    
    private var rem_cache: [Reminder] = []
    
    typealias Host = String
    typealias Url  = String
    
    //instead of a hashmap I could build a trie tree, where the first layer of nodes is host names, and then attached to them path components
    private var url_hash_map: [Host : Url] = [:]
    
    struct Reminder {
        var url: String
        var title: String
        var date: Date
        //var domain: String
    }
    
    static let sharedInstance = CIReminderManager()
    
    override init() {
        super.init()
    }
    
//    func buildUrlHashMap(notifications:[Notification]) -> [Host : Url] {
//        
//    }
    
    func registerReminder(url: String, title: String, date: Date) {
        
        //let domain = URL(string: url)?.absoluteURL.baseURL?.absoluteString ?? ""

        let userInfo = ["url": url, "title": title, "date": date, "isReminder": true] as [String : Any]
        
//        if #available(iOS 10.0, *) {
//            let content = UNMutableNotificationContent()
//            content.body = NSString.localizedUserNotificationString(forKey: "\(title) (Reminder)", arguments: nil)
//            content.userInfo = userInfo
//            content.sound = UNNotificationSound.default()
//            
//            // Trigger time
//            let timeDifference = date.timeIntervalSince(Date.init(timeIntervalSinceNow: 0))
//            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeDifference, repeats: false)
//            
//            // Schedule the notification.
//            let request = UNNotificationRequest(identifier: "FiveSecond", content: content, trigger: trigger)
//            let center = UNUserNotificationCenter.current()
//            center.add(request, withCompletionHandler: nil)
//        
//        } else {
            // Fallback on earlier versions
            
            let notification = UILocalNotification()
            notification.alertBody = "\(title) (Reminder)" // text that will be displayed in the notification
            notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
            notification.fireDate = date // todo item due date (when notification will be fired) notification.soundName = UILocalNotificationDefaultSoundName // play default sound
            notification.userInfo = userInfo // assign a unique identifier to the notification so that we can retrieve it later
            
            UIApplication.shared.scheduleLocalNotification(notification)
        //}
        
        didRemindersChange = .True
        
    }
    
    
    func allValidReminders(completion: @escaping ([Reminder]) -> Void ) {
        
        //Caching mechanism
        //There are 2 ways reminders are modified:
        //Added when registered
        //Removed when they fire
        //Keep a cache of all reminders, and a flag "didRemindersChange"
        //if didRemindersChange == false return cache, else query
        
        if didRemindersChange == .False {
            completion(rem_cache)
            return
        }
        
//        if #available(iOS 10.0, *) {
//            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (array_requests) in
//                let reminders = array_requests.map({ (request) -> Reminder in
//                    let url   = request.content.userInfo["url"] as! String
//                    let title = request.content.userInfo["title"] as! String
//                    let date  = request.content.userInfo["date"] as! Date
//                    
//                    return Reminder(url: url, title: title, date: date)
//                })
//                
//                completion(reminders)
//            })
//        }
//        else {
            if let notifications = UIApplication.shared.scheduledLocalNotifications {
                let reminders = notifications.map({ (notification) -> Reminder in
                    let url   = notification.userInfo?["url"] as! String
                    //let domain = notification.userInfo?["domain"] as! String
                    let title = notification.userInfo?["title"] as! String
                    let date  = notification.userInfo?["date"] as! Date
                    
                    return Reminder(url: url, title: title, date: date)//, domain: domain)
                })
                rem_cache = reminders
                didRemindersChange = .False
                completion(reminders)
            }
            else {
                completion([])
            }
        //}
    }
    
}

