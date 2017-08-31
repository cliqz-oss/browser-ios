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
    
    
    //styling
    let pageControlHeight: CGFloat = 24.0
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        let historyNavigation = HistoryNavigationViewController()
        historyNavigation.externalDelegate = Router.shared
        
        surfViewController = SurfViewController(viewControllers: [historyNavigation, DashViewController()])
        
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.pageControl.addGestureRecognizer(tap)
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
    
    @objc
    func tapped(_ sender: UITapGestureRecognizer) {
        if pageControl.currentPage == 0 {
            pageControl.changePage(page: 1)
            surfViewController.showNext()
        }
        else {
            pageControl.changePage(page: 0)
            surfViewController.showPrev()
        }
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
