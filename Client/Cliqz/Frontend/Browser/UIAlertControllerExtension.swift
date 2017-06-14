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
    class func createNewTabActionSheetController(_ presenter: UIView, newTabHandler: @escaping ((UIAlertAction) -> Void), newForgetModeTabHandler: @escaping ((UIAlertAction) -> Void), cancelHandler: @escaping ((UIAlertAction) -> Void), closeAllTabsHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // new normal Tab option
        let newTabTitle = NSLocalizedString("Open New Tab", tableName: "Cliqz", comment: "Action sheet item for opening a new tab")
        let openNewTabAction =  UIAlertAction(title: newTabTitle, style: UIAlertActionStyle.default, handler: newTabHandler)
        actionSheetController.addAction(openNewTabAction)
        
        // new forget tab option
        let newForgetTabTitle = NSLocalizedString("Open New Forget Tab", tableName: "Cliqz", comment: "Action sheet item for opening a new forget tab")
        let openNewForgetTabAction =  UIAlertAction(title: newForgetTabTitle, style: UIAlertActionStyle.default, handler: newForgetModeTabHandler)
        actionSheetController.addAction(openNewForgetTabAction)
        
        // close all tabs option
        if let closeAllTabsHandler = closeAllTabsHandler {
            let closeAllTabsTitle = NSLocalizedString("Close All Tabs", tableName: "Cliqz", comment: "Action sheet item for closing all opened tabs")
            let closeAllTabsAction =  UIAlertAction(title: closeAllTabsTitle, style: UIAlertActionStyle.destructive, handler: closeAllTabsHandler)
            actionSheetController.addAction(closeAllTabsAction)
        }
        
        
        // cancel option
        let cancelAction = UIAlertAction(title: UIConstants.CancelString, style: UIAlertActionStyle.cancel, handler: cancelHandler)
        actionSheetController.addAction(cancelAction)
        
        if let popPresenter = actionSheetController.popoverPresentationController {
            popPresenter.sourceView = presenter
            popPresenter.sourceRect = presenter.bounds
        }
        
        
        return actionSheetController
    }
}
