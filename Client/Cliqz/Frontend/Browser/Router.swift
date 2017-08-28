//
//  Router.swift
//  Client
//
//  Created by Tim Palade on 8/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//Router: The purpose of the class is to eliminate the need to have too many delegates. 
//If position in the hierarchy between two classes is more than or equal to two levels, then use the Router for communication. 

import UIKit

class Router {
    
    enum Controller {
        case contentNavigation
    }
    
    fileprivate weak var ContentNavVC: ContentNavigationViewController?
    
    static let sharedInstance = Router()
    
    func registerController(viewController: UIViewController, as type: Controller) {
        
        if type == .contentNavigation {
            if let controller = viewController as? ContentNavigationViewController {
                ContentNavVC = controller
            }
        }
        
    }
}


//History Details
extension Router: ExternalHistoryHandler {
    
    func historyDetailCellPressed(url: String?) {
        ContentNavVC?.historyDetailWasPressed(url: url)
    }
}

//Url Bar
extension Router: ExternalURLBarHandler {
    
    func textChangedInUrlBar(text: String) {
        ContentNavVC?.textInUrlBarChanged(text: text)
    }
    
    func textClearedInUrlBar() {
        ContentNavVC?.textIUrlBarCleared()
    }
    
    func backPressedUrlBar() {
        ContentNavVC?.backPressedUrlBar()
    }
}
