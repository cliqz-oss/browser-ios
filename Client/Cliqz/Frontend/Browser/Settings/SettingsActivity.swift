//
//  SettingsActivity.swift
//  Client
//
//  Created by Mahmoud Adam on 8/30/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class SettingsActivity : UIActivity {
    
    fileprivate let callback: () -> ()
    
    init(callback: @escaping () -> ()) {
        self.callback = callback
    }
    
    override var activityTitle : String? {
        return NSLocalizedString("Settings", tableName: "Cliqz", comment: "Sharing activity for opening Settings")
        
    }
    
    override var activityImage : UIImage? {
        return UIImage(named: "settings")
    }
    
    override func perform() {
        callback()
        activityDidFinish(true)
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
}
