//
//  Router.swift
//  Client
//
//  Created by Tim Palade on 8/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class Router {
    
    enum Controller {
        case contentNavigation
    }
    
    private weak var ContentNavVC: ContentNavigationViewController?
    
    static let sharedInstance = Router()
    
    func registerController(viewController: UIViewController, as type: Controller) {
        
        if type == .contentNavigation {
            if let controller = viewController as? ContentNavigationViewController {
                ContentNavVC = controller
            }
        }
        
    }
    
    func historyDetailCellPressed(url: String?) {
        ContentNavVC?.navigateToBrowser()
    }
    
}
