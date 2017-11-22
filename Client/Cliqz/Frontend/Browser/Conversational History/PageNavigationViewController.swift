//
//  PageNavigationViewController.swift
//  Client
//
//  Created by Tim Palade on 8/11/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class PageNavigationViewController: UIViewController {

    
    let pageControl: CustomDots
    let surfViewController: SurfViewController
    
    let historyNavigation: HistoryNavigationViewController
    let dashboardVC: DashViewController
    
    enum State {
        case History
        case DashBoard
    }
    
    let stateIndex : [State : Int] = [.History: 1, .DashBoard: 0]
    
    var currentState: State = .History
    
    //styling
    let pageControlHeight: CGFloat = 24.0
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        historyNavigation = HistoryNavigationViewController()
        historyNavigation.externalDelegate = Router.shared
        
        dashboardVC = DashViewController()
        
        surfViewController = SurfViewController(viewControllers: [dashboardVC, historyNavigation], initial: stateIndex[currentState]!)
        pageControl = CustomDots(numberOfPages: 2, currentPage: stateIndex[currentState]!)
        
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
    
    func setUpComponent() {
        addController(viewController: surfViewController)
        self.view.addSubview(pageControl)
		let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwipe(_:)))
		rightSwipe.direction = .right
		self.view.addGestureRecognizer(rightSwipe)
		let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftSwipe(_:)))//UISwipeGestureRecognizer(target: self, action: #selector(swipeView(_:)))
		leftSwipe.direction = .left
		self.view.addGestureRecognizer(leftSwipe)
    }

    func setStyling() {
        self.view.backgroundColor = .clear
        self.pageControl.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    func setConstraints() {
        pageControl.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(pageControlHeight)
        }
        
        surfViewController.view.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(pageControl.snp.top)
        }
    }
    
    func resetNavigation() {
        if pageControl.currentPage == stateIndex[.DashBoard] {
            self.navigate() //go back to first screen (Domains)
        }
        
        historyNavigation.nc.popToRootViewController(animated: false)
        historyNavigation.conversationalHistory.view.alpha = 1.0
    }
    
    func showDashBoard(animated: Bool) {
        if pageControl.currentPage == stateIndex[.History] {
            pageControl.changePage(page: stateIndex[.DashBoard]!)
            if stateIndex[.DashBoard]! > stateIndex[.History]! {
                surfViewController.showNext(animated: animated)
            }
            else {
                surfViewController.showPrev(animated: animated)
            }
            currentState = .DashBoard
        }
    }
    
    func showDomains() {
        if pageControl.currentPage == stateIndex[.DashBoard] {
            pageControl.changePage(page: stateIndex[.History]!)
            if stateIndex[.History]! > stateIndex[.DashBoard]! {
                surfViewController.showNext(animated: true)
            }
            else {
                surfViewController.showPrev(animated: true)
            }
            currentState = .History
        }
    }
    
    func navigate() {
        if currentState == .History {
            showDashBoard(animated: true)
        }
        else if currentState == .DashBoard {
            showDomains()
        }
    }
    
    func showDots() {
        pageControl.alpha = 1.0
        pageControl.snp.updateConstraints { (make) in
            make.height.equalTo(pageControlHeight)
        }
        self.view.layoutIfNeeded()
    }
    
    func hideDots() {
        pageControl.alpha = 0.0
        pageControl.snp.updateConstraints { (make) in
            make.height.equalTo(0)
        }
        self.view.layoutIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func addController(viewController: UIViewController) {
        self.addChildViewController(viewController)
        self.view.addSubview(viewController.view)
        viewController.didMove(toParentViewController: self)
    }
    
    private func removeController(viewController: UIViewController) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
	}

	@objc private func rightSwipe(_ recognizer: UISwipeGestureRecognizer) {
		StateManager.shared.handleAction(action: Action(type: .pageNavRightSwipe))
	}
    
    @objc private func leftSwipe(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        StateManager.shared.handleAction(action: Action(type: .pageNavLeftSwipe))
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
