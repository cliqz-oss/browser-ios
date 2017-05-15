//
//  HistoryDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import Shared
import Storage


struct Domain {
    let domainName: String
    let domainDetails: [DomainDetail]
    let date: NSDate? //this should be the date of the most recently accessed DomainDetail.
}

struct DomainDetail {
    var title: String
    let url: NSURL
    let date: NSDate?
}


final class HistoryModule: NSObject {
    
    class func getHistory(profile: Profile, completion:(result:[Domain]?, error:NSError?) -> Void) {
        //limit is static for now. 
        //later there will be a mechanism in place to handle a variable limit and offset.
        //It will keep a window of results that updates as the user scrolls.
        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        profile.history.getHistoryVisits(0, limit: 15).uponQueue(backgroundQueue) { (result) in
           let rawDomainDetails = processRawDataResults(result)
           let domainList       = processDomainDetails(rawDomainDetails)
           completion(result: domainList, error: nil) //TODO: there should be a better error handling mechanism here
        }
    }
    
    class func processRawDataResults(result: Maybe<Cursor<Site>>) -> [DomainDetail] {
        var historyResults: [DomainDetail] = []
        
        if let sites = result.successValue {
            for site in sites {
                if let domain = site, url = NSURL(string: domain.url) {
                    let title = domain.title
                    var date:NSDate?  = nil
                    if let latestDate = domain.latestVisit?.date {
                        date = NSDate(timeIntervalSince1970: Double(latestDate) / 1000000.0) // second = microsecond * 10^-6
                    }
                    let d = DomainDetail(title: title, url: url, date: date)
                    historyResults.append(d)
                }
            }
        }
        
        return historyResults
    }
    
    class func processDomainDetails(details: [DomainDetail]) -> [Domain] {
        
        //group domain details by domain.
        var domainName_to_details: [String: [String: DomainDetail]] = Dictionary()
        var domainName_to_date   : [String: NSDate] = Dictionary()
        
        //warning: Horrendous code. 
        //TODO: refactor
        //What am I doing here?
        //First I determine which Domain(s) I have in the list I receive
        //Second I make sure that each DomainDetail belonging to Domain is unique. I don't want multiple entries that are the same but have different dates. I take only the one with the most recent date. 
        //Third...some recent DomainDetail(s) miss the title sometimes, so I just take it from another DomainDetail with matching url.
        
        for detail in details {
            if let domainName = urlToDomain(detail.url), url_abs_string = detail.url.absoluteString {
                //add the details
                if var nested_dict = domainName_to_details[domainName] {
                    //nested dictionary
                    //inside dict is a mapping from detail.url -> DomainDetail with the most recent date
                    if let inside_domainDetail = nested_dict[url_abs_string] {
                        if inside_domainDetail.date?.timeIntervalSince1970 < detail.date?.timeIntervalSince1970 {
                            
                            var final_detail = detail
                            
                            if detail.title == "" {
                                final_detail.title = inside_domainDetail.title
                            }
                            nested_dict[url_abs_string] = final_detail
                        }
                    }
                    else{
                        nested_dict[url_abs_string] = detail
                    }
                }
                else{
                    domainName_to_details[domainName] = [url_abs_string : detail]
                }
                
                //check if the date can be replaced by a more recent one
                if domainName_to_date[domainName] != nil {
                    if domainName_to_date[domainName]?.timeIntervalSince1970 < detail.date?.timeIntervalSince1970 {
                        domainName_to_date[domainName] = detail.date
                    }
                }
                else{
                    domainName_to_date[domainName] = detail.date
                }
            }
        }
        
        //now contruct the Detail array. Each Detail object should be complete.
        
        var domainArray: [Domain] = []
        
        for domainName in domainName_to_details.keys {
            let domainDetailsArray = domainName_to_details[domainName]?.map({ (url, detail) -> DomainDetail in
                return detail
            })
            if let array = domainDetailsArray {
                let domain = Domain(domainName: domainName, domainDetails: array, date: domainName_to_date[domainName])
                domainArray.append(domain)
            }
        }
        
        return domainArray
    }
    
    class func urlToDomain(url:NSURL) -> String? {
        return url.baseDomain()
    }
    
}

final class HistoryDataSource: NSObject, HistoryProtocol {
    
    //Note: The mechanism is not robust enough to handle the failure of ConversationalHistoryAPI.getHistory
    //TO DO: Work on that.
    
    var domains: [Domain] = []
    
    let cliqzNews_header = "Cliqz News"
    let cliqzNews_title  = "Tap to Read"
    
    private var loading: Bool = false
    //Note: CompletionBlocks is not thread safe: I copy it when I iterate over it. 
    var completionBlocks: [((ready:Bool) -> Void)?] = []
    
