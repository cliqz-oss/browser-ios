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

//Have a place where you create the StateData from the action. Or even better, modify the action such that it will send state data.
struct StateData: Equatable {
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
    
    static func == (lhs: StateData, rhs: StateData) -> Bool {
        //I don't care about the indexPath and image. They can be different.
        //If I care about them, I can have identical states in the BackForwardNavigation that differ only because of this.
        //Case to see this: browse -> domains -> details -> domains...there will be 2 domains registered with different indexPaths
        return lhs.query == rhs.query && lhs.url == rhs.url && lhs.tab == rhs.tab //&& lhs.indexPath == rhs.indexPath && lhs.image == rhs.image
    }
    
}


//Careful about this. There are 2 equality rules. One when all the states are the same but the state data is different (==). The other when everything is identical including the stateData (equalWithTheSameData).
struct State: Equatable {
    let mainState: MainState
    let contentState: ContentState
    let urlBarState: URLBarState
    let toolBarState: ToolBarState
    var toolBackState: ToolBarBackState
    var toolForwardState: ToolBarForwardState
    let toolShareState: ToolBarShareState
    
    let stateData: StateData
    
    static func == (lhs: State, rhs: State) -> Bool {
        return lhs.mainState == rhs.mainState && lhs.contentState == rhs.contentState && lhs.urlBarState == rhs.urlBarState && lhs.toolBarState == rhs.toolBarState //&& lhs.toolBackState == rhs.toolBackState && lhs.toolForwardState == rhs.toolForwardState && lhs.toolShareState == rhs.toolShareState
    }
    
    static func equalWithTheSameData (lhs: State, rhs: State) -> Bool {
        return lhs == rhs && lhs.stateData == rhs.stateData
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
    
    
    func preprocessActionData(data: [String: Any]?) -> StateData {
        
        guard let data = data else {
            return StateData(query: nil, url: nil, tab: nil, indexPath: nil, image: nil)
        }
        
        let text = data["text"] as? String
        let tab  = data["tab"] as? Tab
        let indexPath = data["indexPath"] as? IndexPath
        let image = data["image"] as? UIImage
        var url  = data["url"] as? String
        
        //careful about this. Think about it. Maybe you want to navigate to a url, that is not already set as the url of the tab...
//        if let t = tab {
//            url = t.url?.absoluteString ?? "localhost"
//        }
        
        if let u = url, let appDelegate = UIApplication.shared.delegate as? AppDelegate, let profile = appDelegate.profile {
            var validURL = URIFixup.getURL(u)
            if validURL == nil {
                validURL = profile.searchEngines.defaultEngine.searchURLForQuery(u)
            }
            url = validURL?.absoluteString
        }
        
        
        return StateData(query: text, url: url, tab: tab, indexPath: indexPath, image: image)
    }
    
    //func areUrlSameExcept
    
    func handleAction(action: Action) {
        
        let preprocessedData = preprocessActionData(data: action.data)
        
        //there is an infinite loop when the url is modified and the only thing that differs are the arguments
        //let nextURL = URL(string: preprocessedData.url ?? "")
        //let currentURL = URL(string: currentState.stateData.url ?? "")
        
        //let specialCond = nextURL?.absoluteURL.host == currentURL?.absoluteURL.host && nextURL?.absoluteURL.relativePath == currentURL?.absoluteURL.relativePath
         //.urlIsModified is called even when the url is the same. Ignore. I should fix this.
        if (preprocessedData.url == currentState.stateData.url /*||  specialCond*/) && action.type == .urlIsModified {
            return
        }
        
        //a tab should always be selected.
        if action.type == .tabSelected, let tab = preprocessedData.tab, let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager {
            //tab Manager has to become a singleton. There cannot be 2 tab managers.
            tabManager.selectTab(tab)
        }
        
        let nextState = ActionStateTransformer.nextState(previousState: previousState, currentState: currentState, actionType: action.type, nextStateData: preprocessedData)
        //there will be some more state changes added here, to take care of back and forward. 

        changeToState(nextState: nextState, action: action)
    }
    
    func changeToState(nextState: State, action: Action) {
        mainContChangeToState(currentState: currentState.mainState, nextState: nextState.mainState)
        contentNavChangeToState(currentState: currentState.contentState, nextState: nextState.contentState, nextStateData: nextState.stateData, action: action)
        urlBarChangeToState(currentState: currentState.urlBarState, nextState: nextState.urlBarState, nextStateData: nextState.stateData)
        //TO DO: Call the toolbar change to state
        //---
        toolBackChangeToState(currentState: currentState.toolBackState, nextState: nextState.toolBackState)
        toolForwardChageToState(currentState: currentState.toolForwardState, nextState: nextState.toolForwardState)
        
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
    
    func contentNavChangeToState(currentState: ContentState, nextState: ContentState, nextStateData: StateData, action: Action) {
    
        switch nextState {
        case .browse:
            //if url is modified in browsing mode then the webview is already navigating there. no need to tell it to navigate there again. 
            if action.type != .urlIsModified && action.type != .visitAddedInDB {
                if action.type == .tabSelected {
                    contentNav?.browse(url: nil, tab: nextStateData.tab)
                }
                else {
                    contentNav?.browse(url: nextStateData.url, tab: nil)
                }
            }
        case .search:
            contentNav?.search(query: nextStateData.query)
        case .domains:
            contentNav?.domains(currentState: currentState)
        case .details:
            let animated: Bool = currentState == .domains
            contentNav?.details(indexPath: nextStateData.indexPath, image: nextStateData.image, animated: animated)
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
    
    func toolBarChangeToState(currentState: ToolBarState, nextState: ToolBarState) {
        
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
    
    func toolBackChangeToState(currentState: ToolBarBackState, nextState: ToolBarBackState) {
        
//        guard currentState != nextState else {
//            return
//        }
        
        switch nextState {
        case .enabled:
            toolBar?.setBackEnabled()
        case .disabled:
            toolBar?.setBackDisabled()
        case .prevState:
            raisePrevStateException()
        }
    }
    
    func toolForwardChageToState(currentState: ToolBarForwardState, nextState: ToolBarForwardState) {
        
//        guard currentState != nextState else {
//            return
//        }
        
        switch nextState {
        case .enabled:
            toolBar?.setForwardEnabled()
        case .disabled:
            toolBar?.setForwardDisabled()
        case .prevState:
            raisePrevStateException()
        }
    }
    
    func toolShareChangeToState(currentState: ToolBarShareState, nextState: ToolBarShareState) {
        
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
