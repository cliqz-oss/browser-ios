//
//  HistoryDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import RealmSwift
//The data source for the ConversationalHistory View. 

final class DomainsDataSource: NSObject, DomainsProtocol {
    
    //This still needs work
    //Loads every time this view is shown. This can be problematic with big history. Need to handle that.
    
    var domains: Results<Domain>
    
    var notificationToken: NotificationToken? = nil
    
    let cliqzNews_header = "Cliqz News"
    let cliqzNews_title  = "Tap to Read"
    
    weak var delegate: HasDataSource?
    
    override init() {
        
        let realm = try! Realm()
        domains = realm.objects(Domain.self).sorted(byKeyPath: "last_timestamp", ascending: false)
        
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(reminderFired), name: CIReminderManager.notification_fired, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newsUpdated), name: NewsManager.notification_updated, object: nil)
        
        notificationToken = domains.observe { [weak self] (changes: RealmCollectionChange) in

            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                self?.update()
            case .update(_, _, _, _):
                // Query results have changed, so apply them to the UITableView
                self?.update()
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }

        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        notificationToken?.invalidate()
    }

    func numberOfCells() -> Int {
        return self.domains.count
    }

    func urlLabelText(indexPath: IndexPath) -> String {
        return domains[indexPath.row].name
    }

    func titleLabelText(indexPath:IndexPath) -> String {
        return domains[indexPath.row].last_timestamp.toRelativeTimeString()
    }

    func timeLabelText(indexPath: IndexPath) -> String {
        return ""
    }

    func baseUrl(indexPath: IndexPath) -> String {
		return domains[indexPath.row].name
    }

	func image(indexPath: IndexPath, completionBlock: @escaping (_ image: UIImage?, _ customView: UIView?) -> Void) {
        
        let baseUrl = self.baseUrl(indexPath: indexPath)
        
        DispatchQueue(label:"background").async {
            LogoLoader.loadLogo(baseUrl) { (image, logoInfo, error) in
                if let img = image {
                    DispatchQueue.main.async {
                        completionBlock(img, nil)
                    }
                } else {
                    if let info = logoInfo {
                        DispatchQueue.main.async {
                            let logoPlaceholder = LogoPlaceholder.init(logoInfo: info)
                            completionBlock(nil, logoPlaceholder)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completionBlock(nil, nil)
                        }
                    }
                }
            }
        }
    }
    
    func shouldShowNotification(indexPath:IndexPath) -> Bool {
        if ReminderNotificationManager.shared.notificationsFor(host: baseUrl(indexPath: indexPath)) > 0 || NewsNotificationManager.shared.newArticlesCount(host: baseUrl(indexPath: indexPath)) > 0 {
            return true
        }
        return false
    }
 
    func notificationNumber(indexPath:IndexPath) -> Int {
        return ReminderNotificationManager.shared.notificationsFor(host: baseUrl(indexPath: indexPath)) + NewsNotificationManager.shared.newArticlesCount(host: baseUrl(indexPath: indexPath))
    }
    
    func indexWithinBounds(indexPath:IndexPath) -> Bool {
        if indexPath.row < self.domains.count {
            return true
        }
        return false
    }
    
    @objc
    func reminderFired(_ notification: Notification) {
        update()
    }
    
    @objc
    func newsUpdated(_ notification: Notification) {
        update()
    }
    
    private func update() {
        delegate?.dataSourceWasUpdated(identifier: "DomainsDataSource")
    }

	func removeDomain(at index: Int) {
        guard isIndexValid(index: index) else { return }
        RealmStore.removeDomain(domain: domains[index])
	}
    
    func isIndexValid(index: Int) -> Bool {
        return index >= 0 && index < domains.count
    }
    
}
