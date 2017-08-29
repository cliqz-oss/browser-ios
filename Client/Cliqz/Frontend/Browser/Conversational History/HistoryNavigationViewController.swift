//
//  ConversationalContainer.swift
//  Client
//
//  Created by Tim Palade on 4/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

final class HistoryNavigationViewController: UIViewController {
    
    var conversationalHistory: DomainsViewController = DomainsViewController()
    var searchController: CliqzSearchViewController?
    var nc: UINavigationController = UINavigationController()
    
    weak var externalDelegate: UserActionDelegate? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        setUpNavigationController()
        setupConversationalHistory()
    }
    
    private func setUpNavigationController() {
        nc = UINavigationController(rootViewController: conversationalHistory)
        self.view.addSubview(nc.view)
        self.addChildViewController(nc)
        nc.view.snp.remakeConstraints { (make) in
            make.top.bottom.left.right.equalTo(self.view)
        }
        nc.view.backgroundColor = UIColor.clear
    }
    
    private func setupConversationalHistory() {
        conversationalHistory.view.backgroundColor = UIColor.clear
        conversationalHistory.didPressCell = { (indexPath,image) in
            
            let conversationalHistoryDetails = self.setUpConversationalHistoryDetails(indexPath: indexPath, image: image)
            
            UIView.animate(withDuration: 0.16, animations: {
                self.conversationalHistory.view.alpha = 0.0
                self.nc.pushViewController(conversationalHistoryDetails, animated: true)
            })
        }
    }
    
    private func setUpConversationalHistoryDetails(indexPath:IndexPath, image: UIImage?) -> DomainDetailsViewController {
        
        let headerAndTableDataSource = DomainDetailsDataSource(image: image, domainDetails: domainDetails(indexPath: indexPath))
        
        let baseUrl = headerAndTableDataSource.baseUrl()
        
        let conversationalHistoryDetails = DomainDetailsViewController(tableViewDataSource: headerAndTableDataSource, recommendationsDataSource: RecommendationsDataSource(baseUrl: baseUrl), headerViewDataSource: headerAndTableDataSource, didPressBack: {
            self.showConversationalHistory()
        }) { (url) in
            self.externalDelegate?.userAction(action: UserAction(data: ["url":url], type: .urlPressed, context: .historyNavVC))
        }
        
        return conversationalHistoryDetails
    }
    
    private func showConversationalHistory() {
        UIView.animate(withDuration: 0.2, animations: {
            self.conversationalHistory.view.alpha = 1.0
        }) { (completed) in
            self.nc.popToRootViewController(animated: true)
        }
    }
    
    private func hideConversationalHistory() {
        self.view.isHidden = true
    }
    
    private func domainDetails(indexPath:IndexPath) -> [DomainDetail] {
        return conversationalHistory.dataSource.domains[indexPath.row].domainDetails
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
