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
    case urlSelected
    case searchAutoSuggest
    case searchDismissKeyboard
	case homeButtonPressed
	case urlIsModified
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
    
    fileprivate weak var contentNavVC: ContentNavigationViewController?
    fileprivate weak var mainNavVC: MainContainerViewController?
	fileprivate weak var urlBarVC: URLBarViewController?
	
    static let shared = Router()
    
    func registerController(viewController: UIViewController) {
        
        if let controller = viewController as? ContentNavigationViewController {
            self.contentNavVC = controller
        } else if let controller = viewController as? MainContainerViewController {
			self.mainNavVC = controller
		} else if let controller = viewController as? URLBarViewController {
			self.urlBarVC = controller
        }
    }
}

extension Router: ActionDelegate {
    
    func action(action: Action) {
        switch action.type {
        case .searchTextChanged:
            if let data = action.data as? [String: String], let text = data["text"] {
                self.contentNavVC?.textInUrlBarChanged(text: text)
            }
        case .searchTextCleared:
             self.contentNavVC?.textInUrlBarChanged(text: "")
        case .urlSelected:
            if let data = action.data as? [String: String], let url = data["url"] {
                self.contentNavVC?.browseURL(url: url)
            }
        case .searchAutoSuggest:
            if let data = action.data as? [String: String], let text = data["text"] {
                //Send this to main navigation. Main navigation is responsible for URL Bar.
                self.mainNavVC?.autoSuggestURLBar(autoSuggestText: text)
            }
        case .searchDismissKeyboard:
            self.mainNavVC?.dismissKeyboardForUrlBar()
		case .homeButtonPressed:
            self.contentNavVC?.homePressed()
		case .urlIsModified:
			var url: URL? = nil
			if let data = action.data as? [String: URL], let u = data["url"] {
				url = u
			}
			self.urlBarVC?.updateURL(url)
		}
	}
}
