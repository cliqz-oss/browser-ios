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
    
    weak var externalDelegate: ActionDelegate? = nil
    
    enum State {
        case Domains
        case Details
    }
    
    var currentState: State = .Domains

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
            
            var data: [String: Any] = ["indexPath": indexPath]
            
            if let img = image {
                data["image"] = img
            }
            
            StateManager.shared.handleAction(action: Action(data: data, type: .domainPressed, context: .historyNavVC))
        }
    }
    
    private func setUpConversationalHistoryDetails(indexPath:IndexPath, image: UIImage?) -> DomainDetailsViewController {
        
        let headerAndTableDataSource = DomainDetailsDataSource(image: image, domainDetails: domainDetails(indexPath: indexPath))
        
        let baseUrl = headerAndTableDataSource.baseUrl()
        
        let recommendationsDataSource = RecommendationsDataSource(baseUrl: baseUrl)
        
        let conversationalHistoryDetails = DomainDetailsViewController(tableViewDataSource: headerAndTableDataSource, recommendationsDataSource: recommendationsDataSource, headerViewDataSource: headerAndTableDataSource, didPressBack: {
            //self.showHistory()
            StateManager.shared.handleAction(action: Action(data: nil, type: .detailBackPressed, context: .historyNavVC))
            
        }) { (url) in
            StateManager.shared.handleAction(action: Action(data: ["url":url], type: .urlSelected, context: .historyNavVC))
        }
        
        recommendationsDataSource.delegate = conversationalHistoryDetails
        
        return conversationalHistoryDetails
    }
    
    func showHistory() {
        
        self.currentState = .Domains
        
        UIView.animate(withDuration: 0.2, animations: {
            self.conversationalHistory.view.alpha = 1.0
        }) { (completed) in
            self.nc.popToRootViewController(animated: true)
        }
    }
    
    func showDetails(indexPath: IndexPath, image: UIImage?) {
        self.currentState = .Details
        
        let conversationalHistoryDetails = self.setUpConversationalHistoryDetails(indexPath: indexPath, image: image)
        
        UIView.animate(withDuration: 0.16, animations: {
            self.conversationalHistory.view.alpha = 0.0
            self.nc.pushViewController(conversationalHistoryDetails, animated: true)
        })
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
