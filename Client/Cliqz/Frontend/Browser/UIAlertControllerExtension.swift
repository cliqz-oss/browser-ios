//
//  UIAlertControllerExtension.swift
//  Client
//
//  Created by Mahmoud Adam on 9/1/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

extension UIAlertController {
    @available(iOS 9.0, *)
    class func createNewTabActionSheetController(newTabHandler: ((UIAlertAction) -> Void), newForgetModeTabHandler: ((UIAlertAction) -> Void)) -> UIAlertController {
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        // new normal Tab option
        let newTabTitle = NSLocalizedString("New Tab", tableName: "Cliqz", comment: "Action sheet item for opening a new tab")
        let openNewTabAction =  UIAlertAction(title: newTabTitle, style: UIAlertActionStyle.Default, handler: newTabHandler)
        actionSheetController.addAction(openNewTabAction)
        
        // new forget tab option
        let newForgetTabTitle = NSLocalizedString("New Private Tab", tableName: "Cliqz", comment: "Action sheet item for opening a new forget tab")
        let openNewForgetTabAction =  UIAlertAction(title: newForgetTabTitle, style: UIAlertActionStyle.Default, handler: newForgetModeTabHandler)
        actionSheetController.addAction(openNewForgetTabAction)
        
        // cancel option
        let cancelAction = UIAlertAction(title: UIConstants.CancelString, style: UIAlertActionStyle.Cancel, handler: nil)
        actionSheetController.addAction(cancelAction)
        
        return actionSheetController
    }
}
