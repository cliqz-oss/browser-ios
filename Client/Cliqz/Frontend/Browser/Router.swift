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

enum ActionType {
    case searchTextChanged
    case searchTextCleared
    case urlPressed
    case searchAutoSuggest
    case searchDismissKeyboard
}

enum ActionContext {
    case urlBarVC
    case historyNavVC
    case contentNavVC
}

struct Action {
    let data: [String: Any]?
    let type: ActionType
    let context: ActionContext
}

protocol ActionDelegate: class {
    func action(action: Action)
}

class Router {
    
    //Route actions to Navigations (Always!!!). The navigations are responsible for state, so they decide what to do with the input for subcomponents.
    
    fileprivate weak var ContentNavVC: ContentNavigationViewController?
    fileprivate weak var MainNavVC: MainContainerViewController?
    
    static let sharedInstance = Router()
    
    func registerController(viewController: UIViewController) {
        
        if let controller = viewController as? ContentNavigationViewController {
            ContentNavVC = controller
        }
        else if let controller = viewController as? MainContainerViewController {
                MainNavVC = controller
        }
    }
}

extension Router: ActionDelegate {
    
    func action(action: Action) {
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
        case .searchAutoSuggest:
            if let data = action.data as? [String: String], let text = data["text"] {
                //Send this to main navigation. Main navigation is responsible for URL Bar.
                MainNavVC?.autoSuggestURLBar(autoSuggestText: text)
            }
        case .searchDismissKeyboard:
            MainNavVC?.dismissKeyboardForUrlBar()
        }
    }
}
