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
    
    class func getHistory(profile: Profile, completion:@escaping (_ result:[Domain]?, _ error:NSError?) -> Void) {
        //limit is static for now.
        //later there will be a mechanism in place to handle a variable limit and offset.
        //It will keep a window of results that updates as the user scrolls.
        let backgroundQueue = DispatchQueue.global()
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
        
        //group domain details by domain.
        var domainName_to_details: [String: [String: DomainDetail]] = Dictionary()
        var domainName_to_date   : [String: Date] = Dictionary()
        
        //warning: Non-elegant code.
        //TODO: refactor
        //What am I doing here?
        //First I determine which Domain(s) I have in the list I receive
        //Second I make sure that each DomainDetail belonging to Domain is unique. I don't want multiple entries that are the same but have different dates. I take only the one with the most recent date.
        //Third...some recent DomainDetail(s) miss the title sometimes, so I just take it from another DomainDetail with matching url.
        
        for detail in details {
            if let domainName = urlToDomain(url: detail.url), let url_abs_string = detail.url.absoluteString {
                //add the details
                if var nested_dict = domainName_to_details[domainName] {
                    //nested dictionary
                    //inside dict is a mapping from detail.url -> DomainDetail with the most recent date
                    if let inside_domainDetail = nested_dict[url_abs_string] {
                        if inside_domainDetail.date! < detail.date! {
                            
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
                    if  domainName_to_date[domainName]! <  detail.date! {//domainName_to_date[domainName]?.timeIntervalSince1970 < detail.date?.timeIntervalSince1970 {
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
        return url.baseURL?.baseDomain()
    }
    
}




extension Date {
    static public func ==(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedSame
    }
    
    static public func <(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
}
