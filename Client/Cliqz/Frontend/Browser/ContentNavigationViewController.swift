//
//  ContentNavigationViewController.swift
//  Client
//
//  Created by Tim Palade on 8/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

final class ContentNavigationViewController: UIViewController {

    let pageNavVC = PageNavigationViewController()
    var browserVC: CIBrowserViewController? = nil
    var searchController: CliqzSearchViewController? = nil

    weak var search_loader: SearchLoader?
    weak var profile: Profile?
	weak var tabManager: TabManager?
    weak var stateDelegate: StateDelegate? = nil

    enum State {
        case pageNavigation
        case browser
        case search
    }

    var currentState: State = .pageNavigation //initial state
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpComponent()
        setStyling()
        setConstraints()
    }
    
    private func setUpComponent() {
        setUpPageNavigation()
    }
    
    private func setStyling() {
        view.backgroundColor = UIColor.clear
    }
    
    private func setConstraints() {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


//All things related to state have to go through here
extension ContentNavigationViewController {

    //TO DO: animation transitions should be defined for the state change.

    func changeState(state: State, text: String? = nil) {
        guard currentState != state else {
            return
        }

        if state == .pageNavigation {
            hideSearchController()
            hideBrowserViewController()
            
            showPageNavigation()
        }
        else if state == .browser {
            hidePageNavigation()
            hideSearchController()

			showBrowser(url: text)
        }
        else if state == .search {
            hideBrowserViewController()
            hidePageNavigation()

            showSearchController(text: text)
        }
        currentState = state
        stateDelegate?.stateChanged(component: "ContentNav")
    }
}

//Router 
extension ContentNavigationViewController {
    //This will be refactored. States will be introduced and as well as a central place for the diplay logic.
    
    func browseURL(url: String?) {
		changeState(state: .browser, text: url)
    }

    func browseTab(tab: Tab) {
        tabManager?.selectTab(tab)
        changeState(state: .browser)
    }

    func textInUrlBarChanged(text: String) {
        searchController?.searchQuery = text
    }
    
    func textIUrlBarCleared() {
        textInUrlBarChanged(text: "")
    }
    
    func backPressedUrlBar() {
        //
    }
    
    func homePressed() {
		pageNavVC.navigate()
    }
}

//PageNavigationViewController
extension ContentNavigationViewController {

    func showPageNavigation() {
        pageNavVC.view.isHidden = false
		// TODO: What is the case when URL should be modified along with showing page navigation, this brakes some other logic
//		Router.shared.action(action: Action(data: nil, type: .urlIsModified, context: .urlBarVC))
    }

    func hidePageNavigation() {
        pageNavVC.view.isHidden = true
    }

    func setUpPageNavigation() {
        
        addChildViewController(pageNavVC)
        view.addSubview(pageNavVC.view)
        
        setStylingPageNavigation()
        setConstraintsPageNavigation()
    }

    func setStylingPageNavigation() {
    }

    func setConstraintsPageNavigation() {
        pageNavVC.view.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}

//BrowserViewController
extension ContentNavigationViewController {

	func showBrowser(url : String?) {
        if self.browserVC == nil {
            setUpBrowserViewController()
        }
        
        self.browserVC?.view.isHidden = false
		if let u = url {
			var validURL = URIFixup.getURL(u)
			if validURL == nil {
				validURL = self.profile?.searchEngines.defaultEngine.searchURLForQuery(u)
			}
			self.browserVC?.loadURL(validURL)
			Router.shared.action(action: Action(data: (validURL != nil ? ["url": validURL!] : nil), type: .urlIsModified, context: .urlBarVC))
		}
    }

    func hideBrowserViewController() {
        browserVC?.view.isHidden = true
    }

    func setUpBrowserViewController() {
        if let profile = self.profile,
			let tabManager = self.tabManager {
			browserVC = CIBrowserViewController(profile: profile, tabManager: tabManager)
			self.addChildViewController(browserVC!)
			view.addSubview(browserVC!.view)

			setStylingBrowserViewController()
			setConstraintsBrowserViewController()
		}
    }

    func setStylingBrowserViewController() {
        
    }

    func setConstraintsBrowserViewController() {
        browserVC!.view.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
        }
    }
}

//SearchViewController
extension ContentNavigationViewController {
    
    func showSearchController(text: String?) {
        if searchController == nil{
            setUpSearchController()
            
        }
        
        searchController?.view.isHidden = false
        searchController?.searchQuery = text
        //searchController?.sendUrlBarFocusEvent()
        
        resetNavigationSteps()
    }
    
    func hideSearchController() {
        searchController?.view.isHidden = true
    }
    
    func setUpSearchController() {
        if let pf = self.profile, let searchLoader = self.search_loader {
            
            searchController = CliqzSearchViewController(profile: pf)
            
            searchController?.delegate = self
            searchLoader.addListener(searchController!)
            
            view.addSubview(searchController!.view)
            addChildViewController(searchController!)
            searchController?.didMove(toParentViewController: self)
            
            setStylingSearchViewController()
            setConstraintsSearchViewController()
        }
    }
    
    func setStylingSearchViewController() {
        
    }
    
    func setConstraintsSearchViewController() {
        searchController!.view.snp.remakeConstraints({ (make) in
            make.top.left.bottom.right.equalToSuperview()
        })
    }
    
    func resetNavigationSteps() {
//        browserVC?.navigationStep = 0
//        browserVC?.backNavigationStep = 0
    }
    
}

extension ContentNavigationViewController: SearchViewDelegate {

    //TO DO: Route these
    
    func didSelectURL(_ url: URL, searchQuery: String?) {
        
    }
    
    func searchForQuery(_ query: String) {

    }

    func autoCompeleteQuery(_ autoCompleteText: String) {
        Router.shared.action(action: Action(data: ["text": autoCompleteText], type: .searchAutoSuggest, context: .contentNavVC))
    }
    
    func stopEditing() {
        Router.shared.action(action: Action(data: nil, type: .searchStopEditing, context: .contentNavVC))
    }
}

// reminders
extension ContentNavigationViewController {

    func showReminder() {
        if currentState == .browser {
            Reminders.show()
        }
    }
}
