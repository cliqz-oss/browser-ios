//
//  RecommendationsManager.swift
//  Client
//
//  Created by Tim Palade on 8/22/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

struct Recommendation {
    let title: String
    let url: String
    let host: String
    let text: String
    let picture_url: String
}

final class RecommendationsManager {
    
    static let sharedInstance = RecommendationsManager()
    
    static let notification_updated = NSNotification.Name(rawValue: "RecomandationsManagerUpdated")
    
    private var recommendations: [Recommendation] = []
    
    init() {
        self.loadRecommendations()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadRecommendations() {
        if NewsManager.sharedInstance.ready {
            let news_articles = NewsManager.sharedInstance.articles
            let news_recommendations = convertArticles2Recommendations(articles: news_articles)
            recommendations += news_recommendations
            
            NotificationCenter.default.post(name: RecommendationsManager.notification_updated, object: nil)
        }
        else {
            NotificationCenter.default.addObserver(self, selector: #selector(newsReady), name: NewsManager.notification_updated, object: nil)
        }
    }
    
    func convertArticles2Recommendations(articles: [[String: Any]]) -> [Recommendation] {
        var array: [Recommendation] = []
        for article in articles {
            array.append(article2Recommendation(article: article))
        }
        return array
    }
    
    func article2Recommendation(article: [String: Any]) -> Recommendation {

        var title = ""
        var media_link = ""
        var description = ""
        var url = ""
        var host = ""
        
        if let t = article["title"] as? String {
            title = t
        }
        
        if let m = article["media"] as? String {
            media_link = m
        }
        
        if let d = article["description"] as? String {
            description = d
        }
        
        if let u = article["url"] as? String {
            url = u
            if let some_url = URL(string: u) {
                if let h = some_url.host {
                    host = h
                }
            }
        }
        
        return Recommendation(title: title, url: url, host: host, text: description, picture_url: media_link)
        
    }
    
    //if domain is nil returns all recommendations
    func recommendations(domain: URL?) -> [Recommendation] {
        
        if let domain = domain {
            
            var baseUrl: String = ""
            
            if domain.baseURL == nil {
                baseUrl = domain.absoluteString
            }
            else {
                baseUrl = domain.host ?? ""
            }
            
            return recommendations.filter({ (recommendation) -> Bool in
                return baseUrl == recommendation.host
            })
            
        }
        
        return recommendations
    }
    
    func recommendationsWithoutHosts(hosts: Set<String>) -> [Recommendation] {
        return recommendations.filter({ (reccomendation) -> Bool in
            return !hosts.contains(reccomendation.host)
        })
    }
    
    @objc
    private func newsReady(_ sender: Notification) {
        self.loadRecommendations()
    }
}
