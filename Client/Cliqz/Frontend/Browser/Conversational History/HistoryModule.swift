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


struct DomainModel: Equatable {
	let id: Int
    let host: String //this is the url.host string
    var domainDetails: [DomainDetailModel]?
    let date: Date? //this should be the date of the most recently accessed DomainDetail.

	static func == (lhs: DomainModel, rhs: DomainModel) -> Bool {
		return lhs.id == rhs.id
	}
}

struct DomainDetailModel {
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
    
    class func getHistory(profile: Profile, completion: @escaping (_ result:[DomainModel]?, _ error:NSError?) -> Void) {
		getDomains(profile: profile) { (domains, error) in
		}
		
        //limit is static for now.
        //later there will be a mechanism in place to handle a variable limit and offset.
        //It will keep a window of results that updates as the user scrolls.
        let backgroundQueue = DispatchQueue.global(qos: .background)
        profile.history.getHistoryVisits(0, limit: 5000).uponQueue(backgroundQueue) { (result) in
            let rawDomainDetails = processRawDataResults(result: result)
            let domainList       = processDomainDetails(details: rawDomainDetails)
            completion(domainList, nil) //TODO: there should be a better error handling mechanism here
		}

        //getHistoryWithLimit(100, startFrame: 1494928155776220, endFrame: 1494928369784560, domain: NSString(string: "reuters.com"), resolve: { _ in}, reject: { _ in})
	}

	class func getDomains(profile: Profile, completion: @escaping (_ result:[DomainModel]?, _ error:NSError?) -> Void) {
		let backgroundQueue = DispatchQueue.global(qos: .background)
		profile.history.getHistoryDomains(limit: 0).uponQueue(backgroundQueue) {
			(result) in
			let domains = processDomainData(result: result)
			completion(domains, nil)
		}
	}

	class func removeDomain(profile: Profile, id: Int, completion: @escaping (_ success: Bool, _ error:NSError?) -> Void) {
		if profile.history.removeDomain(id).value.isSuccess {
			completion(true, nil)
		} else {
			completion(false, nil)
		}
	}

	class func processDomainData(result: Maybe<Cursor<Domain>>) -> [DomainModel] {
		var processedResults: [DomainModel] = []
		guard let domains = result.successValue else {
			return processedResults
		}

		for d in domains {
			if let newID = d?.id,
				let newHost = d?.name {
				let new = DomainModel(id: newID, host: newHost, domainDetails: nil, date: Date.fromMicrosecondTimestamp(d?.lastVisit ?? 0))
				processedResults.append(new)
			}
		}
		return processedResults
	}

	class func getDomainVisits(profile: Profile, domainID: Int, completion: @escaping (_ result:[DomainDetailModel]?, _ error:NSError?) -> Void) {
		profile.history.getHistoryVisits(forDomain: domainID).upon({ (result) in
			let processedResult = self.processRawDataResults(result: result)
			completion(processedResult, nil)
		})
	}

    class func processRawDataResults(result: Maybe<Cursor<Site>>) -> [DomainDetailModel] {
        var historyResults: [DomainDetailModel] = []
        
        if let sites = result.successValue {
            for site in sites {
                if let domain = site, let url = NSURL(string: domain.url) {
                    let title = domain.title
                    var date:Date?  = nil
                    if let latestDate = domain.latestVisit?.date {
                        date =  Date.fromMicrosecondTimestamp(latestDate)
                    }
                    let d = DomainDetailModel(title: title, url: url, date: date)
                    historyResults.append(d)
                }
            }
        }
        return historyResults
    }
    
    class func processDomainDetails(details: [DomainDetailModel]) -> [DomainModel] {
        
        func mostRecentDate(details:[DomainDetailModel]) -> Date? {
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
        
        func removeDuplicates(details: [DomainDetailModel]) -> [DomainDetailModel] {
            //duplicates can be identified by the title, or the url
            // I will take the url as the unique identifier
            
            
            var array: [DomainDetailModel] = []
            
            var group_by_url = GeneralUtils.groupBy(array: details) { (detail) -> NSURL in
                return detail.url
            }
            
            for url in group_by_url.keys {
                if let details = group_by_url[url] {
                    let most_recent_date = mostRecentDate(details: details)
                    array.append(DomainDetailModel(title: details.first?.title ?? "", url: url, date: most_recent_date))
                }
            }
            
            return array
            
        }
        
        var finalArray: [DomainModel] = []
        
        let clean_details = removeDuplicates(details: details)
        
        let groupedDetails_by_Domain = GeneralUtils.groupBy(array: clean_details) { (detail) -> String in
            return detail.url.host ?? ""
        }
        
        for domain in groupedDetails_by_Domain.keys {
            if let details = groupedDetails_by_Domain[domain] {
                //sort details
                let sorted_details = details.sorted(by: { (a, b) -> Bool in
                    if let date_a = a.date, let date_b = b.date {
                        return date_a > date_b
                    }
                    return false
                })
                
                let most_recent_date = mostRecentDate(details: details)
				finalArray.append(DomainModel(id: 0, host: domain, domainDetails: sorted_details, date: most_recent_date))
            }
        }
        
        return finalArray
        
    }
}
