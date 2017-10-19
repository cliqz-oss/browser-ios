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
}

enum ContentState {
    case browse
    case search
    case domains
    case details
    case dash
}

enum URLBarState {
    case collapsedEmptyTransparent
    case collapsedTextTransparent
    case collapsedTextBlue //displays query
    case collapsedDomainBlue //displays domain
    case expandedEmptyWhite
    case expandedTextWhite
}

enum ToolBarState {
    case invisible
    case visible
}

enum ToolBarBackState {
    case enabled
    case disabled
}

enum ToolBarForwardState {
    case enabled
    case disabled
}

enum ToolBarShareState {
    case enabled
    case disabled
}

//Have a place where you create the StateData from the action. Or even better, modify the action such that it will send state data.
struct StateData: Equatable {
    let query: String? 
    let url: String?
    let tab: Tab?
    let detailsHost: String?
    let loadingProgress: Float?
    //maybe indexpath as well or tab?
    
    static func merge(lhs: StateData, rhs: StateData) -> StateData {
        //lhs takes precedence
        
        let query = lhs.query != nil ? lhs.query : rhs.query
        let url   = lhs.url != nil ? lhs.url : rhs.url
        let tab   = lhs.tab != nil ? lhs.tab : rhs.tab
        let detailsHost = lhs.detailsHost != nil ? lhs.detailsHost : rhs.detailsHost
        let loadingProgress = lhs.loadingProgress != nil ? lhs.loadingProgress : rhs.loadingProgress
        
        return StateData(query: query, url: url, tab: tab, detailsHost: detailsHost, loadingProgress: loadingProgress)
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
    let toolBackState: ToolBarBackState
    let toolForwardState: ToolBarForwardState
    let toolShareState: ToolBarShareState
    
    let stateData: StateData
    
    static func == (lhs: State, rhs: State) -> Bool {
        return lhs.mainState == rhs.mainState && lhs.contentState == rhs.contentState && lhs.urlBarState == rhs.urlBarState && lhs.toolBarState == rhs.toolBarState //&& lhs.toolBackState == rhs.toolBackState && lhs.toolForwardState == rhs.toolForwardState && lhs.toolShareState == rhs.toolShareState
    }
    
    static func equalWithTheSameData (lhs: State, rhs: State) -> Bool {
        return lhs == rhs && lhs.stateData == rhs.stateData
    }
}

extension State {
    func sameStateWithNewData(newStateData: StateData) -> State {
        return sameStateWith(info: ["stateData": newStateData])
    }
    
    func sameStateWithNewBackForwardState(newBackState: ToolBarBackState, newForwardState: ToolBarForwardState) -> State {
        return sameStateWith(info: ["toolBackState": newBackState, "toolForwardState": newForwardState])
    }
    
    func sameStateWith(info: [String: Any]) -> State {
        let new_mainState: MainState? = info["mainState"] as? MainState
        let new_contentState: ContentState? = info["contentState"] as? ContentState
        let new_urlBarState: URLBarState? = info["urlBarState"] as? URLBarState
        let new_toolBarState: ToolBarState? = info["toolBarState"] as? ToolBarState
        let new_toolBackState: ToolBarBackState? = info["toolBackState"] as? ToolBarBackState
        let new_toolForwardState: ToolBarForwardState? = info["toolForwardState"] as? ToolBarForwardState
        let new_toolShareState: ToolBarShareState? = info["toolShareState"] as? ToolBarShareState
        let new_stateData: StateData? = info["stateData"] as? StateData
        
        let mainState: MainState = new_mainState != nil ? new_mainState! : self.mainState
        let contentState: ContentState = new_contentState != nil ? new_contentState! : self.contentState
        let urlBarState: URLBarState = new_urlBarState != nil ? new_urlBarState! : self.urlBarState
        let toolBarState: ToolBarState = new_toolBarState != nil ? new_toolBarState! : self.toolBarState
        let toolBackState: ToolBarBackState = new_toolBackState != nil ? new_toolBackState! : self.toolBackState
        let toolForwardState: ToolBarForwardState = new_toolForwardState != nil ? new_toolForwardState! : self.toolForwardState
        let toolShareState: ToolBarShareState = new_toolShareState != nil ? new_toolShareState! : self.toolShareState
        let stateData: StateData = new_stateData != nil ? new_stateData! : self.stateData
        
        return State(mainState: mainState, contentState: contentState, urlBarState: urlBarState, toolBarState: toolBarState, toolBackState: toolBackState, toolForwardState: toolForwardState, toolShareState: toolShareState, stateData: stateData)
        
    }
}

final class StateManager {
    
