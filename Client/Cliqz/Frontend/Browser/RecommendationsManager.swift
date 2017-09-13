//
//  RecommendationsManager.swift
//  Client
//
//  Created by Tim Palade on 8/22/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

enum RecommendationType {
    case news
}

struct Recommendation {
    let type: RecommendationType
    let title: String
    let url: String
    let host: String
    let text: String
    let picture_url: String
}

final class RecommendationsManager {
    
    enum RecommendationType {
        case withHistoryDomains
        case withoutHistoryDomains
    }
    
    static let sharedInstance = RecommendationsManager()
    
    static let notification_updated = NSNotification.Name(rawValue: "RecomandationsManagerUpdated")
    
    private var recommendations: [Recommendation] = []
    
    static let newsIgnoreListID = "NewsIgnoreList"
    
    private var newsIgnoreList: NewsIgnoreList = NewsIgnoreList(identifier: RecommendationsManager.newsIgnoreListID)
    
    init() {
        self.loadRecommendations()
        NotificationCenter.default.addObserver(self, selector: #selector(newsUpdated), name: NewsManager.notification_updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(domainsUpdated), name: DomainsModule.notification_updated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadRecommendations() {
        if NewsManager.sharedInstance.ready {
            let news_articles = NewsManager.sharedInstance.articles
            let news_recommendations = convertArticles2Recommendations(articles: news_articles)
            recommendations += news_recommendations
            
            stateChanged()
        }
    }
    
    func removeRecommendation(recommendation: Recommendation) {
        if recommendation.type == .news {
            newsIgnoreList.add(element: recommendation.url)
        }
        
        stateChanged()
    }
    
    func stateChanged() {
        NotificationCenter.default.post(name: RecommendationsManager.notification_updated, object: nil)
    }
    
    private func convertArticles2Recommendations(articles: [[String: Any]]) -> [Recommendation] {
        var array: [Recommendation] = []
        for article in articles {
            array.append(article2Recommendation(article: article))
        }
        return array
    }
    
    private func article2Recommendation(article: [String: Any]) -> Recommendation {

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
        
        return Recommendation(type: .news, title: title, url: url, host: host, text: description, picture_url: media_link)
        
    }
    
    //if domain is nil returns all recommendations
    func recommendations(domain: URL?, type: RecommendationType) -> [Recommendation] {
        
        let local_recommendations = type == .withoutHistoryDomains ? recommendationsWithoutHistoryDomains(recommedations: self.recommendations) : self.recommendations
        
        if let domain = domain {
            
            var baseUrl: String = ""
            
            if domain.baseURL == nil {
                baseUrl = domain.absoluteString
            }
            else {
                baseUrl = domain.host ?? ""
            }
            
            return local_recommendations.filter({ (recommendation) -> Bool in
                return baseUrl == recommendation.host
            })
            
        }
        
        return filterOutIgnoredRecommendations(recommendations: local_recommendations)
    }
    
    private func recommendationsWithoutHistoryDomains(recommedations: [Recommendation]) -> [Recommendation] {
        //filter rule: News with a domain that matches any domain in the history should be eliminated. Those news are presented in History Details.
        
        //get a list of all domains in the history
        let domains = DomainsModule.sharedInstance.domains.map { (domain_struct) -> String in
            return domain_struct.host
        }
        
        let host_set = Set.init(domains)
        
        return self.recommendationsWithoutHosts(hosts: host_set)
    }
    
    private func recommendationsWithoutHosts(hosts: Set<String>) -> [Recommendation] {
        return recommendations.filter({ (reccomendation) -> Bool in
            return !hosts.contains(reccomendation.host)
        })
    }
    
    private func filterOutIgnoredRecommendations(recommendations: [Recommendation]) -> [Recommendation] {
        return recommendations.filter({ (recommendation) -> Bool in
            if recommendation.type == .news {
                return !newsIgnoreList.contains(element: recommendation.url)
            }
            
            return true
        })
    }
    
    @objc
    private func newsUpdated(_ sender: Notification) {
        self.loadRecommendations()
    }
    
    @objc
    private func domainsUpdated(_ sender: Notification) {
        //Recommendations depend on the Domains. So when the domains change the list of recommendations without hosts changes. Thus we send a notification.
         NotificationCenter.default.post(name: RecommendationsManager.notification_updated, object: nil)
    }
    
}
