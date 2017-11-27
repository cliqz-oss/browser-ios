//
//  ReminderNotificationManager.swift
//  Client
//
//  Created by Tim Palade on 11/27/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

class ReminderNotificationManager: NSObject {
    
    static  let shared = ReminderNotificationManager()
    private let dict = PersistentDict<String, Int>(id: "ID_Reminder_Notifications")
    
    func notificationsFor(host: String?) -> Int {
        guard let host = host else { return 0 }
        return dict.value(key: host) ?? 0
    }
    
    func reminderPressed(host: String?) {
        guard let host = host else { return }
        if let value = dict.value(key: host), value > 0 {
            dict.setValue(value: value - 1, forKey: host)
        }
    }
    
    func reminderFired(host: String?) {
        guard let host = host else { return }
        if let value = dict.value(key: host), value >= 0 {
            dict.setValue(value: value + 1, forKey: host)
        }
        else {
            dict.setValue(value: 1, forKey: host)
        }
    }
    
    func domainPressed(host: String?) {
        guard let host = host else { return }
        dict.removeValue(forKey: host)
    }
    
    func domainDeleted(host: String?) {
        guard let host = host else { return }
        dict.removeValue(forKey: host)
    }
}
