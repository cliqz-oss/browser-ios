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
    
    var recommendations: [Recommendation] = RecommendationsManager.sharedInstance.recommendations(domain: nil)
    
    weak var delegate: HasDataSource?
    
    init(delegate: HasDataSource) {
        self.delegate = delegate
        NotificationCenter.default.addObserver(self, selector: #selector(recommendationsReady), name: RecommendationsManager.notification_updated, object: nil)
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
    
    func picture(indexPath: IndexPath, completionBlock: @escaping (_ result:UIImage?) -> Void) {
        LogoLoader.loadLogoImageOrFakeLogo(self.url(indexPath: indexPath), completed: { (image, fakeLogo, error) in
            if let img = image{
                completionBlock(img)
            }
            else{
                //completionBlock(result: UIImage(named: "coolLogo") ?? UIImage())
                completionBlock(nil)
            }
        })
    }
    
    func cellPressed(indexPath: IndexPath) {
        //handle press
    }
    
    @objc
    private func recommendationsReady(_ sender: Notification) {
        self.updateRecommendations()
        delegate?.dataSourceWasUpdated(identifier: DashRecommendationsDataSource.identifier)
    }
    
    private func updateRecommendations() {
        recommendations = RecommendationsManager.sharedInstance.recommendations(domain: nil)
    }
}
