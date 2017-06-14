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
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIInterfaceOrientationMask.allButUpsideDown
        } else {
            return UIInterfaceOrientationMask.all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    deinit {
        
    }
    
    //MARK: - View lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge()
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
    
    func createUIBarButton(_ imageName: String, action: Selector) -> UIBarButtonItem {

        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: imageName), for: UIControlState())
        button.addTarget(self, action: action, for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        let barButton = UIBarButtonItem(customView: button)
        return barButton
    }
    //MARK: - Actions
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
}
