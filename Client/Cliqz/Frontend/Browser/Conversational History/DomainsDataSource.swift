//
//  HistoryDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
//The data source for the ConversationalHistory View. 

final class DomainsDataSource: NSObject, DomainsProtocol {
    
    //This still needs work
    //Loads every time this view is shown. This can be problematic with big history. Need to handle that.
    
    var domains: [DomainModel] = []
    
    let cliqzNews_header = "Cliqz News"
    let cliqzNews_title  = "Tap to Read"
    
    weak var delegate: HasDataSource?
    
    override init() {
        super.init()
        loadDomains()
        NotificationCenter.default.addObserver(self, selector: #selector(domainsUpdated), name: DomainsModule.notification_updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reminderFired), name: CIReminderManager.notification_fired, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadDomains() {
        domains = processDomains(domains: DomainsModule.shared.domains)
    }

    func numberOfCells() -> Int {
        return self.domains.count
    }

    func urlLabelText(indexPath: IndexPath) -> String {
        return domains[indexPath.row].host
    }

    func titleLabelText(indexPath:IndexPath) -> String {
        return domains[indexPath.row].date?.toRelativeTimeString() ?? ""
    }

    func timeLabelText(indexPath: IndexPath) -> String {
        return ""
    }

    func baseUrl(indexPath: IndexPath) -> String {
        let domain = domains[indexPath.row]
		return domain.host
    }

	func image(indexPath: IndexPath, completionBlock: @escaping (_ image: UIImage?, _ customView: UIView?) -> Void) {
		LogoLoader.loadLogo(self.baseUrl(indexPath: indexPath)) { (image, logoInfo, error) in
			if let img = image {
				completionBlock(img, nil)
			} else {
				if let info = logoInfo {
					let logoPlaceholder = LogoPlaceholder.init(logoInfo: info)
					completionBlock(nil, logoPlaceholder)
				} else {
					completionBlock(nil, nil)
				}
			}
		}
    }
    
    func shouldShowNotification(indexPath:IndexPath) -> Bool {
        if ReminderNotificationManager.shared.notificationsFor(host: baseUrl(indexPath: indexPath)) > 0 {
            return true
        }
        return false
    }
 
    func notificationNumber(indexPath:IndexPath) -> Int {
        return ReminderNotificationManager.shared.notificationsFor(host: baseUrl(indexPath: indexPath))
    }
    
    func indexWithinBounds(indexPath:IndexPath) -> Bool {
        if indexPath.row < self.domains.count {
            return true
        }
        return false
    }

    @objc
    func domainsUpdated(_ notification: Notification) {
        update()
    }
    
    @objc
    func reminderFired(_ notification: Notification) {
        update()
    }
    
    private func update() {
        loadDomains()
        delegate?.dataSourceWasUpdated(identifier: "DomainsDataSource")
    }

	func removeDomain(at index: Int) {
		if index < self.domains.count {
			self.domains.remove(at: index)
			DomainsModule.shared.removeDomain(at: index)
		}
	}
    
    //-------------------------------------------------------
    
    private func processDomains(domains: [DomainModel]) -> [DomainModel] {
        let domainsWithNotificationOnTop = putDomainsWithNotificationOnTop(domains: domains)
        return domainsWithNotificationOnTop
    }
    
    private func putDomainsWithNotificationOnTop(domains: [DomainModel]) -> [DomainModel] {
        let (extracted, domains_wo_extracted) = extractElements(from: domains) { (domain) -> Bool in
             return ReminderNotificationManager.shared.notificationsFor(host: domain.host) > 0
        }
        
        return extracted + domains_wo_extracted
    }
    
    //this method takes the elements that meet the predicate out of the list and returns two lists:
    //one with the elements that meet the predicate
    //the second is the initial list without the extracted elements
    private func extractElements(from domains: [DomainModel], predicate: (DomainModel) -> Bool) -> ([DomainModel], [DomainModel]){
        
        var copy = domains
        var extracted: [DomainModel] = []
        
        var index = 0
        var index_array:[Int] = []
        for element in domains {
            if predicate(element) {
                extracted.append(element)
                index_array.append(index)
            }
            index += 1
        }
        
        for i in index_array.sorted(by: >) {
            copy.remove(at: i)
        }
        
        return (extracted, copy)
    }
}
