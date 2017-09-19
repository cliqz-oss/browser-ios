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

protocol StateDelegate: class {

    func stateChanged(component: String)
}

class MainContainerViewController: UIViewController {
    
    enum State {
        case hidden
        case visible
    }
    
    fileprivate var currentState: State = .visible
    
    fileprivate let backgroundImage = UIImageView()
    
    fileprivate let URLBarVC = URLBarViewController()
    fileprivate let contentNavVC: ContentNavigationViewController
    fileprivate let toolbarVC = ToolbarViewController()
    
    let tabManager: TabManager
    
    let searchLoader: SearchLoader
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		
		// TODO: Refactor profile/tabManager creation and contentNavVC initialization
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let profile = appDelegate.profile
		self.tabManager = appDelegate.tabManager
		if self.tabManager.tabs.count == 0 {
			_ = self.tabManager.addTabAndSelect()
		}
        searchLoader = SearchLoader(profile: profile!)
        contentNavVC = ContentNavigationViewController(profile: profile!, tabManager: tabManager, searchLoader: searchLoader)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        contentNavVC.stateDelegate = self

        URLBarVC.search_loader = searchLoader

        Router.shared.registerController(viewController: contentNavVC)
        Router.shared.registerController(viewController: self)
		Router.shared.registerController(viewController: URLBarVC)
        
        StateManager.shared.mainCont = self
        StateManager.shared.contentNav = contentNavVC
        StateManager.shared.urlBar = URLBarVC
        StateManager.shared.toolBar = toolbarVC
		
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
}

//state
extension MainContainerViewController {
    
    func changeState(state: State, completion: (() -> ())?) {
        
        guard state != currentState else {
            return
        }
        
        currentState = state
        
        animateToState(state: currentState, completion: completion)
    }

