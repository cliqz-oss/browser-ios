//
//  ConversationalContainer.swift
//  Client
//
//  Created by Tim Palade on 4/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

// This manages the state of the User Interface for the Conversational Experiment components
// Here you can find the definition for what should happen when a domain cell is pressed

// Change changeState is the core method.

final class ConversationalContainer: UIViewController {
    
    var conversationalHistory: ConversationalHistory = ConversationalHistory()
    var searchController: CliqzSearchViewController?
    var nc: UINavigationController = UINavigationController()
    weak var browsing_delegate: BrowserNavigationDelegate?
    weak var searching_delegate: SearchViewDelegate?
    weak var search_loader: SearchLoader?
    weak var profile: Profile?
    
    var resetNavigationSteps: () -> () = { _ in }

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
        conversationalHistory.delegate = self.browsing_delegate
        conversationalHistory.didPressCell = { (indexPath,image) in
            if indexPath.row == 0 { //news
                NewsDataSource.sharedInstance.setNewArticlesAsSeen()
            }
            let conversationalHistoryDetails = self.setUpConversationalHistoryDetails(indexPath: indexPath, image: image)
            
            UIView.animate(withDuration: 0.16, animations: {
                self.conversationalHistory.view.alpha = 0.0
                self.nc.pushViewController(conversationalHistoryDetails, animated: true)
            }, completion: { (completed) in
                //self.conversationalHistory.view.alpha = 1.0
            })
            
        }
    }
    
    private func setUpConversationalHistoryDetails(indexPath:IndexPath, image: UIImage?) -> ConversationalHistoryDetails {
        let conversationalHistoryDetails = ConversationalHistoryDetails()
        conversationalHistoryDetails.delegate = self.browsing_delegate
        conversationalHistoryDetails.didPressBack = {
            self.showConversationalHistory()
        }
        conversationalHistoryDetails.dataSource = detailsDataSource(indexPath: indexPath, image: image)
        return conversationalHistoryDetails
    }
    
    private func showConversationalHistory() {
        UIView.animate(withDuration: 0.16, animations: {
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
    
    private func detailsDataSource(indexPath:IndexPath, image:UIImage?) -> HistoryDetailsProtocol? {
        if indexPath.row == 0 {
            return CliqzNewsDetailsDataSource(image:image, articles: NewsDataSource.sharedInstance.articles)
        }
        else if indexPath.row > 0 {
            return CliqzHistoryDetailsDataSource(image: image, domainDetails: domainDetails(indexPath: indexPath))
        }
        return nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //----------------------------------------------------------------------
    //DEPRECATED
    
    private func showSearchController(text: String?) {
        if searchController == nil{
            setUpSearchController()
        }
        
        searchController?.view.isHidden = false
        searchController?.didMove(toParentViewController: self)
        
        searchController?.searchQuery = text
        //searchController?.sendUrlBarFocusEvent()
        
        resetNavigationSteps()
    }
    
    private func hideSearchController() {
        searchController?.view.isHidden = true
    }
    
    private func setUpSearchController() {
        if let pf = self.profile, let searchLoader = self.search_loader{
            searchController = CliqzSearchViewController(profile: pf)
            searchController?.delegate = self.searching_delegate
            searchLoader.addListener(searchController!)
            self.view.addSubview(searchController!.view)
            self.addChildViewController(searchController!)
            searchController!.view.snp.remakeConstraints({ (make) in
                make.top.left.right.equalTo(self.view)
                make.height.equalTo(UIScreen.main.bounds.height)
            })
        }
    }
    
    //    func changeState(to state: ConversationalState, text: String?) {
    //
    //        if state == .History {
    //            self.hideSearchController()
    //            self.showConversationalHistory()
    //        }
    //        else if state == .Search {
    //            self.showSearchController(text: text)
    //        }
    //        else if state == .Browsing {
    //            self.hideSearchController()
    //            self.hideConversationalHistory()
    //        }
    //        
    //    }
    
}
