//
//  BloomFilterManager.swift
//  Client
//
//  Created by Tim Palade on 7/11/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//WARNING: The Bloomfilter file is generated using a different project (https://github.com/timotei-cliqz/BloomFilterGenerator.git)
//Generate the file and place it in this project
//Make sure that the BloomFilter file and the BitArray file coincide in this project with the ones in the project that is used to generate the bloom file.


import UIKit

class BloomFilterManager: NSObject {
    
    static let sharedInstance = BloomFilterManager()
    
    var failedInit: Bool = false
    var bloomFilter: BloomFilter? = nil
    
    override init() {
        super.init()
        guard let filter_path = Bundle.main.path(forResource: "bloomData", ofType: "bloom") else { failedInit = true; return }
        let filter_url  = URL(fileURLWithPath: filter_path)
        do {
            let filter_data = try Data(contentsOf: filter_url, options: .alwaysMapped)
            bloomFilter = BloomFilter.unarchived(fromData: filter_data)
            if bloomFilter == nil {
                failedInit = true
            }
        }
        catch {
            failedInit = true
        }
    }
    
    func shouldOpenInPrivateTab(url:URL) -> Bool {
        guard failedInit == false else { return false }
        guard let host = url.host else { return false }
        return bloomFilter?.query(host) ?? false
    }
    
}
