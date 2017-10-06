//
//  RecommendationsDataSource.swift
//  Client
//
//  Created by Tim Palade on 8/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import WebImage

class RecommendationsDataSource: RecommendationsCollectionProtocol {
    
    static let identifier = "RecommendationsDataSource"
    
    var baseUrl: String
    var recommendations: [Recommendation]
    
    weak var delegate: HasDataSource? = nil
    
    private let standardTimeFormat = "HH:mm"
    private let standardTimeFormatter = DateFormatter()
    
    private let standardDateFormat = "dd-MM-yyyy"
    private let standardDateFormatter = DateFormatter()
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
        self.recommendations = RecommendationsManager.sharedInstance.recommendations(domain: URL(string: baseUrl), type: .withHistoryDomains)
        self.standardTimeFormatter.dateFormat = standardTimeFormat
        self.standardDateFormatter.dateFormat = standardDateFormat
        NotificationCenter.default.addObserver(self, selector: #selector(recommendationsUpdated), name: RecommendationsManager.notification_updated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadRecommendations() {
        self.recommendations = RecommendationsManager.sharedInstance.recommendations(domain: URL(string: baseUrl), type: .withHistoryDomains) 
    }
    
    func numberOfItems() -> Int {
        return recommendations.count
    }
    
    func cellType(indexPath: IndexPath) -> RecommendationsCellType {
        guard isIndexPathValid(indexPath: indexPath) else {
            return .Recommendation
        }
        
        if recommendations[indexPath.row].type == .reminder {
            return .Reminder
        }
        
        return .Recommendation
    }
    
    func text(indexPath: IndexPath) -> String {
        guard isIndexPathValid(indexPath: indexPath) else {
            return ""
        }
        
        if recommendations[indexPath.row].type == .reminder {
            return recommendations[indexPath.row].title
        }
        
        return recommendations[indexPath.row].text
    }
    
    func headerTitle(indexPath: IndexPath) -> String {
        guard isIndexPathValid(indexPath: indexPath) else {
            return ""
        }
        
        if recommendations[indexPath.row].type == .reminder, let date = recommendations[indexPath.row].date {
            
            let reminderDayMonthYear = date.dayMonthYear()
            let todayDayMonthYear    = Date().dayMonthYear()
            
            if reminderDayMonthYear == todayDayMonthYear {
                return "Today"
            }
            else if reminderDayMonthYear.day == (todayDayMonthYear.day + 1) && reminderDayMonthYear.month == todayDayMonthYear.month && reminderDayMonthYear.year == todayDayMonthYear.year {
                return "Tomorrow"
            }
            
            return self.standardDateFormatter.string(from: date)
        }
        
        return recommendations[indexPath.row].title
    }
    
    func picture(indexPath: IndexPath, completion: @escaping (UIImage?, UIView?) -> Void) {
        guard isIndexPathValid(indexPath: indexPath) else {
            completion(nil, nil)
            return
        }
        
        guard recommendations[indexPath.row].type == .news else {
            completion(nil, nil)
            return
        }
        
        let url_str = recommendations[indexPath.row].picture_url
        if let url = URL(string: url_str) {
            SDWebImageManager.shared().downloadImage(with: url, options: .highPriority, progress: { (receivedSize, expectedSize) in
                //
            }, completed: { (image, error, cacheType, finished, url) in
                completion(image, nil)
            })
        }
    }
    
    func time(indexPath: IndexPath) -> String {
        guard isIndexPathValid(indexPath: indexPath) else {
            return ""
        }
        
        guard recommendations[indexPath.row].type == .reminder else {
            return ""
        }
        
        guard let date = recommendations[indexPath.row].date else {
            return ""
        }
        
        return self.standardTimeFormatter.string(from: date)
    }
    
    func url(indexPath: IndexPath) -> String {
        guard isIndexPathValid(indexPath: indexPath) else {
            return ""
        }
        
        return recommendations[indexPath.row].url
    }
    
    func deletePressed(indexPath: IndexPath) {
        guard isIndexPathValid(indexPath: indexPath) else {
            return
        }
        
        RecommendationsManager.sharedInstance.removeRecommendation(recommendation: recommendations[indexPath.row])
    }
    
    func isIndexPathValid(indexPath: IndexPath) -> Bool {
        return indexPath.row >= 0 && indexPath.row < recommendations.count
    }
    
    @objc func recommendationsUpdated(_ notification: Notification) {
        loadRecommendations()
        delegate?.dataSourceWasUpdated(identifier: RecommendationsDataSource.identifier)
    }
    
    
}
