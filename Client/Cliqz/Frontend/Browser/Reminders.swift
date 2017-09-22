//
//  Reminders.swift
//  Client
//
//  Created by Tim Palade on 9/5/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class Reminders: NSObject {
    
    enum ReminderOption {
        case Option1
        case Option2
        case Option3
        case Option4
    }
    
    private class func getUrl() -> String {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let tabManager = appDelegate.tabManager
        
        if let currentTab = tabManager?.selectedTab {
            return currentTab.url?.absoluteString ?? ""
        }
        
        return ""
    }
    
    private class func getTitle() -> String {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let tabManager = appDelegate.tabManager
        
        if let currentTab = tabManager?.selectedTab {
            return currentTab.title ?? ""
        }
        
        return ""
    }
    
    class func show() {
        
        let url = self.getUrl()
        
        if CIReminderManager.sharedInstance.isUrlRegistered(url_str: url) {
            showRemoveReminderActionSheet(url: url)
        }
        else {
            showSetReminderActionSheet(title: self.getTitle(), url: url)
        }
    }
    
    private class func showSetReminderActionSheet(title: String, url: String){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        //define actions
        let first_option = UIAlertAction(title: "30 Minutes", style: .default) { (action) in
            self.reminderSet(option: .Option1, title: title, url: url)
        }
        
        let second_option = UIAlertAction(title: "4 Hours", style: .default) { (action) in
            self.reminderSet(option: .Option2, title: title, url: url)
        }
        
        let third_option = UIAlertAction(title: "8 Hours", style: .default) { (action) in
            self.reminderSet(option: .Option3, title: title, url: url)
        }
        
        let fourth_option = UIAlertAction(title: "Tomorrow", style: .default) { (action) in
            self.reminderSet(option: .Option4, title: title, url: url)
        }
        
        let cancel_action = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let actions = [first_option, second_option, third_option, fourth_option, cancel_action]
        let title   = "When would you like to be reminded?"
        let message: String? = nil
        
        appDelegate.presentActionSheet(title: title, message: message, actions: actions)
        
    }
    
    private class func showRemoveReminderActionSheet(url: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        //define actions
        let first_option = UIAlertAction(title: "Remove Reminder", style: .destructive) { (action) in
            self.reminderRemove(url: url)
        }
        
        let cancel_action = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let actions = [first_option, cancel_action]
        var title: String?   = nil
        let message: String? = nil
        
        
        let array = CIReminderManager.sharedInstance.remindersWith(url: url)
        if !array.isEmpty {
            let notification = array.first
            if let seconds = notification?.fireDate?.timeIntervalSinceNow {
                let time = GeneralUtils.convert(seconds: Int(seconds))
                if seconds >= 0 {
                    title = "You will be reminded in " + time
                }
                else if seconds < 0 {
                    title = "You were reminded " + time + " ago"
                }
                
            }
        }
        
        
        appDelegate.presentActionSheet(title: title, message: message, actions: actions)
        
    }
    
    private class func reminderSet(option: ReminderOption, title: String, url: String) {
        
        var timeInterval: TimeInterval = 0.0
        
        switch option {
        case .Option1: //30 Minutes
            timeInterval = 30 * 60
        case .Option2: //4 Hours
            timeInterval = (4 * 60) * 60
        case .Option3: //8 Hours
            timeInterval = (8 * 60) * 60
        case .Option4: //Tomorrow
            timeInterval = (24 * 60) * 60
        }
        
        let date = Date.init(timeIntervalSinceNow: timeInterval)
        
        CIReminderManager.sharedInstance.registerReminder(url: url, title: title, date: date)
        
    }
    
    private class func reminderRemove(url: String){
        
        let reminders = CIReminderManager.sharedInstance.remindersWith(url: url)
        for reminder in reminders {
            CIReminderManager.sharedInstance.unregisterReminder(reminder: reminder)
        }
    }
    
}
