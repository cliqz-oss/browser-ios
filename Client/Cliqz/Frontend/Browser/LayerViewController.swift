//
//  LayerViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 11/26/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import UIKit

class LayerViewController: UIViewController {
    
    var dummyImageView: UIImageView?
    
    //MARK: - init and configuration
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        didInit()
    }
    
    func didInit() {
        // should be overriden by the drived class
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    deinit {
        
    }
    
    //MARK: - View lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = .None
        prepareView()
        setupConstraints()
    }
    func prepareView() {
        // should be overriden by the drived class
        dummyImageView = UIImageView(frame:self.view.frame)
        self.view.addSubview(dummyImageView!)
    }
    
    func setupConstraints() {
        // should be overriden by the drived class
    }
    
    func createUIBarButton(imageName: String, action: Selector) -> UIBarButtonItem {

        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: imageName), forState: UIControlState.Normal)
        button.addTarget(self, action: action, forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 20, 20)
        
        let barButton = UIBarButtonItem(customView: button)
        return barButton
    }
    //MARK: - Actions
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
}
