//
//  DomainsModule.swift
//  Client
//
//  Created by Tim Palade on 8/29/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class DomainsModule {
    
    //TO DO: I need to update the domains each time a new domain is added to the database. I need something smart here. I don't want to load everything every time.
    
    static let sharedInstance = DomainsModule()
    
    static let notification_updated = Notification.Name(rawValue: "DomainsModuleUpdated")
    
    var domains: [Domain] = []
    
    private var loading: Bool = false
    //Note: CompletionBlocks is not thread safe: I copy it when I iterate over it.
    var completionBlocks: [((_ ready:Bool) -> Void)?] = []
    
    init() {
        self.loadData(completion: nil)
    }
    
    func loadData(completion:((_ ready:Bool) -> Void)?) {
        
        if loading == false {
            
            loading = true
            self.completionBlocks.append(completion)
            domains = []
            
            if let appDel = UIApplication.shared.delegate as? AppDelegate , let profile = appDel.profile {
                HistoryModule.getHistory(profile: profile, completion: { (result, error) in
                    DispatchQueue.main.async(execute: {
                        if let domains = result {
                            self.domains.append(contentsOf: domains.sorted(by: { (a, b) -> Bool in
                                if let date_a = a.date, let date_b = b.date {
                                    return date_a > date_b
                                }
                                return false
                            }))
                        }
                        
                        NotificationCenter.default.post(name: DomainsModule.notification_updated, object: nil)
                        
                        self.loading = false
                        //this is not needed. Iteration has its own copy of value it is iterating over.
                        let blocks = self.completionBlocks //array is a value type, as well as the clojures inside. So this is a deep copy on demand (= copies when needed).
                        for completion in blocks{
                            completion?(true)
                        }
                        //elements could have been added in the meantime to completionBlocks, so take out only the first blocks.count
                        //take out the elements starting from the end, so the correspondence betweeen i and the indexes is not messed up.
                        for i in (0..<blocks.count).reversed() {
                            self.completionBlocks.remove(at: i)
                        }
                    })
                })
            }
            
        }
        else {
            self.completionBlocks.append(completion)
        }
    }
    
}
