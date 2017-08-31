//
//  ToolbarViewController.swift
//  Client
//
//  Created by Tim Palade on 8/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class ToolbarViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goHome(_:)))
		self.view.addGestureRecognizer(tapGestureRecognizer)

        // Do any additional setup after loading the view.
        setUpComponent()
        setStyling()
        setConstraints()
    }
	
	func goHome(_ gestureReconizer: UITapGestureRecognizer) {
		Router.shared.action(action: Action(data: nil, type: .homeButtonPressed, context: .contentNavVC))
	}

    func setUpComponent() {
        
    }
    
    func setStyling() {
        view.backgroundColor = UIColor.black
    }
    
    func setConstraints() {
        
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
