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
                CINotificationManager.sharedInstance.newsVisisted = true
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
    
    private func domainDict(indexPath:NSIndexPath) -> NSDictionary {
        let key = conversationalHistory.dataSource.domains[indexPath.row]
        return conversationalHistory.dataSource.domainsInfo.valueForKey(key) as! NSDictionary
    }
    
    private func detailsDataSource(indexPath:NSIndexPath, image:UIImage?) -> HistoryDetailsProtocol? {
        if indexPath.row == 0 && NewsDataSource.sharedInstance.ready{
            return CliqzNewsDetailsDataSource(image:image, articles: NewsDataSource.sharedInstance.articles)
        }
        else if indexPath.row > 0{
            let domain_dict = domainDict(indexPath)
            return CliqzHistoryDetailsDataSource(image: image, visits: domain_dict.valueForKey("visits") as? NSArray ?? NSArray(), baseUrl: domain_dict.valueForKey("baseUrl") as? String ?? "")
        }
        return nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

final class ReadNewsManager {
    
    //articles change every day. So only articles that are youger than 1 day should stay in my manager
    //I will write to disk the current articles when the application is closed.
    
    //user defaults key
    private let userDefaultsKey_Read = "ID_READ_NEWS"
    
    private var readArticlesDict: Dictionary<String,NSDate> = Dictionary()
    
    static let sharedInstance = ReadNewsManager()
    
    init() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let read = userDefaults.valueForKey(userDefaultsKey_Read) as? Dictionary<String,NSDate> {
            //here add only keys that have a value younger than 1 day.
            self.readArticlesDict = self.youngerThanOneDayDict(read)
        }
    }
    
    func youngerThanOneDayDict(dict: Dictionary<String,NSDate>) -> Dictionary<String,NSDate>{
        var returnDict: Dictionary<String,NSDate> = Dictionary()
        for key in dict.keys{
            if let date = dict[key] where isYoungerThanOneDay(date){
                returnDict[key] = date
            }
        }
        return returnDict
    }
    
    func isYoungerThanOneDay(date:NSDate) -> Bool{
        let currentDate = NSDate(timeIntervalSinceNow: 0)
        let difference_seconds = currentDate.timeIntervalSinceDate(date)
        let oneDay_seconds     = Double(24 * 360)
        if difference_seconds > 0 && difference_seconds < oneDay_seconds {
            return true
        }
        return false
    }
    
    func isRead(articleLink:String) -> Bool {
        return readArticlesDict.keys.contains(articleLink)
    }
    
    func markAsRead(articleLink:String?) {
        guard let art_link = articleLink else { return }
        readArticlesDict[art_link] = NSDate(timeIntervalSinceNow: 0)
    }
    
    func save(){
        NSUserDefaults.standardUserDefaults().setObject(self.readArticlesDict, forKey: userDefaultsKey_Read)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
}
