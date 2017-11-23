//
//  ReminderActivity.swift
//  Client
//
//  Created by Tim Palade on 9/5/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class ReminderActivity: UIActivity {
    
    fileprivate let callback: () -> ()
    
    init(callback: @escaping () -> ()) {
        self.callback = callback
    }
    
    override var activityTitle : String? {
        return NSLocalizedString("Set Reminder", tableName: "Cliqz", comment: "Text for set reminders title")
    }
    
    override var activityImage : UIImage? {
        return UIImage.templateImageNamed("whiteBell")
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType("com.cliqz.reminder")
    }
    
    override func perform() {
        callback()
        activityDidFinish(true)
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
}
