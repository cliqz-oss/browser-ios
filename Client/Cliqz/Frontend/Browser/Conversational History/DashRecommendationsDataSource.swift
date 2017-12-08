//
//  DashRecommendationsDataSource.swift
//  Client
//
//  Created by Tim Palade on 8/11/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

final class DashRecommendationsDataSource: ExpandableViewProtocol {
    
    static let identifier = "DashRecommendationsDataSource"
    
    var recommendations: [Recommendation]
    
    weak var delegate: HasDataSource?
    
    init(delegate: HasDataSource? = nil) {
        self.recommendations = RecommendationsManager.sharedInstance.recommendations(domain: nil, includeDomainsFromHistory: false, type: .news)
        self.delegate = delegate
        NotificationCenter.default.addObserver(self, selector: #selector(recommendationsUpdated), name: RecommendationsManager.notification_updated, object: nil)
    }
    
    func maxNumCells() -> Int {
        return recommendations.count
    }
    
    func minNumCells() -> Int {
        return min(recommendations.count, 3)
    }
    
    func title(indexPath: IndexPath) -> String {
        return recommendations[indexPath.row].title
    }
    
    func url(indexPath: IndexPath) -> String {
        return recommendations[indexPath.row].url
    }
    
	func picture(indexPath: IndexPath, completionBlock: @escaping (_ result:UIImage?, _ customView: UIView?) -> Void) {
        
        let baseUrl = self.url(indexPath: indexPath)
        
        DispatchQueue(label:"background").async {
            LogoLoader.loadLogo(baseUrl) { (image, logoInfo, error) in
                if let img = image {
                    DispatchQueue.main.async {
                        completionBlock(img, nil)
                    }
                } else {
                    if let info = logoInfo {
                        DispatchQueue.main.async {
                            let logoPlaceholder = LogoPlaceholder.init(logoInfo: info)
                            completionBlock(nil, logoPlaceholder)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completionBlock(nil, nil)
                        }
                    }
                }
            }
        }
    }
    
    func cellPressed(indexPath: IndexPath) {
        StateManager.shared.handleAction(action: Action(data: ["url": self.url(indexPath: indexPath)], type: .urlSelected))
    }
    
    @objc
    private func recommendationsUpdated(_ sender: Notification) {
        self.updateRecommendations()
        delegate?.dataSourceWasUpdated(identifier: DashRecommendationsDataSource.identifier)
    }
    
    private func updateRecommendations() {
        recommendations = RecommendationsManager.sharedInstance.recommendations(domain: nil, includeDomainsFromHistory: false, type: .news)
    }
    
    
}
