//
//  BackgroundTasksManager.swift
//  Client
//
//  Created by Mahmoud Adam on 7/13/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class BackgroundTasksManager: NSObject {
    static let sharedInstance = BackgroundTasksManager()
    
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    private var backdroundTasksCount = 0
    
    func beginBackgroundTask() {
        if backdroundTasksCount == 0 {
            backgroundTaskIdentifier =  UIApplication.shared.beginBackgroundTask() {
                self.doEndBackgroundTask()
            }
        }
        backdroundTasksCount += 1
    }
    
    func endBackgroundTask() {
        guard backdroundTasksCount > 0 else {
            return
        }
        
        backdroundTasksCount -= 1
        if backdroundTasksCount == 0 {
            self.doEndBackgroundTask()
        }
    }
    
    private func doEndBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
        backgroundTaskIdentifier = UIBackgroundTaskInvalid
    }
}
