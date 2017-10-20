//
//  CliqzHistoryDetailsDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/20/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

let domainDetailsDataSourceID = "DomainDetailsDataSource"

class DomainDetailsDataSource: DomainDetailsHeaderViewProtocol, BubbleTableViewDataSource {
    
    
    //group details by their date. 
    //order the dates.
	var domain: DomainModel
	let details: [DomainDetailModel]? = nil

	var delegate: HasDataSource?

    struct SortedDomainDetail: Comparable {
        let date: String
        var details: [DomainDetailModel]?
        
        static func ==(x: SortedDomainDetail, y: SortedDomainDetail) -> Bool {
            return x.date == y.date
        }
        static func <(x: SortedDomainDetail, y: SortedDomainDetail) -> Bool {
            return x.date < y.date
        }
    }
    
    private let standardDateFormat = "dd-MM-yyyy"
    private let standardTimeFormat = "HH:mm"
    
    private let standardDateFormatter = DateFormatter()
    private let standardTimeFormatter = DateFormatter()

	
    var sortedDetails: [SortedDomainDetail] = []
    
    init(domain: DomainModel) {
		self.domain = domain
        standardDateFormatter.dateFormat = standardDateFormat
        standardTimeFormatter.dateFormat = standardTimeFormat
		if let details = domain.domainDetails {
			self.sortedDetails = groupByDate(details)
		} else {
			loadDetails()
		}
    }

	private func loadDetails() {
		DomainsModule.shared.loadDomainDetails(self.domain) {
			(result) in
			self.domain.domainDetails = result
			self.sortedDetails = self.groupByDate(result)
			self.delegate?.dataSourceWasUpdated(identifier: domainDetailsDataSourceID)
		}
	}

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	func logo(completionBlock: @escaping (_ image: UIImage?, _ customView: UIView?) -> Void) {
        LogoLoader.loadLogo(self.domain.host ?? "") { (image, logoInfo, error) in
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
        return detail(indexPath: indexPath)?.url.absoluteString ?? ""
    }
    
    func title(indexPath: IndexPath) -> String {
        return detail(indexPath: indexPath)?.title ?? ""
    }
    
    func titleSectionHeader(section: Int) -> String {
        guard sectionWithinBounds(section: section) else { return "" }
        return sortedDetails[section].date
    }
    
    func time(indexPath: IndexPath) -> String {
        if let date = detail(indexPath: indexPath)?.date {
            return standardTimeFormatter.string(from: date)
        }
        return ""
    }
    
    func numberOfSections() -> Int {
        return sortedDetails.count
    }
    
    func numberOfRows(section: Int) -> Int {
        return sortedDetails[section].details?.count ?? 0
    }
    
    func baseUrl() -> String {
		return self.domain.host
    }
    
    func isNews() -> Bool {
        return false
    }
    
    func useRightCell(indexPath: IndexPath) -> Bool {
        return false
    }
    
    func detail(indexPath: IndexPath) -> DomainDetailModel? {
        if indexWithinBounds(indexPath: indexPath) {
            return sortedDetails[indexPath.section].details?[indexPath.row]
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
        if indexPath.row >= 0 && indexPath.row < sortedDetails[indexPath.section].details?.count ?? 0 {
            return true
        }
        return false
    }
    
    func groupByDate(_ domainDetails: [DomainDetailModel]?) -> [SortedDomainDetail] {
		var result  = [SortedDomainDetail]()
		guard let data = domainDetails else {
			return result
		}
		for d in data {
			var date: String?
			if let dd = d.date {
				date = standardDateFormatter.string(from: dd)
			} else {
				date = "01-01-1970"
			}
			if result.count > 0 && result[result.count - 1].date == date {
				result[result.count - 1].details?.append(d)
			} else {
				let x = SortedDomainDetail(date: date!, details:[d])
				result.append(x)
			}
		}
		return result
    }

}
