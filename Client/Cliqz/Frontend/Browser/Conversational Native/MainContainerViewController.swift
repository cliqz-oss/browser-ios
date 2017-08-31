//
//  MainContainerViewController.swift
//  Client
//
//  Created by Tim Palade on 8/1/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

//Documentation of Important Global Ideas

//UI Update Rules:
//1. Managers or Modules update each other using Notifications.
//2. Datasources update controllers using delegates.

protocol HasDataSource: class {
    func dataSourceWasUpdated(identifier: String)
}

class MainContainerViewController: UIViewController {
    
    private let backgroundImage = UIImageView()
    
    fileprivate let URLBarVC = URLBarViewController()
    fileprivate let contentNavVC = ContentNavigationViewController()
    fileprivate let toolbarVC = ToolbarViewController()
    
    let searchLoader: SearchLoader
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		
		// TODO: Refactor profile/tabManager creation and contentNavVC initialization
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let profile = appDelegate.profile
		let tabManager = appDelegate.tabManager
        
        searchLoader = SearchLoader(profile: profile!)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        contentNavVC.search_loader = searchLoader
        contentNavVC.profile = profile
		contentNavVC.tabManager = tabManager

        URLBarVC.search_loader = searchLoader
        URLBarVC.externalDelegate = Router.sharedInstance
        
        Router.sharedInstance.registerController(viewController: ContentNavVC)
        Router.sharedInstance.registerController(viewController: self)
        
        prepareModules()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpComponent()
        setStyling()
        setConstraints()
    }
    
    private func prepareModules() {
        _ = NewsManager.sharedInstance
        _ = DomainsModule.sharedInstance
    }
    
    private func setUpComponent() {
        
        self.view.addSubview(backgroundImage)
        
        self.addChildViewController(URLBarVC)
        self.view.addSubview(URLBarVC.view)
        
        self.addChildViewController(toolbarVC)
        self.view.addSubview(toolbarVC.view)
        
        self.addChildViewController(contentNavVC)
        self.view.addSubview(contentNavVC.view)
        
        Router.sharedInstance.registerController(viewController: contentNavVC, as: .contentNavigation)
    }

    private func setStyling() {
        self.view.backgroundColor = UIColor(colorString: "E9E9E9")
        backgroundImage.layer.zPosition = -100
        backgroundImage.image = UIImage(named: "conversationalBG")
    }
    
    private func setConstraints() {
        
        backgroundImage.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalTo(self.view)
        }
        
        URLBarVC.view.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(URLBarVC.URLBarHeight)
        }
        
        toolbarVC.view.snp.makeConstraints { (make) in
            make.height.equalTo(44)
            make.left.right.bottom.equalToSuperview()
        }
        
        contentNavVC.view.snp.makeConstraints { (make) in
            make.top.equalTo(URLBarVC.view.snp.bottom)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(toolbarVC.view.snp.top)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

//receive actions
extension MainContainerViewController {
    
    //TO DO: Centralized decision place
    
    func autoSuggestURLBar(autoSuggestText: String) {
        URLBarVC.setAutocompleteSuggestion(autoSuggestText)
    }
    
    func dismissKeyboardForUrlBar() {
        URLBarVC.resignFirstResponder()
    }
}

