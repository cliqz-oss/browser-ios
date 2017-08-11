//
//  MainContainerViewController.swift
//  Client
//
//  Created by Tim Palade on 8/1/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class MainContainerViewController: UIViewController {
    
    private let URLBarVC = URLBarViewController()
    private let ConversationalVC = PageNavigationViewController()//DashViewController()//ConversationalContainer()
    private let backgroundImage = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundImage.layer.zPosition = -100
        backgroundImage.image = UIImage(named: "conversationalBG")
        self.view.addSubview(backgroundImage)

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor(colorString: "E9E9E9")        
        self.addChildViewController(URLBarVC)
        self.view.addSubview(URLBarVC.view)
        
        self.addChildViewController(ConversationalVC)
        self.view.addSubview(ConversationalVC.view)
        
        setConstraints()
    }
    
    private func setConstraints() {
        
        backgroundImage.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalTo(self.view)
        }
        
        URLBarVC.view.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(URLBarVC.URLBarHeight)
        }
        
        ConversationalVC.view.snp.makeConstraints { (make) in
            make.top.equalTo(URLBarVC.view.snp.bottom)
            make.left.right.bottom.equalTo(self.view)
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
