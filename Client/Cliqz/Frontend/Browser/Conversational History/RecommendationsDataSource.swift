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
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
        self.recommendations = RecommendationsManager.sharedInstance.recommendations(domain: URL(string: baseUrl), type: .withHistoryDomains)
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
        return .Recommendation
    }
    
    func text(indexPath: IndexPath) -> String {
        guard isIndexPathValid(indexPath: indexPath) else {
            return ""
        }
        
        return recommendations[indexPath.row].text
    }
    
    func headerTitle(indexPath: IndexPath) -> String {
        guard isIndexPathValid(indexPath: indexPath) else {
            return ""
        }
        
        return recommendations[indexPath.row].title
    }
    
    func picture(indexPath: IndexPath, completion: @escaping (UIImage?) -> Void) {
        guard isIndexPathValid(indexPath: indexPath) else {
            completion(nil)
            return
        }
        
        let url_str = recommendations[indexPath.row].picture_url
        if let url = URL(string: url_str) {
            SDWebImageManager.shared().downloadImage(with: url, options: .highPriority, progress: { (receivedSize, expectedSize) in
                //
            }, completed: { (image, error, cacheType, finished, url) in
                completion(image)
            })
        }
    }
    
    func time(indexPath: IndexPath) -> String {
        guard isIndexPathValid(indexPath: indexPath) else {
            return ""
        }
        
        return ""
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
