//
//  CliqzHistoryDetailsDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class CliqzHistoryDetailsDataSource: HistoryDetailsProtocol{
    
    var img: UIImage?
    var domainDetails: [DomainDetail]
    
    init(image:UIImage?, domainDetails: [DomainDetail]) {
        self.img = image
        self.domainDetails = domainDetails.sort({ (a, b) -> Bool in
            return a.date?.timeIntervalSince1970 > b.date?.timeIntervalSince1970
        })
    }
    
    func image() -> UIImage? {
        return self.img
    }
    
    func urlLabelText(indexPath: NSIndexPath) -> String {
        return detail(indexPath)?.url.absoluteString ?? ""
    }
    
    func titleLabelText(indexPath: NSIndexPath) -> String {
        return detail(indexPath)?.title ?? ""
    }
    
    func timeLabelText(indexPath: NSIndexPath) -> String {
        return detail(indexPath)?.date?.toRelativeTimeString() ?? ""
    }
    
    func numberOfCells() -> Int {
        return domainDetails.count
    }
    
    func baseUrl() -> String {
        return domainDetails.first?.url.domainURL().absoluteString ?? ""
    }
    
    func isNews() -> Bool {
        return false
    }
    
    func detail(indexPath:NSIndexPath) -> DomainDetail? {
        if indexWithinBounds(indexPath) {
            return domainDetails[indexPath.row]
        }
        return nil
    }
    
    func indexWithinBounds(indexPath:NSIndexPath) -> Bool {
        if indexPath.row < self.domainDetails.count{
            return true
        }
        return false
    }
    
}
