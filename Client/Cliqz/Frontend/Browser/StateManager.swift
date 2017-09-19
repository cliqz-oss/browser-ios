//
//  StateManager.swift
//  Client
//
//  Created by Tim Palade on 9/14/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//define cases for ContentNav
//define cases for URLBar
//define cases for ToolBar

//Definitions:
//Types of states:
//1. Global states
//2. Component states

//Any state can be categorized as:
//1. previousState
//2. currentState
//3. nextState

enum MainState {
    case tabsVisible
    case reminderVisible
    case actionSheetVisible
    case other
    case prevState
}

enum ContentState {
    case browse
    case search
    case domains
    case details
    case dash
    case prevState
}

enum URLBarState {
    case collapsedEmptyTransparent
    case collapsedTextTransparent
    case collapsedTextBlue //displays query
    case collapsedDomainBlue //displays domain
    case expandedEmptyWhite
    case expandedTextWhite
    case prevState
}

enum ToolBarState {
    case invisible
    case visible
    case prevState
}

enum ToolBarBackState {
    case enabled
    case disabled
    case prevState
}

enum ToolBarForwardState {
    case enabled
    case disabled
    case prevState
}

enum ToolBarShareState {
    case enabled
    case disabled
    case prevState
}

//struct ContentStateAndData: Equatable {
//    let state: ContentState
//    let data : [String: Any]?
//    
//    static func == (lhs: ContentStateAndData, rhs: ContentStateAndData) -> Bool {
//        return lhs.state == rhs.state
//    }
//}

//struct URLBarStateAndData {
//    let state: URLBarState
//    let data : [String: Any]?
//    
//    static func == (lhs: URLBarStateAndData, rhs: URLBarStateAndData) -> Bool {
//        return lhs.state == rhs.state
//    }
//}


//Have a place where you create the StateData from the action. Or even better, modify the action such that it will send state data.
struct StateData {
    let query: String?
    let url: String?
    let tab: Tab?
    let indexPath: IndexPath?
    let image: UIImage?
    //maybe indexpath as well or tab?
    
    static func merge(lhs: StateData, rhs: StateData) -> StateData {
        //lhs takes precedence
        
        let query = lhs.query != nil ? lhs.query : rhs.query
        let url   = lhs.url != nil ? lhs.url : rhs.url
        let tab   = lhs.tab != nil ? lhs.tab : rhs.tab
        let indexPath = lhs.indexPath != nil ? lhs.indexPath : rhs.indexPath
        let image = lhs.image != nil ? lhs.image : rhs.image
        
        return StateData(query: query, url: url, tab: tab, indexPath: indexPath, image: image)
    }
    
}

struct State: Equatable {
    let mainState: MainState
    let contentState: ContentState
    let urlBarState: URLBarState
    let toolBarState: ToolBarState
    let toolBackState: ToolBarBackState
    let toolForwardState: ToolBarForwardState
    let toolShareState: ToolBarShareState
    
    let stateData: StateData
    
    static func == (lhs: State, rhs: State) -> Bool {
        return lhs.mainState == rhs.mainState && lhs.contentState == rhs.contentState && lhs.urlBarState == rhs.urlBarState && lhs.toolBarState == rhs.toolBarState && lhs.toolBackState == rhs.toolBackState && lhs.toolForwardState == rhs.toolForwardState && lhs.toolShareState == rhs.toolShareState
    }
}

final class StateManager {
    
    static let shared = StateManager()
    
    weak var mainCont: MainContainerViewController?
    weak var urlBar: URLBarViewController?
    weak var contentNav: ContentNavigationViewController?
    weak var toolBar: ToolbarViewController?

    
    //initial state
    var currentState: State = State(mainState: .other, contentState: .domains, urlBarState: .collapsedEmptyTransparent, toolBarState: .visible, toolBackState: .disabled, toolForwardState: .disabled, toolShareState: .disabled, stateData: StateData(query: nil, url: nil, tab: nil, indexPath: nil, image: nil))
    var previousState: State = State(mainState: .other, contentState: .domains, urlBarState: .collapsedEmptyTransparent, toolBarState: .visible, toolBackState: .disabled, toolForwardState: .disabled, toolShareState: .disabled, stateData: StateData(query: nil, url: nil, tab: nil, indexPath: nil, image: nil))
    
    //Rules for stateMetaData
    //Keys: 
    //1. url
    //2. tab
    //3. query
    //action data modifies the last entry.
    //var stateMetaData : [String : Any] = [:] //here I can have the query strings
    
    func preprocessActionData(data: [String: Any]?) -> StateData {
        
        guard let data = data else {
            return StateData(query: nil, url: nil, tab: nil, indexPath: nil, image: nil)
        }
        
        let text = data["text"] as? String
        let tab  = data["tab"] as? Tab
        let indexPath = data["indexPath"] as? IndexPath
        let image = data["image"] as? UIImage
        var url  = data["url"] as? String
        
        if let t = tab {
            url = t.url?.absoluteString
        }
        
        if let u = url, let appDelegate = UIApplication.shared.delegate as? AppDelegate, let profile = appDelegate.profile {
            var validURL = URIFixup.getURL(u)
            if validURL == nil {
                validURL = profile.searchEngines.defaultEngine.searchURLForQuery(u)
            }
            url = validURL?.absoluteString
        }
        
        
        return StateData(query: text, url: url, tab: tab, indexPath: indexPath, image: image)
    }
    