    fileprivate func visibleState(completion: (() -> ())?) -> [Transition] {
        let transition = Transition(endState: {
            self.contentNavVC.view.alpha = 1.0
            self.URLBarVC.view.alpha = 1.0
            self.toolbarVC.view.alpha = 1.0
            
        }, afterTransition: completion, animationDetails: AnimationDetails(duration: 0.1, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }

    fileprivate func hiddenState(completion: (() -> ())?) -> [Transition] {
        let transition = Transition(endState: {
            self.contentNavVC.view.alpha = 0.0
            self.URLBarVC.view.alpha = 0.0
            self.toolbarVC.view.alpha = 0.0
            
        }, afterTransition: completion, animationDetails: AnimationDetails(duration: 0.04, curve: .linear, delayFactor: 0.0))
        
        return [transition]
    }
    
    fileprivate func animateToState(state: State, completion: (() -> ())?) {
        StateAnimator.animate(animators: generateAnimators(state: state, completion: completion))
    }
    
    private func generateAnimators(state: State, completion: (() -> ())?) -> [Animator] {
        return StateAnimator.generateAnimators(state: generateState(state: state, completion: completion), parentView: self.view)
    }
    
    fileprivate func generateState(state: State, completion: (() -> ())?) -> [Transition] {
        switch state {
        case .visible:
            return self.visibleState(completion: completion)
        case .hidden:
            return self.hiddenState(completion: completion)
        }
    }
}

//receive actions
extension MainContainerViewController {

    //TO DO: Centralized decision place

    func autoSuggestURLBar(autoSuggestText: String) {
        URLBarVC.setAutocompleteSuggestion(autoSuggestText)
    }

    func stopEditing() {
        //URLBarVC.stopEditing()
    }

}

extension MainContainerViewController: StateDelegate {

    func stateChanged(component: String) {
        if component == "ContentNav" {
            if contentNavVC.currentState == .browser {
                toolbarVC.changeState(state: .browsing)
            }
            else {
                toolbarVC.changeState(state: .notBrowsing)
            }
        }
    }
}

//Tab Overview Show
extension MainContainerViewController {

    func showTabOverView(){
        changeState(state: .hidden, completion: {
            
            let tabsVC = TabsViewController(tabManager: self.tabManager)
            tabsVC.delegate = self
            tabsVC.view.backgroundColor = .clear
            self.addChildViewController(tabsVC)
            self.view.addSubview(tabsVC.view)
            
            let transition = Transition(endState: {
                
                //tabsVC.view.alpha = 1.0
                
                tabsVC.view.snp.remakeConstraints({ (make) in
                    make.top.equalTo(self.view)
                    make.width.equalToSuperview()
                    make.height.equalToSuperview()
                })
            }, beforeTransition: {
                
                //tabsVC.view.alpha = 0.0
                
                tabsVC.view.snp.makeConstraints({ (make) in
                    make.height.equalToSuperview()
                    make.top.equalTo(self.view.snp.bottom)
                    make.width.equalToSuperview()
                })
                
                self.view.layoutIfNeeded()
                
            }, afterTransition: nil, animationDetails: AnimationDetails(duration: 0.16, curve: .linear, delayFactor: 0.0))
            
            let animators = StateAnimator.generateAnimators(state: [transition], parentView: self.view)
            StateAnimator.animate(animators: animators)
        })
    }
    
    func dismissTabOverview(tabsVC: TabsViewController?, completion: (() -> ())?) {
        
        guard let vc = tabsVC else {
            return
        }
        
        let transition = Transition(endState: {
            vc.view.snp.remakeConstraints({ (make) in
                make.height.equalToSuperview()
                make.top.equalTo(self.view.snp.bottom)
                make.width.equalToSuperview()
            })
        }, afterTransition: {
            vc.removeFromParentViewController()
            vc.view.removeFromSuperview()
            
            self.changeState(state: .visible, completion: {
                if let completion_block = completion {
                    completion_block()
                }
            })
            
        }, animationDetails: AnimationDetails(duration: 0.2, curve: .easeIn, delayFactor: 0.0))
        
        let animators = StateAnimator.generateAnimators(state: [transition], parentView: self.view)
        StateAnimator.animate(animators: animators)
        
    }
}

extension MainContainerViewController: TabsViewControllerDelegate {

    func itemPressed(tabsVC: TabsViewController?, indexPath: IndexPath) {
        if indexPath.row >= 0 && indexPath.row < self.tabManager.tabs.count {
            dismissTabOverview(tabsVC: tabsVC, completion: {
				let tab = self.tabManager.tabs[indexPath.row]
                StateManager.shared.handleAction(action: Action(data: ["tab": tab], type: .tabSelected, context: .mainContainer))
            })
        }
    }

    func donePressed(tabsVC: TabsViewController?) {
        //pass this through the State Manager -- after
        dismissTabOverview(tabsVC: tabsVC, completion: nil)
    }
}

extension MainContainerViewController {

//	fileprivate func switchTab(_ tab: Tab) {
//		self.tabManager.selectTab(tab)
//		switchContentState(tab.currentNavigationState())
//	}
//
//	fileprivate func switchContentState(_ tabState: TabNavigationState) {
//		var data: String?
//		var state = ContentNavigationViewController.State.pageNavigation
//		var toolbarState = ToolbarViewController.State.notBrowsing
//		switch tabState {
//		case .web(let a):
//			state = .browser
//			data = a
//			toolbarState = .browsing
//		case .home:
//			state = .pageNavigation
//			//self.URLBarVC.updateURL(nil)
//		case .search(let a):
//			state = .search
//			data = a
//			//self.URLBarVC.startEditing(initialText: data, pasted: false)
//		}
//		self.toolbarVC.changeState(state: toolbarState)
//		if let tab = self.tabManager.selectedTab {
//			self.toolbarVC.setIsBackEnabled(tab.canGoBack)
//			self.toolbarVC.setIsForwardEnabled(tab.canGoForward)
//		}
//		self.contentNavVC.changeState(state: state, text: data)
//	}
//
//	fileprivate func switchContentAndTabState(_ state: ContentNavigationViewController.State, stateData: String? = nil) {
//		if let tab = self.tabManager.selectedTab {
//			switch self.contentNavVC.currentState {
//			case .pageNavigation:
//				tab.navigateToState(.home)
//			case .search:
//				let navState = TabNavigationState.search(self.contentNavVC.searchController.searchQuery ?? "")
//				tab.navigateToState(navState)
//			default:
//				print("No need to log browser state")
//			}
//			self.toolbarVC.setIsBackEnabled(tab.canGoBack)
//			self.toolbarVC.setIsForwardEnabled(tab.canGoForward)
//		}
//		self.contentNavVC.changeState(state: state, text: stateData)
//	}

//	func urlSelected(url: String) {
////		switchContentAndTabState(.browser, stateData: url)
////		self.toolbarVC.changeState(state: .browsing)
////		if let tab = self.tabManager.selectedTab {
////			self.toolbarVC.setIsBackEnabled(tab.canGoBack)
////			self.toolbarVC.setIsForwardEnabled(tab.canGoForward)
////		}
//
//	}
//
//	func urlIsModified(_ url: URL?) {
//		if self.contentNavVC.currentState == .browser {
//			//self.URLBarVC.updateURL(url)
//			if let tab = self.tabManager.selectedTab {
//				self.toolbarVC.setIsBackEnabled(tab.canGoBack)
//				self.toolbarVC.setIsForwardEnabled(tab.canGoForward)
//			}
//		}
//	}
//
//	func urlbCancelEditing() {
//		if self.contentNavVC.currentState == .search {
//			if let tab = self.tabManager.selectedTab {
//				self.switchContentState(tab.currentNavigationState())
//				self.toolbarVC.setIsBackEnabled(tab.canGoBack)
//				self.toolbarVC.setIsForwardEnabled(tab.canGoForward)
//			}
//		}
//	}
//
//	func homeButtonPressed() {
//		if self.contentNavVC.currentState != .pageNavigation {
//			switchContentAndTabState(.pageNavigation)
//			self.toolbarVC.changeState(state: .notBrowsing)
//			//self.URLBarVC.updateURL(nil)
//			if let tab = self.tabManager.selectedTab {
//				self.toolbarVC.setIsBackEnabled(tab.canGoBack)
//				self.toolbarVC.setIsForwardEnabled(tab.canGoForward)
//			}
//		} else {
//			self.contentNavVC.homePressed()
//		}
//	}
//
//	func backButtonPressed() {
//		if let tab = self.tabManager.selectedTab,
//			let newState = tab.goBack() {
//			switchContentState(newState)
//		}
//	}
//
//	func forwardButtonPressed() {
//		if let tab = self.tabManager.selectedTab,
//			let newState = tab.goForward() {
//			switchContentState(newState)
//		}
//	}
//
//	func textInUrlBarChanged(text: String) {
//		if self.contentNavVC.currentState != .search {
//			// TODO: should be called state change properly
//			switchContentAndTabState(.search, stateData: text)
//			if let tab = self.tabManager.selectedTab {
//				self.toolbarVC.setIsBackEnabled(tab.canGoBack)
//				self.toolbarVC.setIsForwardEnabled(tab.canGoForward)
//			}
//		}
//		self.contentNavVC.textInUrlBarChanged(text: text)
//	}

//	func tabSelected() {
////		if let data = action.data, let tab = data["tab"] as? Tab {
//			contentNavVC?.browseTab(tab: tab)
////		}
//	}
}





