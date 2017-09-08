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
    
    init(delegate: HasDataSource) {
        self.recommendations = RecommendationsManager.sharedInstance.recommendations(domain: nil, type: .withoutHistoryDomains)
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
    
    func picture(indexPath: IndexPath, completionBlock: @escaping (_ result:UIImage? ) -> Void) {
		LogoLoader.loadLogo(self.url(indexPath: indexPath)) { (image, logoInfo, error) in
			if let img = image {
				completionBlock(img)
			}
			else{
				// TODO: Cell should support logo as a UIView corresponding to logoInfo
				completionBlock(nil)
			}
		}
    }
    
    func cellPressed(indexPath: IndexPath) {
        Router.shared.action(action: Action(data: ["url": self.url(indexPath: indexPath)], type: .urlSelected, context: .dashRecommendationsDS))
    }
    
    @objc
    private func recommendationsUpdated(_ sender: Notification) {
        self.updateRecommendations()
        delegate?.dataSourceWasUpdated(identifier: DashRecommendationsDataSource.identifier)
    }
    
    private func updateRecommendations() {
        recommendations = RecommendationsManager.sharedInstance.recommendations(domain: nil, type: .withoutHistoryDomains)
    }
    
    
}
