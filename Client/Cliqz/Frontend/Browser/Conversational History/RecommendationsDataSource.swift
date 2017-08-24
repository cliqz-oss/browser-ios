//
//  RecommendationsDataSource.swift
//  Client
//
//  Created by Tim Palade on 8/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import WebImage

class RecommendationsDataSource: RecommendationsCollectionProtocol {
    
    var baseUrl: String
    var recommendations: [Recommendation]
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
        self.recommendations = RecommendationsManager.sharedInstance.recommendations(domain: URL(string: baseUrl))
    }
    
    func numberOfItems() -> Int {
        return recommendations.count
    }
    
    func cellType(indexPath: IndexPath) -> RecommendationsCellType {
        return .Recommendation
    }
    
    func text(indexPath: IndexPath) -> String {
        return recommendations[indexPath.row].text
    }
    
    func headerTitle(indexPath: IndexPath) -> String {
        return recommendations[indexPath.row].title
    }
    
    func picture(indexPath: IndexPath, completion: @escaping (UIImage?) -> Void) {
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
        return ""
    }
}
