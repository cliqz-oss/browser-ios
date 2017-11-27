//
//  PersistentDict.swift
//  Client
//
//  Created by Tim Palade on 11/27/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

class PersistentDict<A,B> where A: Hashable {
    
    private let id: String
    private var internalDict: Dictionary<A,B> = [:]
    private weak var userDefaults: UserDefaults? = UserDefaults.standard
    
    var keys: LazyMapCollection<[A : B], A> {
        return internalDict.keys
    }
    
    init(id: String) {
        self.id = id
        if let diskDict = dictFromDisk() {
            self.internalDict = diskDict
        }
        NotificationCenter.default.addObserver(self, selector: #selector(save), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(save), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func value(key: A) -> B? {
        return internalDict[key]
    }
    
    func setValue(value: B, forKey: A) {
        internalDict[forKey] = value
    }
    
    func map<C>(f: (B) -> C) -> Dictionary<A,C> {
        return internalDict.mapValues({ (value) -> C in
            return f(value)
        })
    }
    
    func filter(p: (B) -> Bool) {
        for key in internalDict.keys {
            if let value = internalDict[key], !p(value) {
                internalDict.removeValue(forKey: key)
            }
        }
    }
    
    func removeValue(forKey: A) {
        internalDict.removeValue(forKey: forKey)
    }
    
    private func dictFromDisk() -> Dictionary<A,B>? {
        return userDefaults?.value(forKey: id) as? Dictionary<A,B>
    }
    
    @objc private func save() {
        UserDefaults.standard.set(self.internalDict, forKey: id)
        UserDefaults.standard.synchronize()
    }
}
