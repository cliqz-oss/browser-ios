//
//  NewsIgnoreList.swift
//  Client
//
//  Created by Tim Palade on 9/7/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//this has a delete rule. It should get rid of urls older than one day, because the assumption is that after one day they will not come back from the backend. So any time after 24 hours is fine for deletion. The easiest seems to be to delete all urls older than one day every time the app wakes up.

//or simpler, I can do a clean up every time I have retreive something. 
//the added work is negligible

class NewsIgnoreList: PersistentList<String> {
    
    override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    override func contains(element: String) -> Bool {
        cleanUp()
        return super.contains(element: element)
    }
    
    func cleanUp() {
        
        var index = 0
        
        for elem_date in dateList {
            if isOlderThanOneDay(date: elem_date) {
                self.removeAt(index: index)
            }
            
            index += 1
        }
    }
    
    private func isOlderThanOneDay(date: Date) -> Bool{
        let currentDate = NSDate(timeIntervalSinceNow: 0)
        let difference_seconds = currentDate.timeIntervalSince(date)
        let oneDay_seconds     = Double(24 * 360)
        if difference_seconds > 0 && difference_seconds > oneDay_seconds {
            return true
        }
        return false
    }
    
}




