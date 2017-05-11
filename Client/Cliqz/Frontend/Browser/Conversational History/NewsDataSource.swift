//
//  NewsDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/19/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//Note: Certainly not production ready.

import Alamofire

final class NewsDataSource{
    
    //here is where I should take care of computing the number of new articles. 
    //should show notification if the number of new articles is greater than zero
    //when pressing the news cell, set the number of new articles to zero.
    
    //how many news to fetch
    let news_to_fetch = 5
    
    //user defaults key 
    let userDefaultsKey_ArticleLinks = "ID_LAST_ARTICLE_LINKS"
    
    static let sharedInstance = NewsDataSource()
    
    var ready = false
    var news_version: Int = 0
    var last_update_server: Int = 0
    var articles: [[String:AnyObject]] = []
    private var articleLinks: Set<String> = []
    private var new_article_count: Int = 0
    
    init() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let art_links = userDefaults.valueForKey(userDefaultsKey_ArticleLinks) as? [String] {
            //I will use this to compute the number of new links from the backend.
            self.articleLinks = Set(art_links)
        }
        getNews(news_to_fetch)
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
    
    private func getNews(count:Int) { // -> [String: String]{
        
        ready = false
        
        let data = ["q": "","results": [[ "url": "rotated-top-news.cliqz.com",  "snippet":[String:String]()]]]
        let userRegion = self.getDefaultRegion()
        let newsUrl = "https://newbeta.cliqz.com/api/v2/rich-header?"
        let uri = "path=/v2/map&q=&lang=N/A&locale=\(NSLocale.currentLocale().localeIdentifier)&country=\(userRegion)&adult=0&loc_pref=ask&count=\(count)"
        
        Alamofire.request(.PUT, newsUrl + uri, parameters: data, encoding: .JSON, headers: nil).responseJSON { (response) in
            if response.result.isSuccess {
                if let result = response.result.value?["results"] as? [[String: AnyObject]] {
                    if let snippet = result[0]["snippet"] as? [String: AnyObject],
                        extra = snippet["extra"] as? [String: AnyObject],
                        articles = extra["articles"] as? [[String: AnyObject]]
                    {
                        self.setLocalVariables(extra, articles: articles)
                    }
                }
            }
        }
        
    }
    
    private func setLocalVariables(extra: [String: AnyObject], articles: [[String: AnyObject]]) {
        self.news_version = (extra["news_version"] as? NSNumber)?.integerValue ?? 0
        self.last_update_server = (extra["last_update"] as? NSNumber)?.integerValue ?? 0
        self.articles = articles
        
        let new_links = newLinks(articles)
        self.new_article_count = newArticles(between: articleLinks, and: new_links)
        self.articleLinks = new_links
        
        CINotificationManager.sharedInstance.newsVisisted = false
        
        self.ready = true
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
        let substract_set = new_links.subtract(old_links)
        return substract_set.count
    }
    
    private func getDefaultRegion() -> String {
        let availableCountries = ["DE", "US", "UK", "FR"]
        let currentLocale = NSLocale.currentLocale()
        if let countryCode = currentLocale.objectForKey(NSLocaleCountryCode) as? String where availableCountries.contains(countryCode) {
            return countryCode
        }
        return "DE"
    }
    
    func save() {
        NSUserDefaults.standardUserDefaults().setValue(Array(self.articleLinks), forKey: userDefaultsKey_ArticleLinks)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
