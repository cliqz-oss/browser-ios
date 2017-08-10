//
//  NewsDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/19/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//This is the DataSource for News. 

import Alamofire

final class NewsDataSource {
    
    //here is where I should take care of computing the number of new articles. 
    //should show notification if the number of new articles is greater than zero
    //when pressing the news cell, set the number of new articles to zero.
    
    //how many news to fetch...Does not seem to have any effec. I receive all anyway.
    let news_to_fetch = 5
    
    //user defaults key 
    let userDefaultsKey_ArticleLinks = "ID_LAST_ARTICLE_LINKS"
    
    //notification name
    let notification_ready_name = "NotificationsNewsReady"
    
    static let sharedInstance = NewsDataSource()
    
    var ready = false
    var news_version: Int = 0
    var last_update_server: Int = 0
    var articles: [[String:AnyObject]] = []
    private var articleLinks: Set<String> = []
    private var new_article_count: Int = 0
    
    init() {
        let userDefaults = UserDefaults.standard
        if let art_links = userDefaults.value(forKey: userDefaultsKey_ArticleLinks) as? [String] {
            //I will use this to compute the number of new links from the backend.
            self.articleLinks = Set(art_links)
        }
        getNews(count: news_to_fetch)
    }
    
    func newArticlesAvailable() -> Bool{
        return self.new_article_count > 0
    }
    
    func newArticleCount() -> Int {
        return self.new_article_count
    }
    
    func setNewArticlesAsSeen(){
        self.new_article_count = 0
    }
    
    func save() {
        UserDefaults.standard.setValue(Array(self.articleLinks), forKey: userDefaultsKey_ArticleLinks)
        UserDefaults.standard.synchronize()
    }
    
    private func getNews(count:Int) { // -> [String: String]{
        
        ready = false
        
        let data = ["q": "","results": [[ "url": "rotated-top-news.cliqz.com",  "snippet":[String:String]()]]] as [String : Any]
        let userRegion = self.getDefaultRegion()
        let newsUrl = "https://newbeta.cliqz.com/api/v2/rich-header?"
        let uri = "path=/v2/map&q=&lang=N/A&locale=\(NSLocale.current.identifier)&country=\(userRegion)&adult=0&loc_pref=ask&count=\(count)"
        let final_uri = newsUrl + uri
        
        Alamofire.request(final_uri, method: .put, parameters: data, encoding: JSONEncoding.default , headers: nil).responseJSON { (response) in
            if response.result.isSuccess {
                
//                let dict = try! JSONSerialization.jsonObject(with: response, options: JSONSerialization.ReadingOptions.allowFragments)
//                
//                if let d = dict as? [String: [[String: AnyObject]]] {
//                    debugPrint(d)
//                }
                
                if let result_dict = response.result.value as? [String : [[String: AnyObject]]] {
                    if let result = result_dict["results"] {
                        if let snippet = result[0]["snippet"] as? [String: AnyObject],
                            let extra = snippet["extra"] as? [String: AnyObject],
                            let articles = extra["articles"] as? [[String: AnyObject]]
                        {
                            self.setLocalVariables(extra: extra, articles: articles)
                        }
                    }
                }
            }

        }
        
    }
    
    private func setLocalVariables(extra: [String: AnyObject], articles: [[String: AnyObject]]) {
        self.news_version = (extra["news_version"] as? NSNumber)?.intValue ?? 0
        self.last_update_server = (extra["last_update"] as? NSNumber)?.intValue ?? 0
        self.articles = articles
        
        let new_links = newLinks(articles: articles)
        self.new_article_count = newArticles(between: articleLinks, and: new_links)
        self.articleLinks = new_links
        
        self.ready = true
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notification_ready_name), object: nil)
    }
    
    private func newLinks(articles: [[String:AnyObject]]) -> Set<String> {
        var new_links:Set<String> = []
        
        for article in articles{
            if let link = article["url"] as? String{
                new_links.insert(link)
            }
        }
        
        return new_links
    }
    
    private func newArticles(between old_links: Set<String>, and new_links:Set<String>) -> Int {
        //get a list of all the new links
        let substract_set = new_links.subtracting(old_links)
        return substract_set.count
    }
    
    private func getDefaultRegion() -> String {
        let availableCountries = ["DE", "US", "UK", "FR"]
        let currentLocale = Locale.current
        if let countryCode = currentLocale.regionCode, availableCountries.contains(countryCode) {
            return countryCode
        }
//        if let countryCode = currentLocale.objectForKey(NSLocaleCountryCode) as? String, availableCountries.contains(countryCode) {
//            return countryCode
//        }
        return "DE"
    }
}
