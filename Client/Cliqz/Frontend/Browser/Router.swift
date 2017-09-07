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
    //search
    case searchTextChanged
    case searchTextCleared
    case searchAutoSuggest
    case searchStopEditing
    //url
    case urlSelected
    case urlIsModified
	case urlBarCancelEditing
    //toolbar
	case homeButtonPressed
	case tabsPressed
    case sharePressed
	case backButtonPressed
	case forwardButtonPressed
    //activity
    case remindersPressed
    //tab
    case tabSelected
}

enum ActionContext {
    case mainContainer
    case urlBarVC
    case historyNavVC
    case historyDetails
    case contentNavVC
    case toolBarVC
    case shareHelper
    case dashRemindersDS
    case dashRecommendationsDS
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
                self.mainNavVC?.textInUrlBarChanged(text: text)
            }
        case .searchTextCleared:
             self.contentNavVC?.textInUrlBarChanged(text: "")
        case .searchAutoSuggest:
            if let data = action.data as? [String: String], let text = data["text"] {
                //Send this to main navigation. Main navigation is responsible for URL Bar.
                self.mainNavVC?.autoSuggestURLBar(autoSuggestText: text)
            }
        case .searchStopEditing:
            self.mainNavVC?.stopEditing()

		case .homeButtonPressed:
			self.mainNavVC?.homeButtonPressed()
//            self.contentNavVC?.homePressed()
		case .urlSelected:
			if let data = action.data as? [String: String], let url = data["url"] {
				self.mainNavVC?.urlSelected(url: url)
			}
 //            if let data = action.data as? [String: String], let url = data["url"] {
//                self.contentNavVC?.browseURL(url: url)
//            }
		case .urlIsModified:
			var url: URL? = nil
			if let data = action.data as? [String: URL], let u = data["url"] {
				url = u
			}
            self.mainNavVC?.urlIsModified(url)
		case .urlBarCancelEditing:
			mainNavVC?.urlbCancelEditing()
        case .tabsPressed:
            mainNavVC?.showTabOverView()
        case .sharePressed:
            ShareHelper.presentActivityViewController()
        case .remindersPressed:
            contentNavVC?.showReminder()
        case .backButtonPressed:
            mainNavVC?.backButtonPressed()
        case .forwardButtonPressed:
            mainNavVC?.forwardButtonPressed()
        case .tabSelected:
            if let data = action.data, let tab = data["tab"] as? Tab {
                contentNavVC?.browseTab(tab: tab)
            }
        }
	}
}
