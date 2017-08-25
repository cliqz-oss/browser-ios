//
//  CliqzHistoryDetailsDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class DomainDetailsDataSource: DomainDetailsHeaderViewProtocol, BubbleTableViewDataSource {
    
    
    //group details by their date. 
    //order the dates.
    
    struct SortedDomainDetail: Comparable {
        let date: Date
        let details: [DomainDetail]
        
        static func ==(x: SortedDomainDetail, y: SortedDomainDetail) -> Bool {
            return x.date == y.date
        }
        static func <(x: SortedDomainDetail, y: SortedDomainDetail) -> Bool {
            return x.date < y.date
        }
    }
    
    private let standardDateFormat = "dd-MM-yyyy"
    
    private let standardFormatter = DateFormatter()

    var img: UIImage?
    
    var sortedDetails: [SortedDomainDetail] = []
    
    init(image:UIImage?, domainDetails: [DomainDetail]) {
        
        standardFormatter.dateFormat = standardDateFormat
        
        self.img = image
        self.sortedDetails = orderByDate(domainDict: groupByDate(domainDetails: domainDetails))
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
        guard sectionWithinBounds(section: section) else { return "" }
        let date = sortedDetails[section].date
        return standardFormatter.string(from: date)
    }
    
    func time(indexPath: IndexPath) -> String {
        return detail(indexPath: indexPath)?.date?.toRelativeTimeString() ?? ""
    }
    
    func numberOfSections() -> Int {
        return sortedDetails.count
    }
    
    func numberOfRows(section: Int) -> Int {
        return sortedDetails[section].details.count
    }
    
    func baseUrl() -> String {
        return sortedDetails.first?.details.first?.url.host ?? ""
    }
    
    func isNews() -> Bool {
        return false
    }
    
    func useRightCell(indexPath: IndexPath) -> Bool {
        return false
    }
    
    func detail(indexPath: IndexPath) -> DomainDetail? {
        if indexWithinBounds(indexPath: indexPath) {
            return sortedDetails[indexPath.section].details[indexPath.row]
        }
        return nil
    }
    
    func sectionWithinBounds(section: Int) -> Bool {
        if section >= 0 && section < sortedDetails.count {
            return true
        }
        return false
    }
    
    func indexWithinBounds(indexPath: IndexPath) -> Bool {
        guard sectionWithinBounds(section: indexPath.section) else { return false }
        if indexPath.row >= 0 && indexPath.row < sortedDetails[indexPath.section].details.count {
            return true
        }
        return false
    }
    
    func groupByDate(domainDetails: [DomainDetail]) -> Dictionary<String, [DomainDetail]> {
        return GeneralUtils.groupBy(array: domainDetails) { (domainDetail) -> String in
            if let date = domainDetail.date {
                let formatter = DateFormatter()
                formatter.dateFormat = standardDateFormat
                return formatter.string(from: date)
            }
            return "01-01-1970"
        }
    }
    
    //return a descending array
    func orderByDate(domainDict: Dictionary<String, [DomainDetail]>) -> [SortedDomainDetail] {
        
        let unsortedArray = domainDict.keys.map { (key) -> SortedDomainDetail in
            let domainDetails = domainDict[key]
            return SortedDomainDetail(date: self.standardFormatter.date(from: key)!, details: domainDetails!)
        }
        
        return unsortedArray.sorted().reversed()
    }
    
    
}
