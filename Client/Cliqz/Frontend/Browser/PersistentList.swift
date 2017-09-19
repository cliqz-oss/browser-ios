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
    var list: [A] = []
    var dateList: [Date] = []
    //here is where the date when that entry was added is put. The following should hold true: the date for the element at list[index] is at date[index]
    //there is a one to one index correspondece.
    
    let defaults = UserDefaults.standard
    
    init(identifier: String) {
        self.id = identifier
        self.loadList()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appEnteredBackground), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func add(element: A) {
        
        guard !contains(element: element) else {
            return
        }
        
        list.append(element)
        dateList.append(Date())
    }
    
    //removes all occurences of element
    func remove(element: A) {
        
        var index = 0
        
        for entry in list {
            if entry == element {
                removeAt(index: index)
            }
            
            index += 1
        }
    }
    
    func removeAt(index: Int) {
        list.remove(at: index)
        dateList.remove(at: index)
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
    
    @objc func appEnteredBackground(_ notification: Notification) {
        self.saveList()
    }
    
}