    override init() {
        super.init()
        self.loadData(nil)
    }
    
    func loadData(completion:((ready:Bool) -> Void)?) {
        
        if loading == false {
            
            loading = true
            self.completionBlocks.append(completion)
            
            if let appDel = UIApplication.sharedApplication().delegate as? AppDelegate , profile = appDel.profile {
                HistoryModule.getHistory(profile, completion: { (result, error) in
                    dispatch_async(dispatch_get_main_queue(), {
                        self.domains = [Domain(domainName: "cliqz.com", domainDetails: [], date: nil)] //cliqz news.
                        if let domains = result {
                            self.domains.appendContentsOf(domains.sort({ (a, b) -> Bool in
                              return a.date?.timeIntervalSince1970 > b.date?.timeIntervalSince1970
                            }))
                        }
                        self.loading = false
                        let blocks = self.completionBlocks //array is a value type, as well as the clojures inside. So this is a deep copy (on demand = copies when needed).
                        for completion in blocks{
                            completion?(ready:true)
                        }
                        //elements could have been added in the meantime to completionBlocks, so take out only the first blocks.count
                        //take out the elements starting from the end, so the correspondence betweeen i and the indexes is not messed up.
                        for i in (0..<blocks.count).reverse() {
                            self.completionBlocks.removeAtIndex(i)
                        }
                    })
                })
            }
            
        }
        else {
            self.completionBlocks.append(completion)
        }
    }
    
    func sortedDomains(from domainsDict:NSDictionary) -> [String] {
        return domainsDict.keysSortedByValueUsingComparator({ (a, b) -> NSComparisonResult in
            if let dict_a = a as? [String: AnyObject], dict_b = b as? [String: AnyObject], time_a = dict_a["lastVisitedAt"] as? NSNumber, time_b = dict_b["lastVisitedAt"] as? NSNumber
            {
                return time_a.doubleValue > time_b.doubleValue ? .OrderedAscending : .OrderedDescending
            }
            return .OrderedSame
        }) as! [String]
    }
    
    func numberOfCells() -> Int {
        return self.domains.count
    }
    
    func urlLabelText(indexPath:NSIndexPath) -> String {
        if indexPath.row == 0{
            return cliqzNews_header
        }
        else if indexWithinBounds(indexPath){
            return domains[indexPath.row].domainName
        }
        
        return ""
    }
    
    func titleLabelText(indexPath:NSIndexPath) -> String {
        if indexPath.row == 0{
            return cliqzNews_title
        }
        else{
            return domains[indexPath.row].date?.toRelativeTimeString() ?? ""
        }
    }
    
    func timeLabelText(indexPath:NSIndexPath) -> String {
        return ""
    }
    
    func baseUrl(indexPath:NSIndexPath) -> String {
        if indexPath.row == 0{
            return "https://www.cliqz.com"
        }
        else{
            let domainDetail = domains[indexPath.row].domainDetails
            return domainDetail.first?.url.domainURL().absoluteString ?? ""
        }
    }
    
    func image(indexPath:NSIndexPath, completionBlock:(result:UIImage?) -> Void) {
        LogoLoader.loadLogoImageOrFakeLogo(self.baseUrl(indexPath), completed: { (image, fakeLogo, error) in
            if let img = image{
                completionBlock(result: img)
            }
            else{
                //completionBlock(result: UIImage(named: "coolLogo") ?? UIImage())
                completionBlock(result: nil)
            }
        })
    }
    
    func shouldShowNotification(indexPath:NSIndexPath) -> Bool {
        if indexPath.row == 0 && NewsDataSource.sharedInstance.newArticlesAvailable() {
            return true
        }
        return false
    }
    
    func notificationNumber(indexPath:NSIndexPath) -> Int {
        return NewsDataSource.sharedInstance.newArticleCount()
    }
    
//    func domainValue(forKey key: String, at indexPath:NSIndexPath) -> String? {
//        if indexWithinBounds(indexPath){
//            let domainDict = domain(at: indexPath)
//            if let timeinterval = domainDict[key] as? NSNumber {
//                return NSDate(timeIntervalSince1970: timeinterval.doubleValue / 1000000.0).toRelativeTimeString()
//            }
//            return domainDict[key] as? String
//        }
//        return ""
//    }
    
//    func domain(at indexPath:NSIndexPath) -> [String:AnyObject] {
//        return self.domainsInfo.valueForKey(self.domains[indexPath.row]) as? [String:AnyObject] ?? [:]
//    }
    
    func indexWithinBounds(indexPath:NSIndexPath) -> Bool {
        if indexPath.row < self.domains.count{
            return true
        }
        return false
    }
}
