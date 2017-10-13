//
//  BackForwardWrapper.swift
//  Client
//
//  Created by Tim Palade on 9/26/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class DomainsAddRule {
    
    class func canAdd(newState: State, tab: Tab, actionType: ActionType) -> Bool {
        
        guard actionType != .urlIsModified else {
            return false
        }
        
        guard newState.contentState == .domains else {
            return false
        }
        
        if let currentState = BackForwardNavigation.shared.currentState(tab: tab) {
            if currentState.contentState == newState.contentState && currentState.urlBarState == newState.urlBarState {
                return false
            }
        }
        
        return true
    }
}

class SearchAddRule {
    
    class func canAdd(newState: State, tab: Tab, actionType: ActionType) -> Bool {
        
        guard actionType != .urlIsModified else {
            return false
        }
        
        guard newState.contentState == .search else {
            return false
        }
        
        guard SearchAddRule.shouldReplaceCurrent(newState: newState, tab: tab, actionType: actionType) == false else {
            return false //one cannot add when one needs to replace
        }
        
        if let currentState = BackForwardNavigation.shared.currentState(tab: tab) {
            if currentState.contentState == .search {
                return false
            }
        }
        
        return true
        
    }
    
    class func shouldReplaceCurrent(newState: State, tab: Tab, actionType: ActionType) -> Bool {
        
        guard actionType != .urlIsModified else {
            return false
        }
        
        guard newState.contentState == .search else {
            return false
        }
        
        if let currentState = BackForwardNavigation.shared.currentState(tab: tab) {
            if currentState.contentState == .search && (newState.urlBarState == .expandedTextWhite || newState.urlBarState == .expandedEmptyWhite) {
                return true
            }
        }
        
        return false
    }
}

class BrowseAddRule {
    
    //Quick fix:
    //We now register browse states on urlIsSelected and replace them when visitAddedInDB.
    //This is not prefect since in the time between the load the user can navigate somewhere else.
    
    class func canAdd(newState: State, tab: Tab, actionType: ActionType) -> Bool {
        

        guard newState.contentState == .browse else {
            return false
        }
        
        guard actionType == .urlSelected else {
            return false
        }
//
//        guard actionType != .urlIsModified else {
//            return false
//        }
//
//        guard BrowseAddRule.shouldReplaceCurrent(newState: newState, tab: tab, actionType: actionType) == false else {
//            return false
//        }
//
//        guard actionType == .visitAddedInDB || (actionType == .urlSelected && BackForwardNavigation.shared.currentState(tab: tab)?.contentState != .browse) else {
//            return false
//        }
//
//        guard newState.stateData.url?.contains("localhost") == false else {
//            return false
//        }
//
//        if let currentState = BackForwardNavigation.shared.currentState(tab: tab) {
//            if currentState.contentState != .browse {
//                return true
//            }
//        }
        
        return true
        
    }
    
    class func shouldReplaceCurrent(newState: State, tab: Tab, actionType: ActionType) -> Bool {
        
//        guard actionType != .urlIsModified else {
//            return false
//        }
//
//        guard newState.contentState == .browse else {
//            return false
//        }
//
//        if let currentState = BackForwardNavigation.shared.currentState(tab: tab) {
//            if currentState.contentState == .browse {
//                return true
//            }
//        }
//
        return false
    }
}



final class BackForwardNavigation {
    
    static let shared = BackForwardNavigation()
    
    /*fileprivate */ let navigationStore: NavigationStore
    

    init() {
        navigationStore = NavigationStore()
    }
    
    func canGoBack(tab: Tab, currentState: State) -> Bool {
//        if currentState.contentState == .browse && BackForwardUtil.shared.previousEntry() == .history {
//            return true
//        }
//
//        return navigationStore.hasPrevState(tab: tab)
        
        return false
    }
    
    func canGoForward(tab: Tab, currentState: State) -> Bool {
//        if currentState.contentState == .browse && BackForwardUtil.shared.nextEntry() == .history {
//            return true
//        }
//
//        return navigationStore.hasNextState(tab: tab)
        
        return false
    }
    
    func addState(tab: Tab, state: State) {
        navigationStore.addState(tab: tab, state: state)
//        if state.contentState == .search {
//            BackForwardUtil.shared.addEntry(entry: .search)
//        }
//        else if state.contentState == .domains {
//            BackForwardUtil.shared.addEntry(entry: .domains)
//        }
//        else if state.contentState == .browse {
//            BackForwardUtil.shared.addEntry(entry: .browse(state.stateData.url ?? ""))
//        }
        
    }
    
    func updateCurrentStateData(tab: Tab, newStateData: StateData) {
        if let current_state = currentState(tab: tab) {
            let mergedData = StateData.merge(lhs: newStateData, rhs: current_state.stateData)
            replaceCurrentState(tab: tab, newState: current_state.sameStateWithNewData(newStateData: mergedData))
        }
    }
    
    func replaceCurrentState(tab: Tab, newState: State) {
        navigationStore.replaceCurrentState(tab: tab, newState: newState)
    }
    
    func removeTab(tab: Tab) {
        navigationStore.removeTab(tab: tab)
    }
    
    
    //This represents the currentState in the Store.
    func currentState(tab: Tab) -> State? {
        return navigationStore.currentState(tab: tab)
    }
    
    func prevState(tab: Tab) -> State? {
        return navigationStore.prevState(tab:tab)
    }
    
    func nextState(tab: Tab) -> State? {
        return navigationStore.nextState(tab:tab)
    }
    
    func shouldChangeToPrevState(tab: Tab, currentState: State) -> Bool {
        
//        if BackForwardUtil.shared.previousEntry() != BackForwardUtil.shared.currentEntry() {
//            return true
//        }
        
//        if currentState.contentState == .browse, tab.webView?.canGoBack == true {
//            return false
//        }
        
        return false
    }
    
    func shouldChangeToNextState(tab: Tab, currentState: State) -> Bool {
        
//        if BackForwardUtil.shared.nextEntry() != BackForwardUtil.shared.currentEntry() {
//            return true
//        }
        
//        if currentState.contentState == .browse, tab.webView?.canGoForward == true {
//            return false
//        }
        
        return false
    }
    
    func incrementIndex(tab: Tab) {
        navigationStore.incrementIndex(tab: tab)
    }
    
    func decrementIndex(tab: Tab) {
        navigationStore.decrementIndex(tab: tab)
    }
    
}
