//
//  ToolbarViewController.swift
//  Client
//
//  Created by Tim Palade on 8/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

final class ToolbarViewController: UIViewController {
    
    let toolBarView = CIToolBarView()
    
    //TO DO: states.
    enum State {
        case browsing
        case notBrowsing
        case undefined
    }
    
    var currentState: State = .undefined

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpComponent()
        setStyling()
        setConstraints()
    }

    func setUpComponent() {
        toolBarView.delegate = self
        view.addSubview(toolBarView)
        
        changeState(state: .notBrowsing) //initialState
    }
    
    func setStyling() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    func setConstraints() {
        toolBarView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


//handle states
//Here are the state rules: 
//If not browsing: back, forward and share are disabled
//If browsing back and forward should be enabled/disabled and the share should be enabled.


extension ToolbarViewController {
    func changeState(state: State) {
        guard currentState != state else {
            return
        }
        
        if state == .browsing {
            toolBarView.shareButton.isEnabled = true
        }
        else if state == .notBrowsing {
            toolBarView.backButton.isEnabled = false
            toolBarView.forwardButton.isEnabled = false
            toolBarView.shareButton.isEnabled = false
        }
        
        currentState = state
        
    }
    
    func setBackEnabled() {
        guard currentState == .browsing else {
            return
        }
        
        toolBarView.backButton.isEnabled = true
        
    }
    
    func setBackDisabled() {
        guard currentState == .browsing else {
            return
        }
        
        toolBarView.backButton.isEnabled = false
    }
    
    func setForwardEnabled() {
        guard currentState == .browsing else {
            return
        }
        
        toolBarView.forwardButton.isEnabled = true
        
    }
    
    func setForwardDisabled() {
        guard currentState == .browsing else {
            return
        }
        
        toolBarView.forwardButton.isEnabled = false
    }
    
}

extension ToolbarViewController: CIToolBarDelegate {
    
    func backPressed() {
        
    }
    
    func forwardPressed() {
        
    }
    
    func middlePressed() {
        Router.shared.action(action: Action(data: nil, type: .homeButtonPressed, context: .contentNavVC))
    }
    
    func sharePressed() {
        
    }
    
    func tabsPressed() {
        
    }
    
}
