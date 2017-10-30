//
//  BackForwardWrapper.swift
//  Client
//
//  Created by Tim Palade on 9/26/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

final class PageNavAddRule {
    class func canAdd(newState: State, tab: Tab, actionType: ActionType) -> Bool {
        
        guard actionType != .urlIsModified && actionType != .urlProgressChanged && actionType != .webNavigationUpdate else {
            return false
        }
        
        guard newState.contentState == .domains || newState.contentState == .details || newState.contentState == .dash else {
            return false
        }
        
        guard PageNavAddRule.shouldReplaceCurrent(newState: newState, tab: tab, actionType: actionType) == false else {
            return false
        }
        
        guard BackForwardNavigation.shared.currentState(tab: tab)?.contentState != .browse else {
            return false
        }
        
        return true
        
    }
    
    class func shouldReplaceCurrent(newState: State, tab: Tab, actionType: ActionType) -> Bool {
        
        guard actionType != .urlIsModified && actionType != .urlProgressChanged && actionType != .webNavigationUpdate else {
            return false
        }
        
        guard newState.contentState == .domains || newState.contentState == .details || newState.contentState == .dash else {
            return false
        }
        
        if let currentState = BackForwardNavigation.shared.currentState(tab: tab) {
            if currentState.contentState == .domains || currentState.contentState == .details || currentState.contentState == .dash {
                return true
            }
        }
        
        return false
    }
}

final class SearchAddRule {
    
    class func canAdd(newState: State, tab: Tab, actionType: ActionType) -> Bool {
        
        guard actionType != .urlIsModified && actionType != .urlProgressChanged && actionType != .webNavigationUpdate else {
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
        
        guard actionType != .urlIsModified && actionType != .urlProgressChanged && actionType != .webNavigationUpdate else {
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

final class BrowseAddRule {
    
    class func canAdd(newState: State, tab: Tab, actionType: ActionType) -> Bool {
        

        guard newState.contentState == .browse else {
            return false
        }
        
        guard actionType == .urlSelected /*|| actionType == .newVisit*/ else {
            return false
        }
        
        guard BrowseAddRule.shouldReplaceCurrent(newState: newState, tab: tab, actionType: actionType) == false else {
            return false
        }
        
        return true
        
    }
    
    class func shouldReplaceCurrent(newState: State, tab: Tab, actionType: ActionType) -> Bool {
        
        guard newState.contentState == .browse else {
            return false
        }
        
        if actionType == .urlIsModified || actionType == .urlProgressChanged {
            return true
        }
        
        return false
    }
}


final class BackForwardAddRule {
    
    enum AddOrReplace {
        case add
        case replace
        case none
    }
    
    class func addOrReplace(state: State, tab: Tab, actionType: ActionType) -> AddOrReplace {
        
        if /*actionType != .urlProgressChanged && actionType != .urlIsModified*/ actionType != .webNavigationUpdate {
            
            if PageNavAddRule.shouldReplaceCurrent(newState: state, tab: tab, actionType: actionType) || SearchAddRule.shouldReplaceCurrent(newState: state, tab: tab, actionType: actionType) || BrowseAddRule.shouldReplaceCurrent(newState: state, tab: tab, actionType: actionType) {
                return .replace
            }
            else if PageNavAddRule.canAdd(newState: state, tab: tab, actionType: actionType) || SearchAddRule.canAdd(newState: state, tab: tab, actionType: actionType) || BrowseAddRule.canAdd(newState: state, tab: tab, actionType: actionType) {
                return .add
            }
        }
    
        return .none
    }
}


final class BackForwardNavigationHelper {
    //returns the first found browse state and the distance between the current index and the index of the browse state
    class func firstBrowseStateBeforeCurrent(tab: Tab) -> (State, Int)? {
        let nav = BackForwardNavigation.shared
        if let currentIndex = nav.currentIndex(tab: tab) {
            var internalIndex = currentIndex
            while internalIndex >= 0 {
                let state: State = nav.state(tab: tab, index: internalIndex)! //this must exist
                if state.contentState == .browse {
                    return (state, GeneralUtils.distance(point1: internalIndex, point2: currentIndex))
                }
                internalIndex -= 1
            }
        }
        
        return nil
    }
    
    class func firstBrowseStateAfterCurrent(tab: Tab) -> (State, Int)? {
        let nav = BackForwardNavigation.shared
        if let currentIndex = nav.currentIndex(tab: tab), let maxIndex = nav.maxIndex(tab: tab) {
            var internalIndex = currentIndex
            while internalIndex >= 0 && internalIndex <= maxIndex {
                let state: State = nav.state(tab: tab, index: internalIndex)! //this must exist
                if state.contentState == .browse {
                    return (state, GeneralUtils.distance(point1: internalIndex, point2: currentIndex))
                }
                internalIndex += 1
            }
        }
        
        return nil
    }
}


final class BackForwardNavigation {
    
    static let shared = BackForwardNavigation()
    
    /*fileprivate */ let navigationStore: NavigationStore
    

    init() {
        _ = CurrentWebViewMonitor.shared
        navigationStore = NavigationStore()
    }
    
    func canGoBack(tab: Tab) -> Bool {
        if prevState(tab: tab) != nil || (canWebViewGoBack(tab: tab) && currentState(tab: tab)?.contentState == .browse) {
            return true
        }
        return false
    }
    
    func canWebViewGoBack(tab: Tab) -> Bool {
        return tab.webView?.canGoBack ?? false
    }
    
    func canGoForward(tab: Tab) -> Bool {
        if nextState(tab: tab) != nil || (canWebViewGoForward(tab: tab) && currentState(tab: tab)?.contentState == .browse) {
            return true
        }
        return false
    }
    
    func canWebViewGoForward(tab: Tab) -> Bool {
        return tab.webView?.canGoForward ?? false
    }
    
    func addState(tab: Tab, state: State) {
        navigationStore.addState(tab: tab, state: state)
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
    
    func removeState(tab: Tab, index: Int) {
        navigationStore.removeState(tab: tab, index: index)
    }
    
    func removeTab(tab: Tab) {
        navigationStore.removeTab(tab: tab)
    }
    
    //This represents the currentState in the Store.
    func state(tab: Tab, index: Int) -> State? {
        return navigationStore.state(tab: tab, index: index)
    }
    
    func currentState(tab: Tab) -> State? {
        return navigationStore.currentState(tab: tab)
    }
    
    func prevState(tab: Tab) -> State? {
        return navigationStore.prevState(tab:tab)
    }
    
    func nextState(tab: Tab) -> State? {
        return navigationStore.nextState(tab:tab)
    }
    
    func currentIndex(tab: Tab) -> Int? {
        return navigationStore.currentIndex(tab: tab)
    }
    
    func maxIndex(tab: Tab) -> Int? {
        if let count = navigationStore.tabStateChains[tab]?.states.count {
            return count - 1
        }
        return nil
    }
 
    func incrementIndex(tab: Tab) {
        navigationStore.incrementIndex(tab: tab)
    }
    
    func incrementIndexByDistance(tab:Tab, distance: Int) {
        for _ in 0..<distance {
            incrementIndex(tab: tab)
        }
    }
    
    func decrementIndex(tab: Tab) {
        navigationStore.decrementIndex(tab: tab)
    }
    
    func decrementIndexByDistance(tab: Tab, distance: Int) {
        for _ in 0..<distance {
            decrementIndex(tab: tab)
        }
    }
    
}
