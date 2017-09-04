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
        case navigationAllowed
        case navigationNotAllowed
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
        
        changeState(state: .navigationNotAllowed) //initialState
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
extension ToolbarViewController {
    func changeState(state: State) {
        guard currentState != state else {
            return
        }
        
        if state == .navigationAllowed {
            toolBarView.backButton.isEnabled = true
            toolBarView.forwardButton.isEnabled = true
            toolBarView.shareButton.isEnabled = true
        }
        else if state == .navigationNotAllowed {
            toolBarView.backButton.isEnabled = false
            toolBarView.forwardButton.isEnabled = false
            toolBarView.shareButton.isEnabled = false
        }
        
        currentState = state
        
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
