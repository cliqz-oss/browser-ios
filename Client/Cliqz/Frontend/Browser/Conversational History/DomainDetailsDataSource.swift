//
//  CliqzHistoryDetailsDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import RealmSwift

let domainDetailsDataSourceID = "DomainDetailsDataSource"

class DomainDetailsDataSource: DomainDetailsHeaderViewProtocol, BubbleTableViewDataSource {
    
    
    //group details by their date. 
    //order the dates.
	var domain: Domain
	var details: Results<Entry>
    
    
    //timestamp, number of timestamps, sum of previous number of timestamps
    //example [(date0, 1, 0), (date1, 3, 1), (date2, 2, 4), ... ]
    //I use the sum to easily map section and row to the index of the entry in details.
    var dateBuckets: [(Date, Int, Int)] = []

	var delegate: HasDataSource?
    
    private let standardDateFormat = "dd-MM-yyyy"
    private let standardTimeFormat = "HH:mm"
    
    private let standardDateFormatter = DateFormatter()
    private let standardTimeFormatter = DateFormatter()
    
    init(domain: Domain) {
		self.domain = domain
        self.details = domain.entries.sorted(byKeyPath: "timestamp", ascending: true)
        self.dateBuckets = self.buildDateBuckets(details: self.details)
        standardDateFormatter.dateFormat = standardDateFormat
        standardTimeFormatter.dateFormat = standardTimeFormat
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buildDateBuckets(details: Results<Entry>) -> [(Date, Int, Int)] {
        
        guard details.count > 0 else { return [] }
        
        var array: [(Date, Int, Int)] = [(details[0].timestamp, 1, 0)]
        
        var last: Date = details[0].timestamp
        var last_sum: Int = 0
        
        for i in 1..<details.count {
            let detail = details[i]
            let detail_comp = detail.timestamp.dayMonthYear()
            
            let last_comp = last.dayMonthYear()
            
            if detail_comp != last_comp {
                last_sum += array[array.count - 1].1
                array.append((detail.timestamp, 1, last_sum))
                last = detail.timestamp
            }
            else {
                let (d, c, s) = array[array.count - 1]
                array[array.count - 1] = (d, c + 1, s)
            }
        }
        
        return array
    }

	func logo(completionBlock: @escaping (_ image: UIImage?, _ customView: UIView?) -> Void) {
        LogoLoader.loadLogo(self.domain.name) { (image, logoInfo, error) in
			if let img = image {
				completionBlock(img, nil)
			} else if let info = logoInfo {
				let view = LogoPlaceholder(logoInfo: info)
				completionBlock(nil, view)
			} else {
				completionBlock(nil, nil)
			}
		}
    }

    func url(indexPath: IndexPath) -> String {
        return detail(indexPath: indexPath)?.url ?? ""
    }
    
    func title(indexPath: IndexPath) -> String {
        guard let detail = detail(indexPath: indexPath) else { return "" }
        if detail.isQuery {
            return detail.query
        }
        return detail.title
    }
    
    func titleSectionHeader(section: Int) -> String {
        return standardDateFormatter.string(from: dateBuckets[section].0)
    }
    
    func time(indexPath: IndexPath) -> String {
        if let date = detail(indexPath: indexPath)?.timestamp {
            return standardTimeFormatter.string(from: date)
        }
        return ""
    }
    
    func numberOfSections() -> Int {
        return dateBuckets.count//sortedDetails.count
    }
    
    func numberOfRows(section: Int) -> Int {
        return dateBuckets[section].1
    }
    
    func baseUrl() -> String {
		return self.domain.name
    }
    
    func isNews() -> Bool {
        return false
    }
    
    func useRightCell(indexPath: IndexPath) -> Bool {
        return detail(indexPath: indexPath)?.isQuery ?? false
    }
    
    func detail(indexPath: IndexPath) -> Entry? {
        let section = indexPath.section
        let row = indexPath.row
        //transform from section and row to list index
        let list_index = dateBuckets[section].2 + row
        return details[list_index]
    }
    
//    func sectionWithinBounds(section: Int) -> Bool {
//        if section >= 0 && section < sortedDetails.count {
//            return true
//        }
//        return false
//    }
//
//    func indexWithinBounds(indexPath: IndexPath) -> Bool {
//        guard sectionWithinBounds(section: indexPath.section) else { return false }
//        if indexPath.row >= 0 && indexPath.row < sortedDetails[indexPath.section].details?.count ?? 0 {
//            return true
//        }
//        return false
//    }

}
