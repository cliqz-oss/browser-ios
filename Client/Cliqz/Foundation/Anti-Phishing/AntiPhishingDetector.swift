//
//  AntiPhishingDetector.swift
//  Client
//
//  Created by Mahmoud Adam on 8/18/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class AntiPhishingDetector: NSObject {
    
    //MARK: - Singltone
    static let antiPhisingAPIURL = "http://antiphishing.cliqz.com/api/bwlist?md5="
    
    //MARK: - public APIs
    class func scanRequest(url: NSURL, completion:(Bool) -> Void) {
        
        guard url.host != "localhost" else {
            completion(false)
            return
        }
        
        if let host = url.host {
            
            let md5Hash = md5(host)
            
            let middelIndex = md5Hash.startIndex.advancedBy(16)
            
            let md5Prefix = md5Hash.substringToIndex(middelIndex)
            let md5Suffix = md5Hash.substringFromIndex(middelIndex)
            
            let antiPhishingURL = antiPhisingAPIURL + md5Prefix
            
            ConnectionManager.sharedInstance.sendRequest(.GET, url: antiPhishingURL, parameters: nil, responseType: .JSONResponse, onSuccess: { (result) in
                
                if let blacklist = result["blacklist"] as? [AnyObject] {
                    for suffixTuples in blacklist {
                        let suffixTuplesArray = suffixTuples as! [AnyObject]
                        if let suffix = suffixTuplesArray.first as? String
                            where md5Suffix == suffix {
                            completion(true)
                        }
                    }
                }
                }, onFailure: { (data, error) in
                    print(error)
                    completion(false)
            })
            
        }
    }
}