    static let shared = StateManager()
    
    weak var mainCont: MainContainerViewController?
    weak var urlBar: URLBarViewController?
    weak var contentNav: ContentNavigationViewController?
    weak var toolBar: ToolbarViewController?

    
    //initial state
    var currentState: State = State(mainState: .other, contentState: .domains, urlBarState: .collapsedEmptyTransparent, toolBarState: .visible, toolBackState: .disabled, toolForwardState: .disabled, toolShareState: .disabled, stateData: StateData(query: nil, url: nil, tab: nil, detailsHost: nil, loadingProgress: nil))
    var previousState: State = State(mainState: .other, contentState: .domains, urlBarState: .collapsedEmptyTransparent, toolBarState: .visible, toolBackState: .disabled, toolForwardState: .disabled, toolShareState: .disabled, stateData: StateData(query: nil, url: nil, tab: nil, detailsHost: nil, loadingProgress: nil))
    
    var lastBackForwAction: Action = Action(type: .initialization)
    
    
    func preprocessAction(action: Action) -> StateData {
        
        guard let data = action.data else {
            return StateData(query: nil, url: nil, tab: nil, detailsHost: nil, loadingProgress: nil)
        }
        
        let text = data["text"] as? String
        let tab  = data["tab"] as? Tab
        let detailsHost = data["detailsHost"] as? String
        var url  = data["url"] as? String
        let loadingProgress = data["progress"] as? Float
        
        if let u = url, let appDelegate = UIApplication.shared.delegate as? AppDelegate, let profile = appDelegate.profile {
            var validURL = URIFixup.getURL(u)
            if validURL == nil {
                validURL = profile.searchEngines.defaultEngine.searchURLForQuery(u)
            }
            url = validURL?.absoluteString
        }
    
        return StateData(query: text, url: url, tab: tab, detailsHost: detailsHost, loadingProgress: loadingProgress)
    }
    
    
    func handleAction(action: Action) {
        
        var preprocessedData = preprocessAction(action: action)
         //.urlIsModified is called even when the url is the same. Ignore. I should fix this.
        if (preprocessedData.url == currentState.stateData.url /*||  specialCond*/) && action.type == .urlIsModified {
            return
        }
        
        //should only change the progress bar in this state
        if action.type == .urlProgressChanged && currentState.urlBarState != .collapsedDomainBlue {
            return
        }
        
        //the logic for adding a tab is handled here
        if let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager {
            if action.type == .urlSelected && (tabManager.selectedTab?.webView?.url != nil || tabManager.tabs.count == 0) {
                
                var currentState_currentTab: State? = nil
                
                if let currentTab = tabManager.selectedTab {
                    currentState_currentTab = BackForwardNavigation.shared.currentState(tab: currentTab)
                }
                
                let tab = tabManager.addTabAndSelect()
                let newStateData = StateData(query: nil, url: nil, tab: tab, detailsHost: nil, loadingProgress: nil)
                preprocessedData = StateData.merge(lhs: newStateData , rhs: preprocessedData)
                if var state = currentState_currentTab {
                    let stateData = state.stateData
                    var newStateData = StateData(query: nil, url: nil, tab: tab, detailsHost: nil, loadingProgress: nil)
                    newStateData = StateData.merge(lhs: newStateData, rhs: stateData)
                    state = state.sameStateWithNewData(newStateData: newStateData)
                    state = state.sameStateWithNewBackForwardState(newBackState: .disabled, newForwardState: .enabled)
                    BackForwardNavigation.shared.addState(tab: tab, state: state)
                }
            }
        }
        

        let nextState = ActionStateTransformer.nextState(previousState: previousState, currentState: currentState, actionType: action.type, nextStateData: preprocessedData)
        //there will be some more state changes added here, to take care of back and forward.
        
        //a tab should always be selected.
        if let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager {
            //tab Manager has to become a singleton. There cannot be 2 tab managers.
            if action.type == .tabSelected, let tab = nextState.stateData.tab {
                tabManager.selectTab(tab)
            }
        }
        
        changeToState(nextState: nextState, action: action)
        
        if action.type == .backButtonPressed || action.type == .forwardButtonPressed {
            lastBackForwAction = action
        }
    }
    
