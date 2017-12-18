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
        conversationalHistory.didPressCell = { (indexPath, host) in
            
            ReminderNotificationManager.shared.domainPressed(host: host)
            
            let data: [String: Any] = ["detailsHost": host]
            
            StateManager.shared.handleAction(action: Action(data: data, type: .domainPressed))
        }
        conversationalHistory.didDeleteCell = { (indexPath, host) in
            ReminderNotificationManager.shared.domainDeleted(host: host)
        }
    }
    
    private func setUpConversationalHistoryDetails(indexPath:IndexPath) -> DomainDetailsViewController {
        
        let headerAndTableDataSource = DomainDetailsDataSource(domain: domain(indexPath:  indexPath))
        
        let baseUrl = headerAndTableDataSource.baseUrl()
        
        let recommendationsDataSource = RecommendationsDataSource(baseUrl: baseUrl)
        
        let conversationalHistoryDetails = DomainDetailsViewController(tableViewDataSource: headerAndTableDataSource, recommendationsDataSource: recommendationsDataSource, headerViewDataSource: headerAndTableDataSource, didPressBack: {
            //self.showHistory()
            StateManager.shared.handleAction(action: Action(data: nil, type: .detailBackPressed))
            
        }, cellPressed: { (text, rightCell) in
            if rightCell == false {
                StateManager.shared.handleAction(action: Action(data: ["url": text], type: .urlSelected))
            }
            else {
                StateManager.shared.handleAction(action: Action(data: ["text": text], type: .urlSearchTextChanged))
            }
            
        })
        
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
    
    func indexPathFor(host:String) -> IndexPath? {
        let hosts = conversationalHistory.dataSource.domains.map { a in a.name }
        
        for i in 0..<hosts.count {
            if host == hosts[i] {
                return IndexPath(row: i, section: 0)
            }
        }
        
        return nil
    }
    
    func hostFor(indexPath: IndexPath) -> String? {
        let row = indexPath.row
        let domains = conversationalHistory.dataSource.domains
        
        if row >= 0 && row < domains.count {
            return domains[row].name
        }
        
        return nil
    }
    
    func showDetails(host: String, animated: Bool) {
        self.currentState = .Details
        
        guard let indexPath = indexPathFor(host: host) else {
            return
        }
        
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
    
    private func domain(indexPath: IndexPath) -> Domain {
        return conversationalHistory.dataSource.domains[indexPath.row]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
