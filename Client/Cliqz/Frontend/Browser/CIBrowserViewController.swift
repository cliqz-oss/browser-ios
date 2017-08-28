//
//  CIBrowserViewController.swift
//  Client
//
//  Created by Tim Palade on 8/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

final class CIBrowserViewController: UIViewController {
    
    private let label = UILabel()
    
    var navigationStep: Int = 0
    var backNavigationStep: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpComponent()
        setStyling()
        setConstraints()
    }
    
    func setUpComponent() {
        label.text = "CIBrowserViewController"
        view.addSubview(label)
    }
    
    func setStyling() {
        view.backgroundColor = UIColor.init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    }
    
    func setConstraints() {
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension CIBrowserViewController: TabManagerDelegate {
    
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
        
    }
    
    func tabManager(_ tabManager: TabManager, didCreateTab tab: Tab) {
        
    }
    
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
        
    }
    
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, removeIndex: Int) {
        
    }
    
    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        
    }
    
    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        
    }
    
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast:ButtonToast?) {
    
    }
}