    func handleAction(action: Action) {
        
        let nextState = ActionStateTransformer.transform(previousState: previousState, currentState: currentState, actionType: action.type, nextStateData: preprocessActionData(data: action.data))
        //there will be some more state changes added here, to take care of back and forward. 
        changeToState(nextState: nextState)
    }
    
    func changeToState(nextState: State) {
        mainContChangeToState(currentState: currentState.mainState, nextState: nextState.mainState)
        contentNavChangeToState(currentState: currentState.contentState, nextState: nextState.contentState, nextStateData: nextState.stateData)
        urlBarChangeToState(currentState: currentState.urlBarState, nextState: nextState.urlBarState, nextStateData: nextState.stateData)
        //TO DO: Call the toolbar change to state
        //---
        
        //there is not point in changing the previous state if the currentstate does not change. 
        
        //Attention: note that currentState == nextState even if the data of the nextState is different from the data of currentState
        debugPrint("------------------------------------")
        debugPrint("PREV STATE")
        debugPrint(previousState.urlBarState)
        debugPrint(previousState.stateData)
        debugPrint("CURRENT STATE")
        debugPrint(currentState.urlBarState)
        debugPrint(currentState.stateData)
        debugPrint("NEXT STATE")
        debugPrint(nextState.urlBarState)
        debugPrint(nextState.stateData)
        
        
        if currentState != nextState {
            if !((currentState.urlBarState == .expandedEmptyWhite || currentState.urlBarState == .expandedTextWhite) && (nextState.urlBarState == .expandedEmptyWhite || nextState.urlBarState == .expandedTextWhite)) {
                previousState = currentState
            }
            
        }
        
        //if currentState == nextState, then the data of the currentState is updated.
        //else the nextState replaces the currentState
        currentState = nextState
    }
    
    func mainContChangeToState(currentState: MainState, nextState: MainState) {
        
        guard currentState != nextState else {
            return
        }
        
        switch nextState {
        case .tabsVisible:
            debugPrint()
        case .reminderVisible:
            debugPrint()
        case .actionSheetVisible:
            debugPrint()
        case .other:
            debugPrint()
        case .prevState:
            raisePrevStateException()
        }
    }
    
    func contentNavChangeToState(currentState: ContentState, nextState: ContentState, nextStateData: StateData) {
    
        switch nextState {
        case .browse:
            contentNav?.browse(url: nextStateData.url, tab: nextStateData.tab)
        case .search:
            contentNav?.search(query: nextStateData.query)
        case .domains:
            contentNav?.domains(currentState: currentState)
        case .details:
            contentNav?.details(indexPath: nextStateData.indexPath, image: nextStateData.image)
        case .dash:
            contentNav?.dash()
        case .prevState:
            raisePrevStateException()
        }
    }
    
    func urlBarChangeToState(currentState: URLBarState, nextState: URLBarState, nextStateData: StateData) {
        
        switch nextState {
        case .collapsedEmptyTransparent:
            urlBar?.collapsedEmptyTransparent()
        case .collapsedTextTransparent:
            urlBar?.collapsedTextTransparent(text: nextStateData.query)
        case .collapsedTextBlue:
            urlBar?.collapsedQueryBlue(text: nextStateData.query)
        case .collapsedDomainBlue:
            urlBar?.collapsedDomainBlue(urlStr: nextStateData.url)
        case .expandedEmptyWhite:
            urlBar?.expandedEmptyWhite()
        case .expandedTextWhite:
            urlBar?.expandedTextWhite(text: nextStateData.query)
        case .prevState:
           raisePrevStateException()
        }
    }
    
    func toolBarChangeToState(currentState: ToolBarState, nextState: ToolBarState, data: [String: Any]?) {
        
        guard currentState != nextState else {
            return
        }
        
        switch nextState {
        case .invisible:
            debugPrint()
        case .visible:
            debugPrint()
        case .prevState:
            raisePrevStateException()
        }
    }
    
    func toolBackChangeToState(currentState: ToolBarBackState, nextState: ToolBarBackState, data: [String: Any]?) {
        
        guard currentState != nextState else {
            return
        }
        
        switch nextState {
        case .enabled:
            debugPrint()
        case .disabled:
            debugPrint()
        case .prevState:
            raisePrevStateException()
        }
    }
    
    func toolForwardChageToState(currentState: ToolBarForwardState, nextState: ToolBarForwardState, data: [String: Any]?) {
        
        guard currentState != nextState else {
            return
        }
        
        switch nextState {
        case .enabled:
            debugPrint()
        case .disabled:
            debugPrint()
        case .prevState:
            raisePrevStateException()
        }
    }
    
    func toolShareChangeToState(currentState: ToolBarShareState, nextState: ToolBarShareState, data: [String: Any]?) {
        
        guard currentState != nextState else {
            return
        }
        
        switch nextState {
        case .enabled:
            debugPrint()
        case .disabled:
            debugPrint()
        case .prevState:
            raisePrevStateException()
        }
    }
    
    private func raisePrevStateException() {
         NSException(name: NSExceptionName(rawValue: "Bad State Management"), reason: "prevState should never occur. It should always be handled before this.", userInfo: nil).raise()
    }

}
