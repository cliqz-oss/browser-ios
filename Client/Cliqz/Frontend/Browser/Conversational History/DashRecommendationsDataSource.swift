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
        recommendations = filterRecommendations(recommedations: RecommendationsManager.sharedInstance.recommendations(domain: nil))
    }
    
    private func filterRecommendations(recommedations: [Recommendation]) -> [Recommendation] {
        //filter rule: News with a domain that matches any domain in the history should be eliminated. Those news are presented in History Details.
        
        //get a list of all domains in the history 
        let domains = DomainsModule.sharedInstance.domains.map { (domain_struct) -> String in
            return domain_struct.host
        }
        
        let host_set = Set.init(domains)
        
        return RecommendationsManager.sharedInstance.recommendationsWithoutHosts(hosts: host_set)
    }
}
