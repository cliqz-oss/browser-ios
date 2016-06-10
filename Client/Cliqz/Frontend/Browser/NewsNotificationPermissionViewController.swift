//
//  NewsNotificationPermissionViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 5/30/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit


private enum DeviceType: String {
    case iPhone4        = "4"
    case iPhone5        = "5"
    case iPhone6        = "6"
    case iPhone6Plus    = "6Plus"
}

private enum PermissionState {
    case FirstTimeAsking
    case SubsequentAsking
    case HowToEnable
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

    private lazy var newsNotificationPermissionHelper = NewsNotificationPermissionHelper.sharedInstance
    
    private lazy var yesButton: UIButton = {
        let title = NSLocalizedString("Yes please!", tableName: "Cliqz", comment: "Button label to `Yes please` in news notification permission screen")
        let button = self.createButton(title, titleColor: UIColor.whiteColor(), backgroundColor: NewsNotificationPermissionViewControllerUX.blueColor, action: "SELdidClickYes")
        return button
    }()
    
    private lazy var laterButton: UIButton = {
        let title = NSLocalizedString("Remind me later", tableName: "Cliqz", comment: "Button label to `Remind me later` in news notification permission screen")
        let button = self.createButton(title, titleColor: NewsNotificationPermissionViewControllerUX.blueColor, backgroundColor: UIColor.whiteColor(), action: "SELdidClickLater")
        button.layer.borderColor = NewsNotificationPermissionViewControllerUX.blueColor.CGColor
        button.layer.borderWidth = 1
        return button
    }()
    
    private lazy var noButton: UIButton = {
        let title = NSLocalizedString("No thanks", tableName: "Cliqz", comment: "Button label to `No thanks` in news notification permission screen")
        let button = self.createButton(title, titleColor: NewsNotificationPermissionViewControllerUX.blueColor, backgroundColor: UIColor.whiteColor(), action: "SELdidClickNo")
        button.layer.borderColor = NewsNotificationPermissionViewControllerUX.blueColor.CGColor
        button.layer.borderWidth = 1
        return button
    }()
    
    private lazy var okButton: UIButton = {
        let title = NSLocalizedString("OK", tableName: "Cliqz", comment: "Button label to `OK` in news notification permission screen")
        let button = self.createButton(title, titleColor: UIColor.whiteColor(), backgroundColor: NewsNotificationPermissionViewControllerUX.greenColor, action: "SELdidClickOk")
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationController?.navigationBarHidden = true
        self.view.backgroundColor = UIColor.whiteColor()
        
        if newsNotificationPermissionHelper.isAskingForPermissionDisabled() {
            addBackgroundImage(.HowToEnable)
            addActionButtons(.HowToEnable)
        } else if newsNotificationPermissionHelper.isAksedForPermissionBefore() {
            addBackgroundImage(.SubsequentAsking)
            addActionButtons(.SubsequentAsking)
        } else {
            addBackgroundImage(.FirstTimeAsking)
            addActionButtons(.FirstTimeAsking)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
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
    private func addBackgroundImage(permissionState: PermissionState) {
        let backgroundImageView = getBackgroundImageView(permissionState)
        self.view.addSubview(backgroundImageView)
        let height = (getDeviceType() == .iPhone6Plus) ? 1000 : backgroundImageView.frame.height
        
        backgroundImageView.snp_makeConstraints{ make in
            make.top.equalTo(0)
            make.left.right.equalTo(self.view)
            make.size.height.equalTo(height/2)
        }
    }
    
    private func getBackgroundImageView(permissionState: PermissionState) -> UIImageView {
        
        let deviceSuffix = getDeviceType().rawValue
        var backgroundImageName: String

        if permissionState == .HowToEnable {
            backgroundImageName = "NewsPermissionSettings-\(deviceSuffix)"
        } else {
            backgroundImageName = "NewsPermissionAsking-\(deviceSuffix)"
        }
        
        let backgroundImage = UIImage(named: backgroundImageName)
        
        return UIImageView(image: backgroundImage)
    }
    
    private func getDeviceType() -> DeviceType {
        var deviceSuffix: DeviceType
        
        let screenHeight = Int(self.view.frame.size.height)
        if screenHeight == 480 {
            deviceSuffix = .iPhone4
        } else if screenHeight == 568 {
            deviceSuffix = .iPhone5
        } else if screenHeight == 667 {
            deviceSuffix = .iPhone6
        } else if screenHeight == 736 {
            deviceSuffix = .iPhone6Plus
        } else {
            // iPad
            deviceSuffix = .iPhone6
        }
        
        return deviceSuffix
        
    }
    
    private func createButton(title: String, titleColor: UIColor, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton()
        button.backgroundColor = backgroundColor
        button.setTitleColor(titleColor, forState: UIControlState.Normal)
        button.setTitle(title, forState: UIControlState.Normal)
        button.titleLabel?.font = UIFont(name: "Lato-Medium", size: 14.0)
        button.addTarget(self, action: action, forControlEvents: UIControlEvents.TouchUpInside)
        button.layer.cornerRadius = 5
        return button
    }
    
    private func addActionButtons(permissionState: PermissionState) {
        var offsetFactor = 1.0
        if getDeviceType() == .iPhone4 {
            offsetFactor = 2.0
        } else if getDeviceType() == .iPhone6  || getDeviceType() == .iPhone6Plus{
            offsetFactor = 0.75
        }
        
        switch permissionState {
        case .FirstTimeAsking:
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
            
        case .SubsequentAsking:
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
            
        case .HowToEnable:
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
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func SELdidClickLater() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func SELdidClickNo() {
        newsNotificationPermissionHelper.disableAskingForPermission()
        let viewController = NewsNotificationPermissionViewController()
        self.navigationController?.pushViewController(viewController, animated: false)
    }
    
    func SELdidClickOk() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
