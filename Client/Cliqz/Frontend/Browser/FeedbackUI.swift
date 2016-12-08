//
//  FeedbackUI.swift
//  Client
//
//  Created by Mahmoud Adam on 11/10/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import CRToast
import SVProgressHUD

public enum ToastMessageType {
    case Info
    case Error
    case Done
}
class FeedbackUI: NSObject {
    static var defaultOptions : [NSObject : AnyObject] = [
        kCRToastTextAlignmentKey : NSTextAlignment.Left.rawValue,
        kCRToastNotificationTypeKey: CRToastType.NavigationBar.rawValue,
        kCRToastNotificationPresentationTypeKey: CRToastPresentationType.Cover.rawValue,
        kCRToastAnimationInTypeKey : CRToastAnimationType.Linear.rawValue,
        kCRToastAnimationOutTypeKey : CRToastAnimationType.Linear.rawValue,
        kCRToastAnimationInDirectionKey : CRToastAnimationDirection.Top.rawValue,
        kCRToastAnimationOutDirectionKey : CRToastAnimationDirection.Top.rawValue,
        kCRToastImageAlignmentKey: CRToastAccessoryViewAlignment.Left.rawValue
        
    ]
    
    //MARK:- Toast
    class func showToastMessage(message: String, messageType: ToastMessageType) {
        var options : [NSObject : AnyObject] = [kCRToastTextKey: message]
        
        switch messageType {
        case .Info:
            options[kCRToastBackgroundColorKey] = UIColor(colorString: "E8E8E8")
            options[kCRToastImageKey] = UIImage(named:"toastInfo")!
            options[kCRToastTextColorKey] = UIColor.blackColor()
            
        case .Error:
            options[kCRToastBackgroundColorKey] = UIColor(colorString: "E64C66")
            options[kCRToastImageKey] = UIImage(named:"toastError")!
        
        case .Done:
            options[kCRToastBackgroundColorKey] = UIColor(colorString: "2CBA84")
            options[kCRToastImageKey] = UIImage(named:"toastCheckmark")!
            
        }
        
        
        // copy default options to the current options dictionary
        defaultOptions.forEach { options[$0] = $1 }
        
        //[Cliqz][Grage13] disable showing toast message
//        dispatch_async(dispatch_get_main_queue()) {
//            CRToastManager.showNotificationWithOptions(options, completionBlock: nil)
//        }
    }
    
    //MARK:- HUD
    class func showLoadingHUD(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            SVProgressHUD.showWithStatus(message)
        }
    }

    class func dismissHUD() {
        dispatch_async(dispatch_get_main_queue()) {
            SVProgressHUD.dismiss()
        }
    }
    

}
