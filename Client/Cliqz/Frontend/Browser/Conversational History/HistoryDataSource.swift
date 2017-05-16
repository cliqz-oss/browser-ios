//
//  HistoryDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

//The data source for the ConversationalHistory View. 

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
                        let blocks = self.completionBlocks //array is a value type, as well as the clojures inside. So this is a deep copy on demand (= copies when needed).
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
    
    func indexWithinBounds(indexPath:NSIndexPath) -> Bool {
        if indexPath.row < self.domains.count{
            return true
        }
        return false
    }
}
