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

enum UserActionType {
    case searchTextChanged
    case searchTextCleared
    case urlPressed
}

enum UserActionContext {
    case urlBarVC
    case historyNavVC
}

struct UserAction {
    let data: [String: Any]?
    let type: UserActionType
    let context: UserActionContext
}

protocol UserActionDelegate: class {
    func userAction(action: UserAction)
}

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

extension Router: UserActionDelegate {
    func userAction(action: UserAction) {
        switch action.type {
        case .searchTextChanged:
            if let data = action.data as? [String: String], let text = data["text"] {
                ContentNavVC?.textInUrlBarChanged(text: text)
            }
        case .searchTextCleared:
             ContentNavVC?.textInUrlBarChanged(text: "")
        case .urlPressed:
            if let data = action.data as? [String: String], let url = data["url"] {
                ContentNavVC?.historyDetailWasPressed(url: url)
            }
            
        }
    }
}

