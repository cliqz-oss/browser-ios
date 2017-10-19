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
    //init
    case initialization
    //search
    case searchAutoSuggest
    case searchStopEditing
    //url
    case urlSelected
    case urlIsModified
    case urlBackPressed
    case urlClearPressed
    case urlSearchPressed
    case urlSearchTextChanged
    case urlProgressChanged
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
    
    //missing
    //case didChangeOrientation
    case detailBackPressed
    case domainPressed
    //case tabsDismissed
    //history
    //case visitAddedInDB
    case newVisit
    case webNavigationUpdate
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

struct Action: Equatable {
    let data: [String: Any]?
    let type: ActionType
	
    init(data: [String: Any]? = nil, type: ActionType) {
        self.data = data
        self.type = type
    }
    
    static func == (lhs: Action, rhs: Action) -> Bool {
        return lhs.type == rhs.type
    }
    
    static func != (lhs: Action, rhs: Action) -> Bool {
        return lhs.type != rhs.type
    }
    
    func addData(newData: [String: Any]) -> Action {
        if var current_data = self.data {
            for key in newData.keys {
                //if keys are the same just replace.
                current_data[key] = newData[key]
            }
            
            return Action(data: current_data, type: self.type)
            
        }
        
        return Action(data: data, type: self.type)
    }
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
        case .tabsPressed:
            mainNavVC?.showTabOverView()
        case .sharePressed:
            ShareHelper.presentActivityViewController()
        case .remindersPressed:
            contentNavVC?.showReminder()
        default:
            debugPrint()
        }
	}
}
