//
//  HistoryDataSource.swift
//  Client
//
//  Created by Mahmoud Adam on 10/17/17.
//  Copyright © 2017 Cliqz. All rights reserved.
//

import UIKit

class HistoryDataSource: BubbleTableViewDataSource {
    
    //group details by their date. 
    //order the dates.
    
    struct SortedHistoryEntry: Comparable {
        let date: String
        var details: [HistoryEntry]
        
        static func ==(x: SortedHistoryEntry, y: SortedHistoryEntry) -> Bool {
            return x.date == y.date
        }
        static func <(x: SortedHistoryEntry, y: SortedHistoryEntry) -> Bool {
            return x.date < y.date
        }
    }
    
    private let standardDateFormat = "dd.MM.yyyy"
    private let standardTimeFormat = "HH:mm"
    
    private let standardDateFormatter = DateFormatter()
    private let standardTimeFormatter = DateFormatter()

	
    var sortedDetails: [SortedHistoryEntry] = []
    weak var delegate: HasDataSource?
    var profile: Profile!

    init(profile: Profile) {
        self.profile = profile
        standardDateFormatter.dateFormat = standardDateFormat
        standardTimeFormatter.dateFormat = standardTimeFormat
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadHistory(completion: (() -> Void )?) {
        HistoryModule.getHistory(profile: profile) { [weak self] (historyEntries, error) in
            if error == nil,
                let orderedEntries = self?.groupByDate(historyEntries) {
                self?.sortedDetails = orderedEntries
                completion?()
            }
        }
    }
 
    func logo(indexPath: IndexPath, completionBlock: @escaping (_ url: URL, _ image: UIImage?, _ logoInfo: LogoInfo?) -> Void) {
        if let url = url(indexPath: indexPath) {
            LogoLoader.loadLogo(url.absoluteString) { (image, logoInfo, error) in
                completionBlock(url, image, logoInfo)
            }
        }
    }
 
    func url(indexPath: IndexPath) -> URL? {
        let historyEntry = detail(indexPath: indexPath)
        if let historyUrlEntry = historyEntry as? HistoryUrlEntry {
            return historyUrlEntry.url
        }
        return nil
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
    func accessibilityLabel(indexPath: IndexPath) -> String {
        if useRightCell(indexPath: indexPath) {
            return "query"
        } else {
            return "url"
        }
    }
    func numberOfSections() -> Int {
        return sortedDetails.count
    }
    
    func numberOfRows(section: Int) -> Int {
        return sortedDetails[section].details.count
    }
    
    func isNews() -> Bool {
        return false
    }
    
    func useRightCell(indexPath: IndexPath) -> Bool {
        if let _ = detail(indexPath: indexPath) as? HistoryQueryEntry {
            return true
        }
        return false
    }
    
    func useLeftExpandedCell() -> Bool {
        return false
    }
    
    func isEmpty() -> Bool {
        return !sectionWithinBounds(section: 0)
    }
    
    func detail(indexPath: IndexPath) -> HistoryEntry? {
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
    
    func groupByDate(_ historyEntries: [HistoryEntry]?) -> [SortedHistoryEntry] {
        var result  = [SortedHistoryEntry]()
        guard let historyEntries = historyEntries else {
            return result
        }
        
        let ascendingHistoryEntries = historyEntries.reversed()
        for historyEntry in ascendingHistoryEntries {
            var date = "01-01-1970"
            if let entryDate = historyEntry.date {
                date = standardDateFormatter.string(from: entryDate)
            }
            if result.count > 0 && result[result.count - 1].date == date {
                result[result.count - 1].details.append(historyEntry)
            } else {
                let x = SortedHistoryEntry(date: date, details:[historyEntry])
                result.append(x)
            }
        }
        return result
    }
    
    func deleteItem(at indexPath: IndexPath, completion: (() -> Void )?) {
        if let historyEntry = detail(indexPath: indexPath) {
            HistoryModule.removeHistoryEntries(profile: profile, ids: [historyEntry.id])
            self.reloadHistory(completion: {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.dataSourceWasUpdated()
                }
                completion?()
            })
        }
    }
}