    func changeToState(nextState: State, action: Action) {
        mainContChangeToState(currentState: currentState.mainState, nextState: nextState.mainState)
        contentNavChangeToState(currentState: currentState.contentState, nextState: nextState.contentState, nextStateData: nextState.stateData, action: action)
        urlBarChangeToState(currentState: currentState.urlBarState, nextState: nextState.urlBarState, nextStateData: nextState.stateData)
        toolBarChangeToState(currentState: currentState.toolBarState, nextState: nextState.toolBarState)
        toolBackChangeToState(currentState: currentState.toolBackState, nextState: nextState.toolBackState, tab: nextState.stateData.tab)
        toolForwardChageToState(currentState: currentState.toolForwardState, nextState: nextState.toolForwardState, tab: nextState.stateData.tab)
        toolShareChangeToState(currentState: currentState.toolShareState, nextState: nextState.toolShareState)
        //there is not point in changing the previous state if the currentstate does not change.
        
        if currentState.contentState != nextState.contentState {
            previousState = currentState
        }
        
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
        }
    }
    
    private var webViewDidGoBack: Bool = false
    private var webViewDidGoForw: Bool = false
    
    func contentNavChangeToState(currentState: ContentState, nextState: ContentState, nextStateData: StateData, action: Action) {
        
        let special_cond_1 = lastBackForwAction.type == .backButtonPressed && action.type == .forwardButtonPressed && webViewDidGoBack == true && previousState.contentState == .browse
        let special_cont_2 = lastBackForwAction.type == .forwardButtonPressed && action.type == .backButtonPressed && webViewDidGoForw == true && previousState.contentState == .browse
        
        if (currentState == .browse || special_cond_1 || special_cont_2) && (action.type == .backButtonPressed || action.type == .forwardButtonPressed) && action.type != .urlIsModified && action.type != .urlProgressChanged && action.type != .webNavigationUpdate {
            if let tab = nextStateData.tab {
                if action.type == .backButtonPressed {
                    if BackForwardNavigation.shared.canWebViewGoBack(tab: tab) == true {
                        contentNav?.prevPage()
                        webViewDidGoBack = true
                    }
                    else {
                        webViewDidGoBack = false
                    }
                }
                else if action.type == .forwardButtonPressed {
                    if BackForwardNavigation.shared.canWebViewGoForward(tab: tab) == true {
                        contentNav?.nextPage()
                        webViewDidGoForw = true
                    }
                    else {
                        webViewDidGoForw = false
                    }
                }
            }
        }
    
        switch nextState {
        case .browse:
            //if url is modified in browsing mode then the webview is already navigating there. no need to tell it to navigate there again. 
            //these make sure there are no infinite cycles.
            
            guard action.type != .urlIsModified && action.type != .urlProgressChanged && action.type != .webNavigationUpdate else {
                return
            }
            
            if action.type == .backButtonPressed {
                contentNav?.browseBack()
            }
            else if action.type == .forwardButtonPressed {
                contentNav?.browseForward()
            }
            else if action.type != .newVisit && action.type != .webNavigationUpdate /*&& action.type != .visitAddedInDB*/ && action.type != .backButtonPressed && action.type != .forwardButtonPressed  {
                if action.type == .tabSelected {
                    contentNav?.browse(url: nil, tab: nextStateData.tab)
                }
                else {
                    contentNav?.browse(url: nextStateData.url, tab: nil)
                }
            }
            else {
                contentNav?.browse(url: nil, tab: nil)
            }
        case .search:
            contentNav?.search(query: nextStateData.query)
        case .domains:
            contentNav?.domains(currentState: currentState)
        case .details:
            let animated: Bool = currentState == .domains
            contentNav?.details(host: nextStateData.detailsHost, animated: animated)
        case .dash:
            let animated: Bool = currentState == .domains
            contentNav?.dash(animated: animated)
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
            urlBar?.collapsedDomainBlue(urlStr: nextStateData.url, progress: nextStateData.loadingProgress)
        case .expandedEmptyWhite:
            urlBar?.expandedEmptyWhite()
        case .expandedTextWhite:
            urlBar?.expandedTextWhite(text: nextStateData.query)
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
        }
    }
    
    func toolBackChangeToState(currentState: ToolBarBackState, nextState: ToolBarBackState, tab: Tab?) {
        
        if let tab = tab {
            if BackForwardNavigation.shared.canGoBack(tab: tab) {
                toolBar?.setBackEnabled()
                return
            }
        }
        
        toolBar?.setBackDisabled()
        
    }
    
    func toolForwardChageToState(currentState: ToolBarForwardState, nextState: ToolBarForwardState, tab: Tab?) {
        
        if let tab = tab {
            if BackForwardNavigation.shared.canGoForward(tab: tab) {
                toolBar?.setForwardEnabled()
                return
            }
        }
        
        toolBar?.setForwardDisabled()
        
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
        }
    }
}
