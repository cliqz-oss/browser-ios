//
//  RealmStore.swift
//  Client
//
//  Created by Tim Palade on 12/4/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import RealmSwift

class Domain: Object {
    @objc dynamic var name = ""
    @objc dynamic var last_timestamp = Date()
    var entries = LinkingObjects(fromType: Entry.self, property: "domain")
    
    override static func primaryKey() -> String? {
        return "name"
    }
}

class Entry: Object {
    @objc dynamic var timestamp = Date()
    @objc dynamic var domain: Domain?
    @objc dynamic var isQuery: Bool = false
    @objc dynamic var url = ""
    @objc dynamic var title = ""
    @objc dynamic var isBookmarked: Bool = false
    @objc dynamic var query = ""
    
    override class func indexedProperties() -> [String] {
        return ["timestamp"]
    }
}

class Bookmarks: Object {
    var list = List<Entry>()
}

final class RealmStore: NSObject {
    
    //TODO: clean entries without domain
    
    class func addVisitSync(url: String, title: String) {
        let realm = try! Realm()
        _ = self.addVisit(realm: realm, url: url, title: title)
    }
    
    class func addQuerySync(query: String, forUrl: String) {
        guard let host = URL(string: forUrl)?.normalizedHost() else { debugPrint("failed to add query. host is not valid. - \(query) - \(forUrl)"); return }
        let realm = try! Realm()
        let domain = self.getDomain(realm: realm, host: host)
        _ = addQuery(realm: realm, query_str: query, domain: domain)
    }
    
    class func removeDomain(domain: Domain) {
        
        let realm = try! Realm()
        
        do {
            try realm.write {
                realm.delete(domain.entries)
            }
        }
        catch {
            debugPrint("could not remove entries for domain - \(domain)")
        }
        
        executeDelete(realm: realm, objects: [domain])
    }
    
//    class func removeObject(object: Object) {
//        let realm = try! Realm()
//        executeDelete(realm: realm, objects: [object])
//    }
    
    private class func addVisit(realm: Realm, url: String, title: String) -> Entry? {
        
        //use normalizedHost here
        guard let host = URL(string: url)?.normalizedHost() else { debugPrint("visit add failed -- \(url) -- \(title)"); return nil }
        
        let domain = self.getDomain(realm: realm, host: host)
        
        let visit = createVisit(url: url, title: title, domain: domain)
        
        do {
            try realm.write {
                domain.last_timestamp = visit.timestamp
            }
        }
        catch {
            debugPrint("could not update domain timestamp")
        }
        
        executeWrite(realm: realm, objects: [visit])
        
        return visit
    }
    
    private class func getDomain(realm: Realm, host: String) -> Domain {
        //domain found => return domain
        //domain not found => create new and return new
        let possible_domain = realm.object(ofType: Domain.self, forPrimaryKey: host)
        return possible_domain != nil ? possible_domain! : addDomain(realm: realm, name: host)
    }
    
    private class func addQuery(realm: Realm, query_str: String, domain: Domain) -> Entry {
        let query = createQuery(query_str: query_str, domain: domain)
        executeWrite(realm: realm, objects: [query])
        return query
    }
    
    private class func addDomain(realm: Realm, name: String) -> Domain {
        let domain = createDomain(name: name)
        executeWrite(realm: realm, objects: [domain])
        return domain
    }
    
    private class func createQuery(query_str: String, domain: Domain) -> Entry {
        let query = Entry()
        query.query = query_str
        query.timestamp = Date()
        query.domain = domain
        query.isQuery = true
        return query
    }
    
    private class func createVisit(url: String, title: String, domain: Domain) -> Entry {
        let visit = Entry()
        visit.domain = domain
        visit.url = url
        visit.title = title
        visit.timestamp = Date()
        visit.isBookmarked = false
        return visit
    }
    
    private class func createDomain(name: String) -> Domain {
        let domain = Domain()
        domain.name = name
        domain.last_timestamp = Date()
        return domain
    }
    
    private class func executeWrite(realm: Realm, objects: [Object]) {
        do {
            try realm.write {
                realm.add(objects)
            }
        }
        catch {
            debugPrint("objects add failed -- \(objects)")
        }
    }
    
    private class func executeDelete(realm: Realm, objects: [Object]) {
        do {
            try realm.write {
                realm.delete(objects)
            }
        }
        catch {
            debugPrint("objects add failed -- \(objects)")
        }
    }
    
}
