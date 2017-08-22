//
//  CliqzHistoryDetailsDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class DomainDetailsDataSource: DomainDetailsHeaderViewProtocol, BubbleTableViewDataSource {

    var img: UIImage?
    var domainDetails: [DomainDetail]
    
    init(image:UIImage?, domainDetails: [DomainDetail]) {
        self.img = image
        self.domainDetails = domainDetails.sorted(by: { (a, b) -> Bool in
            if let date_a = a.date, let date_b = b.date {
                return date_a > date_b
            }
            return false
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func image() -> UIImage? {
        return self.img
    }
    
    func url(indexPath: IndexPath) -> String {
        return detail(indexPath: indexPath)?.url.absoluteString ?? ""
    }
    
    func title(indexPath: IndexPath) -> String {
        return detail(indexPath: indexPath)?.title ?? ""
    }
    
    func titleSectionHeader(section: Int) -> String {
        return "Today"
    }
    
    func time(indexPath: IndexPath) -> String {
        return detail(indexPath: indexPath)?.date?.toRelativeTimeString() ?? ""
    }
    
    func numberOfSections() -> Int {
        return 1
    }
    
    func numberOfRows(section: Int) -> Int {
        return domainDetails.count
    }
    
    func baseUrl() -> String {
        return domainDetails.first?.url.host ?? ""
    }
    
    func isNews() -> Bool {
        return false
    }
    
    func useRightCell(indexPath: IndexPath) -> Bool {
        if indexPath.row == 1 {
            return true
        }
        return false
    }
    
    func detail(indexPath: IndexPath) -> DomainDetail? {
        if indexWithinBounds(indexPath: indexPath) {
            return domainDetails[indexPath.row]
        }
        return nil
    }
    
    func indexWithinBounds(indexPath: IndexPath) -> Bool {
        if indexPath.row < self.domainDetails.count{
            return true
        }
        return false
    }
    
}
