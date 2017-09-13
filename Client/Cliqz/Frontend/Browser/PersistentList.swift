//
//  IgnoreList.swift
//  Client
//
//  Created by Tim Palade on 9/7/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//Use: When news are deleted from recommendations I need to keep the url for one day. Otherwise the news will appear again in recommendations

class PersistentList<A: Equatable> {
    
    let id: String
    private var list: [A] = []
    private var dateList: [Date] = []
    //here is where the date when that entry was added is put. The following should hold true: the date for the element at list[index] is at date[index]
    //there is a one to one index correspondece.
    
    let defaults = UserDefaults.standard
    
    init(identifier: String) {
        self.id = identifier
        self.loadList()
    }
    
    func add(element: A) {
        list.append(element)
        dateList.append(Date())
    }
    
    func remove(element: A) {
        
        var index = 0
        
        for entry in list {
            if entry == element {
                list.remove(at: index)
                dateList.remove(at: index)
            }
            
            index += 1
        }
    }
    
    func contains(element: A) -> Bool {
        return list.contains(element)
    }
    
    private func loadList() {
        if let dict = defaults.value(forKey: self.id) as? [String: Any] {
            if let array = dict["list"] as? [A], let dateArray = dict["dateList"] as? [Date] {
                list = array
                dateList = dateArray
            }
        }
    }
    
    func saveList() {
        let dict: [String : Any] = ["list": list, "dateList": dateList]
        defaults.set(dict, forKey: self.id)
        defaults.synchronize()
    }
    
}


