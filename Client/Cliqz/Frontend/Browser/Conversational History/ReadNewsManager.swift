//
//  ReadNewsManager.swift
//  Client
//
//  Created by Tim Palade on 5/16/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//import Foundation
//
////This takes care of remembering which news are read.
//
//final class ReadNewsManager {
//    
//    //articles change every day. So only articles that are youger than 1 day should stay in my manager
//    //I will write to disk the current articles when the application is closed.
//    
//    //user defaults key
//    private let userDefaultsKey_Read = "ID_READ_NEWS"
//    
//    private var readArticlesDict: Dictionary<String,NSDate> = Dictionary()
//    
//    static let sharedInstance = ReadNewsManager()
//    
//    init() {
//        let userDefaults = NSUserDefaults.standardUserDefaults()
//        
//        if let read = userDefaults.valueForKey(userDefaultsKey_Read) as? Dictionary<String,NSDate> {
//            //here add only keys that have a value younger than 1 day.
//            self.readArticlesDict = self.youngerThanOneDayDict(read)
//        }
//    }
//    
//    func isRead(articleLink:String) -> Bool {
//        return readArticlesDict.keys.contains(articleLink)
//    }
//    
//    func markAsRead(articleLink:String?) {
//        guard let art_link = articleLink else { return }
//        readArticlesDict[art_link] = NSDate(timeIntervalSinceNow: 0)
//    }
//    
//    func save(){
//        NSUserDefaults.standardUserDefaults().setObject(self.readArticlesDict, forKey: userDefaultsKey_Read)
//        NSUserDefaults.standardUserDefaults().synchronize()
//    }
//    
//    private func youngerThanOneDayDict(dict: Dictionary<String,NSDate>) -> Dictionary<String,NSDate>{
//        var returnDict: Dictionary<String,NSDate> = Dictionary()
//        for key in dict.keys{
//            if let date = dict[key] where isYoungerThanOneDay(date){
//                returnDict[key] = date
//            }
//        }
//        return returnDict
//    }
//    
//    private func isYoungerThanOneDay(date:NSDate) -> Bool{
//        let currentDate = NSDate(timeIntervalSinceNow: 0)
//        let difference_seconds = currentDate.timeIntervalSinceDate(date)
//        let oneDay_seconds     = Double(24 * 360)
//        if difference_seconds > 0 && difference_seconds < oneDay_seconds {
//            return true
//        }
//        return false
//    }
//    
//}
