//
//  FreshTabUtils.swift
//  Client
//
//  Created by Tim Palade on 2/2/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

class TopSiteItem{
    //let id:       Int
    var url:      String
    //let title:    String
    var image:    UIImage?
    var fakeLogo: UIView?
    
    init(url: String){
        self.url = url
    }
}

final class TopSiteManager{
    var topSiteDict: [String: TopSiteItem] = [String: TopSiteItem]()
    var logoL: LogoLoader = LogoLoader.init()
    
    static var shared = TopSiteManager()
    
    private init(){
        
    }
    
    func update(topSites: [[String: String]]?){
        guard topSites != nil else {return}
        var notToRemove = Set<String>()
        for dict in topSites! {
            let url = dict["url"]
            if url == nil && url == "" {continue}
            guard let host = self.hostName(url!) else {continue}
            
            notToRemove.insert(host)
            
            if topSiteDict[host] == nil {
                let tsclass = TopSiteItem.init(url: url!)
                tsclass.fakeLogo = getFakeLogo(url)
                getLogoImage(url!, topSite: tsclass)
                self.topSiteDict[host] = tsclass
            }
        }
        
        for host in topSiteDict.keys{
            if !notToRemove.contains(host){
                topSiteDict[host] = nil
            }
        }
        
    }
    
    func hostName(url:String) -> String? {
        return logoL.getHostComponents(forURL: url)[0]
    }
    
    private func getFakeLogo(url:String?) -> UIView?{
        return logoL.generateFakeLogo(url)
    }
    
    private func getLogoImage(url:String, topSite: TopSiteItem?){
        logoL.loadLogo(url) { (image, error) in
            guard (image   != nil) else {return}
            guard (topSite != nil) else {return}
            topSite!.image  = image
        }
    }
}

class TopNewsItem{
    //let id:       Int
    var url:      String
    //let title:    String
    var image:    UIImage?
    var fakeLogo: UIView?
    
    init(url: String){
        self.url = url
    }
}

final class TopNewsManager{
    var topNewsDict: [String: TopNewsItem] = [String: TopNewsItem]()
    var logoL: LogoLoader = LogoLoader.init()
    
    static var shared = TopNewsManager()
    
    private init(){
        
    }
    
    func update(topNews: [[String: AnyObject]]){
        var notToRemove = Set<String>()
        for dict in topNews {
            let url = dict["url"] as? String
            if url == nil && url == "" {continue}
            guard let host = self.hostName(url!) else {continue}
            
            notToRemove.insert(host)
            
            if topNewsDict[host] == nil {
                let tsclass = TopNewsItem.init(url: url!)
                tsclass.fakeLogo = getFakeLogo(url)
                getLogoImage(url!, topSite: tsclass)
                self.topNewsDict[host] = tsclass
            }
        }
        
        for host in topNewsDict.keys{
            if !notToRemove.contains(host){
                topNewsDict[host] = nil
            }
        }
        
    }
    
    func hostName(url:String) -> String? {
        return logoL.getHostComponents(forURL: url)[0]
    }
    
    private func getFakeLogo(url:String?) -> UIView?{
        return logoL.generateFakeLogo(url)
    }
    
    private func getLogoImage(url:String, topSite: TopNewsItem?){
        logoL.loadLogo(url) { (image, error) in
            guard (image   != nil) else {return}
            guard (topSite != nil) else {return}
            topSite!.image  = image
        }
    }
}

