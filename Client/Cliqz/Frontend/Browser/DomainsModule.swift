//
//  DomainsModule.swift
//  Client
//
//  Created by Tim Palade on 8/29/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
import Shared

class DomainsModule {

    //TO DO: I need to update the domains each time a new domain is added to the database. I need something smart here. I don't want to load everything every time.

    static let shared = DomainsModule()

    static let notification_updated = Notification.Name(rawValue: "DomainsModuleUpdated")

    var domains: [DomainModel] = []

    private var loading: Bool = false
    //Note: CompletionBlocks is not thread safe: I copy it when I iterate over it.
    var completionBlocks: [((_ ready:Bool) -> Void)?] = []
    
    init() {
        self.loadData(completion: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(visitInsertedInDB), name: Notification.Name.init("NotificationSQLiteHistoryAddLocalVisit"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(domainsInHistoryDeleted), name: NotificationPrivateDataClearedHistory, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func loadData(completion:((_ ready: Bool) -> Void)?) {
        
//        if loading == false {
//            loading = true
//            self.completionBlocks.append(completion)
//            domains = []
//
//            if let appDel = UIApplication.shared.delegate as? AppDelegate , let profile = appDel.profile {
//                HistoryModule.getDomains(profile: profile, completion: { (result, error) in
//                    DispatchQueue.main.async(execute: {
//                        if let domains = result {
//                            self.domains.append(contentsOf: domains.sorted(by: { (a, b) -> Bool in
//                                if let date_a = a.date, let date_b = b.date {
//                                    return date_a > date_b
//                                }
//                                return false
//                            }))
//                        }
//
//                        NotificationCenter.default.post(name: DomainsModule.notification_updated, object: nil)
//
//                        self.loading = false
//                        //this is not needed. Iteration has its own copy of value it is iterating over.
//                        let blocks = self.completionBlocks //array is a value type, as well as the clojures inside. So this is a deep copy on demand (= copies when needed).
//                        for completion in blocks{
//                            completion?(true)
//                        }
//                        //elements could have been added in the meantime to completionBlocks, so take out only the first blocks.count
//                        //take out the elements starting from the end, so the correspondence betweeen i and the indexes is not messed up.
//                        for i in (0..<blocks.count).reversed() {
//                            self.completionBlocks.remove(at: i)
//                        }
//                    })
//                })
//            }
//
//        }
//        else {
//            self.completionBlocks.append(completion)
//        }
    }

    @objc
    func visitInsertedInDB(_ notification: Notification) {
		loadData(completion: nil)
		/*
        if let info = notification.userInfo as? [String: Any] {
            let title = info["title"] as? String ?? ""
            let date = info["date"] as? UInt64 ?? Date.nowMicroseconds()
            
            if let url = info["url"] as? String {
                //insert this entry in the domains list
                let domainDetail = constructDomainDetail(url: url, title: title, date: date)
                addDomainDetail(detail: domainDetail)
                //when done send notification
                NotificationCenter.default.post(name: DomainsModule.notification_updated, object: nil)
                //StateManager.shared.handleAction(action: Action(data: ["url" : url], type: .visitAddedInDB))
            }
        }
*/
    }
    
    @objc
    func domainsInHistoryDeleted(_ notification: Notification) {
        loadData(completion: nil)
    }

	func loadDomainDetails(_ domain: DomainModel, completion:(([DomainDetailModel]?) -> Void)?) {
		if let appDel = UIApplication.shared.delegate as? AppDelegate , let profile = appDel.profile {
			HistoryModule.getDomainVisits(profile: profile, domainID: domain.id, completion: { (results, error) in
				if let details = results,
					let i = self.domains.index(of: domain) {
					var d = self.domains[i]
					d.domainDetails = details
					completion?(details)
				}
			})
		}
	}

	func removeDomain(at index: Int) {
		let domain = self.domains[index]
		if let appDel = UIApplication.shared.delegate as? AppDelegate , let profile = appDel.profile {
			HistoryModule.removeDomain(profile: profile, id: domain.id, completion: { (succeed, error) in
				if succeed {
					self.domains.remove(at: index)
					NotificationCenter.default.post(name: DomainsModule.notification_updated, object: nil)
				}
			})
		}
	}

    func constructDomainDetail(url: String, title: String, date: UInt64) -> DomainDetailModel? {
        if let nsUrl = NSURL(string: url) {
            let adjustedDate = Date.init(timeIntervalSince1970: TimeInterval(date / 1000000))
            return DomainDetailModel(title: title, url: nsUrl, date: adjustedDate)
        }
        return nil
    }
    
    func addDomainDetail(detail: DomainDetailModel?) {
        guard let detail = detail else {
            return
        }
        if let detailHost = detail.url.host {
            var index = 0
            var domainFound = false

            for domain in domains {
                if domain.host == detailHost {
                    var domainDetails = domain.domainDetails
                    domainDetails?.insert(detail, at: 0)
                    
					let updatedDomain = DomainModel(id: 0, host: domain.host, domainDetails: domainDetails, date: detail.date)
                    
                    //this is the latest entry. The domain should become the first in the list.
                    domains.remove(at: index)
                    domains.insert(updatedDomain, at: 0)
                    
                    domainFound = true
                    break
                }
                index += 1
            }
            
            if domainFound == false {
				let domain = DomainModel(id: 0, host: detailHost, domainDetails: [detail], date: detail.date)
                self.domains.insert(domain, at: 0)
            }
        }
    }

}
