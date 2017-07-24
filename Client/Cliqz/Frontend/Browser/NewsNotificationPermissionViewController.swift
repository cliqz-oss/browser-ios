//
//  NewsNotificationPermissionViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 5/30/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit
import Shared

private enum PermissionState {
    case firstTimeAsking
    case subsequentAsking
    case howToEnable
}

struct NewsNotificationPermissionViewControllerUX {
    static let Width = 375
    static let Height = 600
    static let ActionButtonWidth = 200
    static let ActionButtonHeight = 35
    static let greenColor = UIColor(red: 75 / 255, green: 214 / 255, blue: 99 / 255, alpha: 1)
    static let blueColor = UIColor(red: 29 / 255, green: 85 / 255, blue: 160 / 255, alpha: 1)
    
}

class NewsNotificationPermissionViewController: UIViewController {

    fileprivate lazy var newsNotificationPermissionHelper = NewsNotificationPermissionHelper.sharedInstance
    
    fileprivate lazy var yesButton: UIButton = {
        let title = NSLocalizedString("Yes please!", tableName: "Cliqz", comment: "Button label to `Yes please` in news notification permission screen")
        let button = self.createButton(title, titleColor: UIColor.white, backgroundColor: NewsNotificationPermissionViewControllerUX.blueColor, action: #selector(NewsNotificationPermissionViewController.SELdidClickYes))
        return button
    }()
    
    fileprivate lazy var laterButton: UIButton = {
        let title = NSLocalizedString("Remind me later", tableName: "Cliqz", comment: "Button label to `Remind me later` in news notification permission screen")
        let button = self.createButton(title, titleColor: NewsNotificationPermissionViewControllerUX.blueColor, backgroundColor: UIColor.white, action: #selector(NewsNotificationPermissionViewController.SELdidClickLater))
        button.layer.borderColor = NewsNotificationPermissionViewControllerUX.blueColor.cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    fileprivate lazy var noButton: UIButton = {
        let title = NSLocalizedString("No thanks", tableName: "Cliqz", comment: "Button label to `No thanks` in news notification permission screen")
        let button = self.createButton(title, titleColor: NewsNotificationPermissionViewControllerUX.blueColor, backgroundColor: UIColor.white, action: #selector(NewsNotificationPermissionViewController.SELdidClickNo))
        button.layer.borderColor = NewsNotificationPermissionViewControllerUX.blueColor.cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    fileprivate lazy var okButton: UIButton = {
        let title = NSLocalizedString("OK", tableName: "Cliqz", comment: "Button label to `OK` in news notification permission screen")
        let button = self.createButton(title, titleColor: UIColor.white, backgroundColor: NewsNotificationPermissionViewControllerUX.greenColor, action: #selector(NewsNotificationPermissionViewController.SELdidClickOk))
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationController?.isNavigationBarHidden = true
        self.view.backgroundColor = UIColor.white
        
        if newsNotificationPermissionHelper.isAskingForPermissionDisabled() {
            addBackgroundImage(.howToEnable)
            addActionButtons(.howToEnable)
        } else if newsNotificationPermissionHelper.isAksedForPermissionBefore() {
            addBackgroundImage(.subsequentAsking)
            addActionButtons(.subsequentAsking)
        } else {
            addBackgroundImage(.firstTimeAsking)
            addActionButtons(.firstTimeAsking)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        newsNotificationPermissionHelper.onAskForPermission()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    //MARK: - private helper methods
    fileprivate func addBackgroundImage(_ permissionState: PermissionState) {
        let backgroundImageView = getBackgroundImageView(permissionState)
        self.view.addSubview(backgroundImageView)
        let height = (DeviceInfo.getDeviceType() == .iPhone6Plus) ? 1000 : backgroundImageView.frame.height
        
        backgroundImageView.snp_makeConstraints{ make in
            make.top.equalTo(0)
            make.left.right.equalTo(self.view)
            make.size.height.equalTo(height/2)
        }
    }
    
    fileprivate func getBackgroundImageView(_ permissionState: PermissionState) -> UIImageView {
        
        let deviceSuffix = DeviceInfo.getDeviceType().rawValue
        var backgroundImageName: String

        if permissionState == .howToEnable {
            backgroundImageName = "NewsPermissionSettings-\(deviceSuffix)"
        } else {
            backgroundImageName = "NewsPermissionAsking-\(deviceSuffix)"
        }
        
        let backgroundImage = UIImage(named: backgroundImageName)
        
        return UIImageView(image: backgroundImage)
    }

    fileprivate func createButton(_ title: String, titleColor: UIColor, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton()
        button.backgroundColor = backgroundColor
        button.setTitleColor(titleColor, for: UIControlState())
        button.setTitle(title, for: UIControlState())
        button.titleLabel?.font = UIFont(name: "Lato-Medium", size: 14.0)
        button.addTarget(self, action: action, for: UIControlEvents.touchUpInside)
        button.layer.cornerRadius = 5
        return button
    }
    
    fileprivate func addActionButtons(_ permissionState: PermissionState) {
        var offsetFactor = 1.0
        if DeviceInfo.getDeviceType() == .iPhone4 {
            offsetFactor = 2.0
        } else if DeviceInfo.getDeviceType() == .iPhone6  || DeviceInfo.getDeviceType() == .iPhone6Plus{
            offsetFactor = 0.75
        }
        
        switch permissionState {
        case .firstTimeAsking:
            self.view.addSubview(yesButton)
            self.view.addSubview(laterButton)
            
            yesButton.snp_makeConstraints{ make in
                make.centerX.equalTo(self.view)
                make.width.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonWidth)
                make.height.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonHeight)
                make.bottom.equalTo(self.view).offset(-30/offsetFactor)
            }
            laterButton.snp_makeConstraints{ make in
                make.centerX.equalTo(self.view)
                make.width.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonWidth)
                make.height.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonHeight)
                make.bottom.equalTo(yesButton.snp_top).offset(-20/offsetFactor)
            }
            
        case .subsequentAsking:
            self.view.addSubview(yesButton)
            self.view.addSubview(laterButton)
            self.view.addSubview(noButton)
            
            yesButton.snp_makeConstraints{ make in
                make.centerX.equalTo(self.view)
                make.width.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonWidth)
                make.height.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonHeight)
                make.bottom.equalTo(self.view).offset(-20/offsetFactor)
            }
            laterButton.snp_makeConstraints{ make in
                make.centerX.equalTo(self.view)
                make.width.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonWidth)
                make.height.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonHeight)
                make.bottom.equalTo(yesButton.snp_top).offset(-15/offsetFactor)
            }
            noButton.snp_makeConstraints{ make in
                make.centerX.equalTo(self.view)
                make.width.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonWidth)
                make.height.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonHeight)
                make.bottom.equalTo(laterButton.snp_top).offset(-15/offsetFactor)
            }
            
        case .howToEnable:
            self.view.addSubview(okButton)
            okButton.snp_makeConstraints{ make in
                make.centerX.equalTo(self.view)
                make.width.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonWidth)
                make.height.equalTo(NewsNotificationPermissionViewControllerUX.ActionButtonHeight)
                make.bottom.equalTo(self.view).offset(-20)
            }
        }
    }
    
    
    func SELdidClickYes() {
        newsNotificationPermissionHelper.enableNewsNotifications()
        self.dismiss(animated: true, completion: nil)
    }
    
    func SELdidClickLater() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func SELdidClickNo() {
        newsNotificationPermissionHelper.disableAskingForPermission()
        let viewController = NewsNotificationPermissionViewController()
        self.navigationController?.pushViewController(viewController, animated: false)
    }
    
    func SELdidClickOk() {
        self.dismiss(animated: true, completion: nil)
    }

}
