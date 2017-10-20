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
        conversationalHistory.didPressCell = { (indexPath) in
            
            let data: [String: Any] = ["indexPath": indexPath]
            
            StateManager.shared.handleAction(action: Action(data: data, type: .domainPressed))
        }
    }
    
    private func setUpConversationalHistoryDetails(indexPath:IndexPath) -> DomainDetailsViewController {
        
        let headerAndTableDataSource = DomainDetailsDataSource(domain: domain(indexPath:  indexPath))
        
        let baseUrl = headerAndTableDataSource.baseUrl()
        
        let recommendationsDataSource = RecommendationsDataSource(baseUrl: baseUrl)
        
        let conversationalHistoryDetails = DomainDetailsViewController(tableViewDataSource: headerAndTableDataSource, recommendationsDataSource: recommendationsDataSource, headerViewDataSource: headerAndTableDataSource, didPressBack: {
            //self.showHistory()
            StateManager.shared.handleAction(action: Action(data: nil, type: .detailBackPressed))
            
        }) { (url) in
            StateManager.shared.handleAction(action: Action(data: ["url":url], type: .urlSelected))
        }
        
        recommendationsDataSource.delegate = conversationalHistoryDetails
        headerAndTableDataSource.delegate = conversationalHistoryDetails

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
    
    func showDetails(indexPath: IndexPath, animated: Bool) {
        self.currentState = .Details
        
        let conversationalHistoryDetails = self.setUpConversationalHistoryDetails(indexPath: indexPath)
        
        if animated {
            UIView.animate(withDuration: 0.16, animations: {
                self.conversationalHistory.view.alpha = 0.0
                self.nc.pushViewController(conversationalHistoryDetails, animated: true)
            })
        }
        else {
            self.conversationalHistory.view.alpha = 0.0
            self.nc.pushViewController(conversationalHistoryDetails, animated: false)
        }
    }
    
    private func hideConversationalHistory() {
        self.view.isHidden = true
    }
    
    private func domain(indexPath: IndexPath) -> DomainModel {
        return conversationalHistory.dataSource.domains[indexPath.row]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
