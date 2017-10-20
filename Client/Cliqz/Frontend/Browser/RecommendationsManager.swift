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
    case reminder
}

struct Recommendation {
    let type: RecommendationType
    let title: String
    let url: String
    let host: String
    let text: String
    let picture_url: String
    let date: Date?
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
        NotificationCenter.default.addObserver(self, selector: #selector(remindersUpdated), name: CIReminderManager.notification_update, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadRecommendations() {
        
        recommendations = []
        
        if NewsManager.sharedInstance.ready {
            let news_articles = NewsManager.sharedInstance.articles
            let news_recommendations = convertArticles2Recommendations(articles: news_articles)
            recommendations += news_recommendations
        }
        
        let reminders = CIReminderManager.sharedInstance.allValidReminders()
        let reminders_recommendations = convertReminders2Recommendations(reminders: reminders)
        recommendations += reminders_recommendations
        
        stateChanged()
    }
    
    func removeRecommendation(recommendation: Recommendation) {
        if recommendation.type == .news {
            newsIgnoreList.add(element: recommendation.url)
        }
        else if recommendation.type == .reminder {
            if let date = recommendation.date {
                CIReminderManager.sharedInstance.unregisterReminder(url: recommendation.url, title: recommendation.title, date: date)
            }
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
        
        return Recommendation(type: .news, title: title, url: url, host: host, text: description, picture_url: media_link, date: nil)
        
    }
    
    private func convertReminders2Recommendations(reminders: [CIReminderManager.Reminder]) -> [Recommendation] {
        var array: [Recommendation] = []
        for reminder in reminders {
            array.append(reminder2Recommendation(reminder: reminder))
        }
        return array
    }
    
    private func reminder2Recommendation(reminder: CIReminderManager.Reminder) -> Recommendation {
        
        var title = ""
        var media_link = ""
        var description = ""
        var url = ""
        var host = ""
        var date: Date? = nil
        
        if let t = reminder["title"] as? String {
            title = t
        }
        
        if let u = reminder["url"] as? String {
            url = u
            if let some_url = URL(string: u) {
                if let h = some_url.host {
                    host = h
                }
            }
        }
        
        if let d = reminder["date"] as? Date {
            date = d
        }
        
        return Recommendation(type: .reminder, title: title, url: url, host: host, text: description, picture_url: media_link, date: date)
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
            
            let domain_recommendations = local_recommendations.filter({ (recommendation) -> Bool in
                return baseUrl == recommendation.host
            })
            
            let filtered_recommendations = filterOutIgnoredRecommendations(recommendations: domain_recommendations)
            
            return filtered_recommendations
            
        }
        
        return filterOutIgnoredRecommendations(recommendations: local_recommendations)
    }
    
    private func recommendationsWithoutHistoryDomains(recommedations: [Recommendation]) -> [Recommendation] {
        //filter rule: News with a domain that matches any domain in the history should be eliminated. Those news are presented in History Details.
        
        //get a list of all domains in the history
        let domains = DomainsModule.shared.domains.map { (domain_struct) -> String in
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
         stateChanged()
    }
    
    @objc
    private func remindersUpdated(_ notification: Notification) {
        self.loadRecommendations()
    }
    
}
