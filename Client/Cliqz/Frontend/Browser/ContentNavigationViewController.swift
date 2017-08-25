//
//  ContentNavigationViewController.swift
//  Client
//
//  Created by Tim Palade on 8/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class ContentNavigationViewController: UIViewController {
    
    private let browserVC = CIBrowserViewController()
    private let pageNavVC = PageNavigationViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpComponent()
        setStyling()
        setConstraints()
    }
    
    private func setUpComponent() {
        self.addChildViewController(pageNavVC)
        view.addSubview(pageNavVC.view)
    }
    
    private func setStyling() {
        view.backgroundColor = UIColor.clear
    }
    
    private func setConstraints() {
        pageNavVC.view.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
    
    func navigateToBrowser() {
        self.addChildViewController(browserVC)
        view.addSubview(browserVC.view)
        
        browserVC.view.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
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
