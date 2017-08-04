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
    
    var bloomFilter: BloomFilter? = nil
    
    func turnOn() {
        if bloomFilter == nil && SettingsPrefs.getAutoForgetTabPref() == true {
            DispatchQueue.global(qos: .background).async {
                self.load()
            }
        }
    }
    
    func turnOff() {
        bloomFilter = nil
    }
    
    private func load() {
        guard let filter_path = Bundle.main.path(forResource: "bloomData", ofType: "bloom") else { return }
        let filter_url  = URL(fileURLWithPath: filter_path)
        do {
            let filter_data = try Data(contentsOf: filter_url, options: .alwaysMapped)
            bloomFilter = BloomFilter.unarchived(fromData: filter_data)
        }
        catch {
            //error
        }
    }
    
    func shouldOpenInPrivateTab(url:URL, currentTab: Tab?) -> Bool {
        guard let filter = bloomFilter else { return false }
        guard let host = url.host else { return false }
        if let tab = currentTab {
            if tab.isPrivate {
                return false
            }
        }
        return filter.query(cleanHost(host: host)) 
    }
    
    func cleanHost(host: String) -> String {
        var components = host.components(separatedBy: ".")
        if let first_part = components.first {
            if first_part == "www" || first_part == "m" {
                components.remove(at: 0)
                return components.reduce("", { (result, a) -> String in
                    if result == "" {
                        return a
                    }
                    return result + "." + a
                })
            }
        }
        
        return host
    }
    
}
