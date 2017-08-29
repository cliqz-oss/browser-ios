//
//  HistoryModule.swift
//  Client
//
//  Created by Tim Palade on 5/16/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Shared
import Storage
import React


//This is the module that works with the History Database.


struct Domain {
    let domainName: String
    let domainDetails: [DomainDetail]
    let date: Date? //this should be the date of the most recently accessed DomainDetail.
}

struct DomainDetail {
    var title: String
    let url: NSURL
    let date: Date?
}

@objc(HistoryModule)
final class HistoryModule: NSObject {
    
    
    //getHistoryWithLimit:(nonnull NSInteger *)limit startFrame:(nonnull NSInteger *)startFrame endFrame:(nonnull NSInteger *)endFrame
    @objc(query:startFrame:endFrame:domain:resolve:reject:)
    func query(limit: NSNumber?, startFrame: NSNumber?, endFrame:NSNumber?, domain:NSString?, resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let profile = appDelegate.profile {
            
            var start_local = startFrame
            var end_local   = endFrame
            
            if startFrame?.intValue == 0 && endFrame?.intValue == 0 {
                start_local = nil
                end_local = nil
            }
            
            profile.history.getHistoryVisits(domain: (domain as String?) ?? "", timeStampLowerLimit: start_local?.intValue ?? nil , timeStampUpperLimit: end_local?.intValue ?? nil, limit: limit?.intValue ?? nil).upon({ (result) in
                let processedResult = self.processRawDataResults(result: result, domain:domain)
                resolve(processedResult)
            })
        }
    }
    
    func processRawDataResults(result: Maybe<Cursor<Site>>, domain: NSString?) -> NSDictionary {
        
        let v_key      = NSString(string: "places")
        let dom_key    = NSString(string: "domain")
        var returnDict: [NSString : AnyObject] = [dom_key : domain ?? "", v_key : NSArray()]
        
        if let sites = result.successValue {
            
            var historyResults: [NSDictionary] = []
            
            for site in sites {
                if let domain = site {
                    let title = NSString(string: domain.title)
                    let date  = NSNumber(value: Double(domain.latestVisit?.date ?? 0))
                    let url   = NSString(string: domain.url)
                    
                    let t_key = NSString(string: "title")
                    let d_key = NSString(string: "visit_date")
                    let u_key = NSString(string: "url")
                    
                    var d: [NSString: AnyObject] = [t_key: title, u_key: url]
                    if domain.latestVisit?.date != nil {
                        d[d_key] = date
                    }
                    
                    let dict = NSDictionary(dictionary: d)
                    
                    historyResults.append(dict)
                }
            }
            
            returnDict[v_key] = NSArray(array: historyResults)
        }
        
        return NSDictionary(dictionary: returnDict)
    }
    
    class func getHistory(profile: Profile, completion: @escaping (_ result:[Domain]?, _ error:NSError?) -> Void) {
        //limit is static for now.
        //later there will be a mechanism in place to handle a variable limit and offset.
        //It will keep a window of results that updates as the user scrolls.
        let backgroundQueue = DispatchQueue.global(qos: .background)
        profile.history.getHistoryVisits(0, limit: 1000).uponQueue(backgroundQueue) { (result) in
            let rawDomainDetails = processRawDataResults(result: result)
            let domainList       = processDomainDetails(details: rawDomainDetails)
            completion(domainList, nil) //TODO: there should be a better error handling mechanism here
        }
        
        //getHistoryWithLimit(100, startFrame: 1494928155776220, endFrame: 1494928369784560, domain: NSString(string: "reuters.com"), resolve: { _ in}, reject: { _ in})
        
    }
    
    class func processRawDataResults(result: Maybe<Cursor<Site>>) -> [DomainDetail] {
        var historyResults: [DomainDetail] = []
        
        if let sites = result.successValue {
            for site in sites {
                if let domain = site, let url = NSURL(string: domain.url) {
                    let title = domain.title
                    var date:Date?  = nil
                    if let latestDate = domain.latestVisit?.date {
                        date = Date(timeIntervalSince1970: Double(latestDate) / 1000000.0) // second = microsecond * 10^-6
                    }
                    let d = DomainDetail(title: title, url: url, date: date)
                    historyResults.append(d)
                }
            }
        }
        
        return historyResults
    }
    
    class func processDomainDetails(details: [DomainDetail]) -> [Domain] {
        
        func mostRecentDate(details:[DomainDetail]) -> Date? {
            guard details.count > 0 else {
                return nil
            }
            var most_recent_date = details.first?.date
            for detail in details {
                if let detail_date = detail.date, let max = most_recent_date {
                    if detail_date > max {
                        most_recent_date = detail_date
                    }
                }
            }
            
            return most_recent_date ?? nil
        }
        
        func removeDuplicates(details: [DomainDetail]) -> [DomainDetail] {
            //duplicates can be identified by the title, or the url
            // I will take the url as the unique identifier
            
            
            var array: [DomainDetail] = []
            
            var group_by_url = GeneralUtils.groupBy(array: details) { (detail) -> NSURL in
                return detail.url
            }
            
            for url in group_by_url.keys {
                if let details = group_by_url[url] {
                    let most_recent_date = mostRecentDate(details: details)
                    array.append(DomainDetail(title: details.first?.title ?? "", url: url, date: most_recent_date))
                }
            }
            
            return array
            
        }
        
        var finalArray: [Domain] = []
        
        let clean_details = removeDuplicates(details: details)
        
        let groupedDetails_by_Domain = GeneralUtils.groupBy(array: clean_details) { (detail) -> String in
            return detail.url.host ?? ""
        }
        
        for domain in groupedDetails_by_Domain.keys {
            if let details = groupedDetails_by_Domain[domain] {
                let most_recent_date = mostRecentDate(details: details)
                finalArray.append(Domain(domainName: domain, domainDetails: details, date: most_recent_date))
            }
        }
        
        return finalArray
        
    }
}
