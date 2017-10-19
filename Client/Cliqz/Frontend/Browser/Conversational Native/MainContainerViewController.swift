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
	let profile: Profile?
	
    let searchLoader: SearchLoader
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		
		// TODO: Refactor profile/tabManager creation and contentNavVC initialization
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.profile = appDelegate.profile
		self.tabManager = appDelegate.tabManager
		
        searchLoader = SearchLoader(profile: self.profile!)
        contentNavVC = ContentNavigationViewController(profile: self.profile!, tabManager: tabManager, searchLoader: searchLoader)
        
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
        
        StateManager.shared.handleAction(action: Action(type: .initialization))
		
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

	override var canBecomeFirstResponder: Bool {
		get {
			return true
		}
	}

	override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
		if motion == .motionShake,
			let profile = self.profile {
			let alert = UIAlertController(title: "Do you want to clear the history?", message: "", preferredStyle: .alert)
			let dismiss = UIAlertAction(title: "Cancel", style: .cancel)
			let open    = UIAlertAction(title: "Clean", style: .default) { (action) in
				// TODO: update UI after
				let _ = HistoryClearable(profile: profile).clear()
			}
			alert.addAction(dismiss)
			alert.addAction(open)
			self.present(alert, animated: true, completion: nil)
		}
	}

    private func prepareModules() {
        _ = NewsManager.sharedInstance
        _ = DomainsModule.shared
    }
    
    private func setUpComponent() {
        
        self.view.addSubview(backgroundImage)
        
        self.addChildViewController(contentNavVC)
        self.view.addSubview(contentNavVC.view)
        
        self.addChildViewController(URLBarVC)
        self.view.addSubview(URLBarVC.view)
        
        self.addChildViewController(toolbarVC)
        self.view.addSubview(toolbarVC.view)
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
            
        }, afterTransition: completion, animationDetails: AnimationDetails(duration: 0.01, curve: .linear, delayFactor: 0.0))
        
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
            
            let tab = self.tabManager.tabs[indexPath.row]
            //think about how tab selection should happen. If the tab is not navigated to, it is not selected even if pressed (because browseTab is not called). I think selection should not happen there.
            //selection should happen in StateManager. TabManager should be a singleton and therefore I can use it.
            //tabManager.selectTab(tab)
            StateManager.shared.handleAction(action: Action(data: ["tab": tab, "url": tab.url?.absoluteString as Any], type: .tabSelected))
            
            dismissTabOverview(tabsVC: tabsVC, completion: {
				
            })
        }
    }

    func donePressed(tabsVC: TabsViewController?) {
        //pass this through the State Manager -- after
        dismissTabOverview(tabsVC: tabsVC, completion: nil)
    }
    
    //
    func plusPressed(tabsVC: TabsViewController?) {
        //tab is already selected by this point
        let tab = tabManager.tabs[tabManager.tabs.count - 1]
        StateManager.shared.handleAction(action: Action(data: ["tab": tab, "url": tab.url?.absoluteString as Any], type: .tabSelected))
        //dismissal should come from StateManager
        dismissTabOverview(tabsVC: tabsVC, completion: nil)
        
    }
}
