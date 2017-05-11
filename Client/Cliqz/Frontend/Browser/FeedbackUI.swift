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
    case info
    case error
    case done
}
class FeedbackUI: NSObject {
    static var defaultOptions : [AnyHashable: Any] = [
        kCRToastTextAlignmentKey : NSTextAlignment.left.rawValue,
        kCRToastNotificationTypeKey: CRToastType.navigationBar.rawValue,
        kCRToastNotificationPresentationTypeKey: CRToastPresentationType.cover.rawValue,
        kCRToastAnimationInTypeKey : CRToastAnimationType.linear.rawValue,
        kCRToastAnimationOutTypeKey : CRToastAnimationType.linear.rawValue,
        kCRToastAnimationInDirectionKey : CRToastAnimationDirection.top.rawValue,
        kCRToastAnimationOutDirectionKey : CRToastAnimationDirection.top.rawValue,
        kCRToastImageAlignmentKey: CRToastAccessoryViewAlignment.left.rawValue
        
    ]
    
    //MARK:- Toast
    class func showToastMessage(_ message: String, messageType: ToastMessageType) {
        var options : [AnyHashable: Any] = [kCRToastTextKey: message]
        
        switch messageType {
        case .info:
            options[kCRToastBackgroundColorKey] = UIColor(colorString: "E8E8E8")
            options[kCRToastImageKey] = UIImage(named:"toastInfo")!
            options[kCRToastTextColorKey] = UIColor.black
            
        case .error:
            options[kCRToastBackgroundColorKey] = UIColor(colorString: "E64C66")
            options[kCRToastImageKey] = UIImage(named:"toastError")!
        
        case .done:
            options[kCRToastBackgroundColorKey] = UIColor(colorString: "2CBA84")
            options[kCRToastImageKey] = UIImage(named:"toastCheckmark")!
            
        }
        
        
        // copy default options to the current options dictionary
        defaultOptions.forEach { options[$0] = $1 }
        
        DispatchQueue.main.async {
            CRToastManager.showNotification(options: options, completionBlock: nil)
        }
    }
    
    //MARK:- HUD
    class func showLoadingHUD(_ message: String) {
        DispatchQueue.main.async {
            SVProgressHUD.show(withStatus: message)
        }
    }

    class func dismissHUD() {
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
        }
    }
    

}
