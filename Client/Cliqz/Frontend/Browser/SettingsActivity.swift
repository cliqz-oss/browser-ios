//
//  SettingsActivity.swift
//  Client
//
//  Created by Mahmoud Adam on 8/30/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class SettingsActivity : UIActivity {
    
    private let callback: () -> ()
    
    init(callback: () -> ()) {
        self.callback = callback
    }
    
    override func activityTitle() -> String? {
        return NSLocalizedString("Settings", tableName: "Cliqz", comment: "Sharing activity for opening Settings")
        
    }
    
    override func activityImage() -> UIImage? {
        return UIImage(named: "settings")
    }
    
    override func performActivity() {
        callback()
        activityDidFinish(true)
    }
    
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return true
    }
}
