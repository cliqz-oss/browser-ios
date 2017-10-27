//
//  PageNavigationViewController.swift
//  Client
//
//  Created by Tim Palade on 8/11/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class PageNavigationViewController: UIViewController {

    
    let pageControl = CustomDots(numberOfPages: 2)
    let surfViewController: SurfViewController
    
    let historyNavigation: HistoryNavigationViewController
    let dashboardVC: DashViewController
    
    enum State {
        case History
        case DashBoard
    }
    
    var currentState: State = .History
    
    //styling
    let pageControlHeight: CGFloat = 24.0
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        historyNavigation = HistoryNavigationViewController()
        historyNavigation.externalDelegate = Router.shared
        
        dashboardVC = DashViewController()
        
        surfViewController = SurfViewController(viewControllers: [historyNavigation, dashboardVC])
        
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
		let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeView(_:)))
		leftSwipe.direction = .left
		self.view.addGestureRecognizer(leftSwipe)
		let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeView(_:)))
		rightSwipe.direction = .right
		self.view.addGestureRecognizer(rightSwipe)
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
        if pageControl.currentPage == 1 {
            self.navigate() //go back to first screen (Domains)
        }
        
        historyNavigation.nc.popToRootViewController(animated: false)
        historyNavigation.conversationalHistory.view.alpha = 1.0
        
        currentState = .History
    }
    
    func showDashBoard() {
        if pageControl.currentPage == 0 {
            pageControl.changePage(page: 1)
            surfViewController.showNext()
            currentState = .DashBoard
        }
    }
    
    func showDomains() {
        if pageControl.currentPage == 1 {
            pageControl.changePage(page: 0)
            surfViewController.showPrev()
            currentState = .History
        }
    }
    
    func navigate() {
        if pageControl.currentPage == 0 && self.historyNavigation.currentState == .Domains {
            pageControl.changePage(page: 1)
            surfViewController.showNext()
            currentState = .DashBoard
        }
        else {
            pageControl.changePage(page: 0)
            surfViewController.showPrev()
            currentState = .History
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

	@objc private func swipeView(_ gestureRecognizer: UISwipeGestureRecognizer) {
		if gestureRecognizer.direction == .right && self.pageControl.currentPage == 1 {
			self.navigate()
		}
		if gestureRecognizer.direction == .left && self.pageControl.currentPage == 0 {
			self.navigate()
		}
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
