//
//  ContentNavigationViewController.swift
//  Client
//
//  Created by Tim Palade on 8/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

final class ContentNavigationViewController: UIViewController {

    let pageNavVC: PageNavigationViewController
    let browserVC: CIBrowserViewController
    let searchController: CliqzSearchViewController

    var profile: Profile
    var tabManager: TabManager
    var searchLoader: SearchLoader
    
    weak var stateDelegate: StateDelegate? = nil

    enum State {
        case pageNavigation
        case browser
        case search
        case undefined
    }

    var currentState: State = .undefined
    
    init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil, profile: Profile, tabManager: TabManager, searchLoader: SearchLoader) {
        
        self.profile = profile
        self.tabManager = tabManager
        self.searchLoader = searchLoader
        
        pageNavVC = PageNavigationViewController()
        browserVC = CIBrowserViewController(profile: profile, tabManager: tabManager)
        searchController = CliqzSearchViewController(profile: profile)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpComponent()
        setStyling()
        setConstraints()
    }
    
    private func setUpComponent() {
        
        addChildViewController(pageNavVC)
        view.addSubview(pageNavVC.view)
        
        self.addChildViewController(browserVC)
        view.addSubview(browserVC.view)
        
        searchController.delegate = self
        searchLoader.addListener(searchController)
        
        view.addSubview(searchController.view)
        addChildViewController(searchController)
        searchController.didMove(toParentViewController: self)
        
        self.changeState(state: .pageNavigation) //initialState
    }
    
    private func setStyling() {
        view.backgroundColor = UIColor.clear
        setStylingPageNavigation()
        setStylingBrowserViewController()
        setStylingSearchViewController()
    }
    
    private func setConstraints() {
        setConstraintsPageNavigation()
        setConstraintsBrowserViewController()
        setConstraintsSearchViewController()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


//All things related to state have to go through here
extension ContentNavigationViewController {

    //TO DO: animation transitions should be defined for the state change.
    
    func browserVisible(text: String?, completion: (() -> ())?) -> [Transition] {
        let transition = Transition(endState: {
            self.browserVC.view.alpha = 1.0
        }, beforeTransition: {
            self.showBrowser(url: text)
            self.view.layoutIfNeeded()
        }, afterTransition: {
            if let c = completion {
                c()
            }
        }, animationDetails: AnimationDetails(duration: 0.2, curve: .easeIn, delayFactor: 0.0))
        
        return [transition]
    }
    
    func browserHidden() -> [Transition] {
        let transition = Transition(endState: {
            self.browserVC.view.alpha = 0.0
        }, beforeTransition: {
            //
        }, afterTransition: {
            self.browserVC.view.isHidden = true
            self.view.layoutIfNeeded()
        }, animationDetails: AnimationDetails(duration: 0.12, curve: .easeOut, delayFactor: 0.0))
        
        return [transition]
    }
    
    func pageNavVisible(completion: (() -> ())?) -> [Transition] {
        let transition = Transition(endState: {
            self.pageNavVC.view.alpha = 1.0
        }, beforeTransition: {
            self.pageNavVC.view.isHidden = false
            self.view.layoutIfNeeded()
        }, afterTransition: {
            if let c = completion {
                c()
            }
        }, animationDetails: AnimationDetails(duration: 0.10, curve: .easeIn, delayFactor: 0.0))
        
        return [transition]
    }
    
    func pageNavHidden() -> [Transition] {
        let transition = Transition(endState: {
            self.pageNavVC.view.alpha = 0.0
        }, beforeTransition: {
            //
        }, afterTransition: {
            self.pageNavVC.view.isHidden = true
            self.view.layoutIfNeeded()
        }, animationDetails: AnimationDetails(duration: 0.12, curve: .easeOut, delayFactor: 0.0))
        
        return [transition]
    }
    
    func searchVisible(text: String?, completion: (() -> ())?) -> [Transition] {
        let transition = Transition(endState: {
            self.searchController.view.alpha = 1.0
        }, beforeTransition: {
            self.showSearchController(text: text)
            self.view.layoutIfNeeded()
        }, afterTransition: {
            if let c = completion {
                c()
            }
        }, animationDetails: AnimationDetails(duration: 0.10, curve: .easeIn, delayFactor: 0.0))
        
        return [transition]
    }
    
    func searchHidden() -> [Transition] {
        let transition = Transition(endState: {
            self.searchController.view.alpha = 0.0
        }, beforeTransition: {
            //
        }, afterTransition: {
            self.searchController.view.isHidden = true
            self.view.layoutIfNeeded()
        }, animationDetails: AnimationDetails(duration: 0.12, curve: .easeOut, delayFactor: 0.0))
        
        return [transition]
    }

    func changeState(state: State, text: String? = nil) {
        guard currentState != state else {
            return
        }
        
        currentState = state
        animateToState(state: currentState, text: text, completion: {
            if self.currentState != .pageNavigation {
                //reset page Navigation
                self.pageNavVC.resetNavigation()
            }
        })
        
        stateDelegate?.stateChanged(component: "ContentNav")
    }
    
    fileprivate func animateToState(state: State, text: String?, completion: (() -> ())?) {
        StateAnimator.animate(animators: generateAnimators(state: state, text: text, completion: completion))
    }
    
    private func generateAnimators(state: State, text: String?, completion: (() -> ())?) -> [Animator] {
        return StateAnimator.generateAnimators(state: generateState(state: state, text: text, completion: completion), parentView: self.view)
    }
    
    fileprivate func generateState(state: State, text: String?, completion: (() -> ())?) -> [Transition] {
        switch state {
        case .pageNavigation:
            return self.browserHidden() + self.searchHidden() + self.pageNavVisible(completion: completion)
        case .browser:
            return self.searchHidden() + self.pageNavHidden() + self.browserVisible(text: text, completion: completion)
        case .search:
            return self.browserHidden() + self.pageNavHidden() + self.searchVisible(text: text, completion: completion)
        case .undefined:
            return []
        }
    }
}

//Router 
extension ContentNavigationViewController {
    //This will be refactored. States will be introduced and as well as a central place for the diplay logic.
    
    func browse(url: String?, tab: Tab?) {

        if let url = url {
            browseURL(url: url)
        }
        else if let tab = tab {
            browseTab(tab: tab)
        }
        
    }
    
    func browseURL(url: String?) {
		changeState(state: .browser, text: url)
    }

    func browseTab(tab: Tab) {
        tabManager.selectTab(tab)
        changeState(state: .browser)
    }
    
    func search(query: String?) {
        changeState(state: .search, text: query)
        searchController.searchQuery = query ?? ""
    }
    
    func domains(currentState: ContentState) {
        pageNavVC.showDots()
        changeState(state: .pageNavigation)
        if currentState == .dash {
            pageNavVC.showDomains()
        }
        else if currentState == .details {
            pageNavVC.historyNavigation.showHistory()
        }
    }
    
    func details(indexPath: IndexPath?, image: UIImage?) {
        pageNavVC.hideDots()
        if let indexPath = indexPath {
            pageNavVC.historyNavigation.showDetails(indexPath: indexPath, image: image)
        }
    }
    
    func dash() {
        changeState(state: .pageNavigation)
        pageNavVC.showDots()
        pageNavVC.showDashBoard()
    }
    
    func textInUrlBarChanged(text: String) {

        searchController.searchQuery = text
        
        if text != "" {
            if currentState != .search {
                changeState(state: .search)
            }
        }
        else {
            changeState(state: .pageNavigation)
        }
    }
    
    func textIUrlBarCleared() {
        textInUrlBarChanged(text: "")
    }
    
    func backPressedUrlBar() {
        //
    }
    
    func homePressed() {
        if currentState == .browser {
            changeState(state: .pageNavigation)
        }
        else if currentState == .pageNavigation {
            if pageNavVC.currentState == .History {
                if pageNavVC.historyNavigation.currentState == .Domains {
                    pageNavVC.navigate()
                }
                else if pageNavVC.historyNavigation.currentState == .Details {
                    pageNavVC.historyNavigation.showHistory()
                }
            }
            else if pageNavVC.currentState == .DashBoard {
                pageNavVC.navigate()
            }
        }
        else if currentState == .search {
            changeState(state: .pageNavigation)
        }
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
        
        self.browserVC.view.isHidden = false
		if let u = url {
			var validURL = URIFixup.getURL(u)
			if validURL == nil {
				validURL = self.profile.searchEngines.defaultEngine.searchURLForQuery(u)
			}
			self.browserVC.loadURL(validURL)
			//Router.shared.action(action: Action(data: (validURL != nil ? ["url": validURL!] : nil), type: .urlIsModified, context: .urlBarVC))
		}
    }
    
    func hideBrowser() {
        self.browserVC.view.isHidden = true
    }

    func setStylingBrowserViewController() {
        
    }

    func setConstraintsBrowserViewController() {
        browserVC.view.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
        }
    }
}

//SearchViewController
extension ContentNavigationViewController {
    
    func showSearchController(text: String?) {
        
        searchController.view.isHidden = false
        searchController.searchQuery = text
        //searchController?.sendUrlBarFocusEvent()
        
        resetNavigationSteps()
    }
    
    func hideSearchController() {
        searchController.view.isHidden = true
    }
    
    func setStylingSearchViewController() {
        
    }
    
    func setConstraintsSearchViewController() {
        searchController.view.snp.remakeConstraints({ (make) in
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
        StateManager.shared.handleAction(action: Action(data: ["url": url.absoluteString], type: .urlSelected, context: .contentNavVC))
    }
    
    func searchForQuery(_ query: String) {

    }

    func autoCompeleteQuery(_ autoCompleteText: String) {
        Router.shared.action(action: Action(data: ["text": autoCompleteText], type: .searchAutoSuggest, context: .contentNavVC))
    }
    
    func stopEditing() {
        StateManager.shared.handleAction(action: Action(data: nil, type: .searchStopEditing, context: .contentNavVC))
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
