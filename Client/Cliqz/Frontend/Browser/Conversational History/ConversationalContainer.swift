//
//  ConversationalContainer.swift
//  Client
//
//  Created by Tim Palade on 4/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

enum ConversationalState{
    case History
    case Search
    case Browsing
}

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
        setupConversationalHistory()
        setUpNavigationController()
    }
    
    func changeState(to state: ConversationalState, text: String?) {
        
        if state == .History {
            self.hideSearchController()
            self.showConversationalHistory()
        }
        else if state == .Search {
            self.showSearchController(text)
        }
        else if state == .Browsing {
            self.hideSearchController()
            self.hideConversationalHistory()
        }
        
    }
    
    private func setupConversationalHistory() {
        conversationalHistory.delegate = self.browsing_delegate
        conversationalHistory.didPressCell = { (indexPath,image) in
            if indexPath.row == 0 { //news
                NewsDataSource.sharedInstance.setNewArticlesAsSeen()
            }
            let conversationalHistoryDetails = self.setUpConversationalHistoryDetails(indexPath, image: image)
            self.nc.pushViewController(conversationalHistoryDetails, animated: true)
        }
    }
    
    private func setUpSearchController() {
        if let pf = self.profile, searchLoader = self.search_loader{
            searchController = CliqzSearchViewController(profile: pf)
            searchController?.delegate = self.searching_delegate
            searchLoader.addListener(searchController!)
            self.view.addSubview(searchController!.view)
            self.addChildViewController(searchController!)
            searchController!.view.snp_makeConstraints(closure: { (make) in
                make.top.left.right.equalTo(self.view)
                make.height.equalTo(UIScreen.mainScreen().bounds.height)
            })
        }
    }
    
    private func setUpNavigationController() {
        nc = UINavigationController(rootViewController: conversationalHistory)
        self.view.addSubview(nc.view)
        self.addChildViewController(nc)
        nc.view.snp_makeConstraints { (make) in
            make.top.bottom.left.right.equalTo(self.view)
        }
    }
    
    private func setUpConversationalHistoryDetails(indexPath:NSIndexPath, image: UIImage?) -> ConversationalHistoryDetails {
        let conversationalHistoryDetails = ConversationalHistoryDetails()
        conversationalHistoryDetails.delegate = self.browsing_delegate
        conversationalHistoryDetails.didPressBack = {
            self.nc.popViewControllerAnimated(true)
        }
        conversationalHistoryDetails.dataSource = detailsDataSource(indexPath, image: image)
        return conversationalHistoryDetails
    }
    
    private func showConversationalHistory() {
        if self.nc.viewControllers.count > 1{
            self.nc.popToRootViewControllerAnimated(false)
        }
        conversationalHistory.loadData()
        self.view.hidden = false
    }
    
    private func hideConversationalHistory() {
        self.view.hidden = true
    }
    
    private func showSearchController(text: String?) {
        if searchController == nil{
            setUpSearchController()
        }
        
        searchController?.view.hidden = false
        searchController?.didMoveToParentViewController(self)
        
        searchController?.searchQuery = text
        //searchController?.sendUrlBarFocusEvent()
        
        resetNavigationSteps()
    }
    
    private func hideSearchController() {
        searchController?.view.hidden = true
    }
    
    private func domainDetails(indexPath:NSIndexPath) -> [DomainDetail] {
        return conversationalHistory.dataSource.domains[indexPath.row].domainDetails
    }
    
    private func detailsDataSource(indexPath:NSIndexPath, image:UIImage?) -> HistoryDetailsProtocol? {
        if indexPath.row == 0 && NewsDataSource.sharedInstance.ready{
            return CliqzNewsDetailsDataSource(image:image, articles: NewsDataSource.sharedInstance.articles)
        }
        else if indexPath.row > 0 {
            return CliqzHistoryDetailsDataSource(image: image, domainDetails: domainDetails(indexPath))
        }
        return nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
