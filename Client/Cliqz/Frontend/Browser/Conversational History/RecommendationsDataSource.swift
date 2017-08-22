//
//  RecommendationsDataSource.swift
//  Client
//
//  Created by Tim Palade on 8/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

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
    
    func date(indexPath: IndexPath) -> String {
        return ""
    }
    
    func picture(indexPath: IndexPath) -> UIImage? {
        return nil
    }
    
    func time(indexPath: IndexPath) -> String {
        return ""
    }
}
