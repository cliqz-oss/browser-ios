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

final class StateManager {
    
    static let shared = StateManager()
    
    weak var mainCont: MainContainerViewController?
    weak var urlBar: URLBarViewController?
    weak var contentNav: ContentNavigationViewController?
    weak var toolBar: ToolbarViewController?
    
    private var webViewDidGoBack: Bool = false
    private var webViewDidGoForw: Bool = false
    
    //initial state
    var currentState: State = State.initial()
    var previousState: State = State.initial()
    
    var lastBackForwAction: Action = Action(type: .initialization)
    
    func handleAction(action: Action) {
        
        var actionStateData = StateData.fromAction(action: action)
        
        guard canHandleAction(action: action, stateData: actionStateData) else {
            return
        }
        
        //Add tab: Rule - whenever a url is selected open a new tab (press on card, press on news, press on reminder, press on history entry)
        if action.type == .urlSelected && (GeneralUtils.tabManager().selectedTab?.webView?.url != nil || GeneralUtils.tabManager().tabs.count == 0) {
            let tab = GeneralUtils.tabManager().addTabAndSelect()
            actionStateData.addTab(tab: tab) //update the tab in the state data
            addStateToNavigation(state: currentState, tab: tab) //add the current state to the navigation of the new tab
            //remove current tab
            if let currentTab = currentState.stateData.tab {
                GeneralUtils.tabManager().removeTab(currentTab)
            }
        }

        let nextState = ActionStateTransformer.nextState(previousState: previousState, currentState: currentState, actionType: action.type, nextStateData: actionStateData)
        //tab could have changed since the last state. Make sure the latest is selected
        selectTabFor(nextState: nextState, action: action)
        
        if action.type == .tabSelected {
            GeneralUtils.tabManager().removeEmptyTabs()
        }
        
        changeToState(nextState: nextState, action: action)
        
        if action.type == .backButtonPressed || action.type == .forwardButtonPressed {
            lastBackForwAction = action
        }
    }
    
    func changeToState(nextState: State, action: Action) {
        contentNavChangeToState(currentState: currentState.contentState, nextState: nextState.contentState, nextStateData: nextState.stateData, action: action)
        urlBarChangeToState(currentState: currentState.urlBarState, nextState: nextState.urlBarState, nextStateData: nextState.stateData)
        updateToolBar(nextState: nextState, action: action)
        
        if currentState.contentState != nextState.contentState {
            previousState = currentState
        }
        
        currentState = nextState
    }
    
    func contentNavChangeToState(currentState: ContentState, nextState: ContentState, nextStateData: StateData, action: Action) {
        
        //TODO: this needs to be explained.
        //This is in case I have a different state in between browse states. It makes sure that going the webview goes back or forward correctly.
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
            else if action.type != .newVisit && action.type != .webNavigationUpdate && action.type != .tabDonePressed /*&& action.type != .visitAddedInDB*/ && action.type != .backButtonPressed && action.type != .forwardButtonPressed && action.type != .urlInBackground {
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
            urlBar?.collapsedDomainBlue(urlStr: nextStateData.url)
        case .expandedEmptyWhite:
            urlBar?.expandedEmptyWhite()
        case .expandedTextWhite:
            urlBar?.expandedTextWhite(text: nextStateData.query)
        }
    }
    
    func updateToolBar(nextState: State, action: Action) {
        
        if let tab = nextState.stateData.tab {
            
            //Update Forward
            if BackForwardNavigation.shared.canGoForward(tab: tab) {
                toolBar?.setForwardEnabled()
            }
            else {
                toolBar?.setForwardDisabled()
            }
            
            //Update Back
            if BackForwardNavigation.shared.canGoBack(tab: tab) && !((nextState.contentState == .domains || nextState.contentState == .details || nextState.contentState == .dash) && BackForwardNavigation.shared.currentState(tab: tab)?.contentState != .search) {
                toolBar?.setBackEnabled()
            }
            else {
                toolBar?.setBackDisabled()
            }
            
            //Update Tabs
            let specialCond = GeneralUtils.tabManager().tabs.count == 1 && GeneralUtils.tabManager().tabs[0].url == nil && action.type != .urlSelected
            
            if GeneralUtils.tabManager().tabs.count == 0 || specialCond {
                toolBar?.setTabsDisabled()
            }
            else {
                toolBar?.setTabsEnabled()
            }
            
            if action.type == .urlInBackground {
                toolBar?.tabsVisualFeedback()
            }
        }
    }
}

extension StateManager {
    
    func canHandleAction(action: Action, stateData: StateData) -> Bool {
        if RouterActions.contains(action.type) {
            //handle only actions that are not handled by the Router
            return false
        }
        
        //.urlIsModified is called even when the url is the same. Ignore. I should fix this.
        if (stateData.url == currentState.stateData.url /*||  specialCond*/) && action.type == .urlIsModified {
            return false
        }
        
        if action.type == .searchStopEditing {
            
        }
        
        return true
    }
    
    func selectTabFor(nextState: State, action: Action) {
        if let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager {
            //tab Manager has to become a singleton. There cannot be 2 tab managers.
            if action.type == .tabSelected, let tab = nextState.stateData.tab {
                tabManager.selectTab(tab)
            }
        }
    }
    
    func addStateToNavigation(state: State, tab: Tab) {
        //change the tab in the StateData and then register the state
        var state = state
        let tabData = StateData(query: nil, url: nil, tab: tab, detailsHost: nil)
        state = state.sameStateWithNewData(newStateData: StateData.merge(lhs: tabData, rhs: state.stateData))
        BackForwardNavigation.shared.addState(tab: tab, state: state)
    }
}
