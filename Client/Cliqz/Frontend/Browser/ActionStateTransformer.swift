//
//  StateGenerator.swift
//  Client
//
//  Created by Tim Palade on 9/14/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//TO Do: Write proper documentation.

//Definition of Transform
//tranform : (State, action) -> (State)
//this transform can be composed of smaller transforms
//transform = contentTransf + urlBarTransf + ToolTransf + ...

//TO DO: update dicts above to include all actions
//define possible states
//define the possible transformations

final class ActionStateTransformer {
    
    class func nextState(previousState: State, currentState: State, actionType: ActionType, nextStateData: StateData) -> State {
        
        let processedStateData = processStateData(nextStateData: nextStateData, currentState: currentState, actionType: actionType)
        
        //after the data is processed I can be sure there is a tab!!!
        //the tab in the alteredStateData is the latest selected tab.
        let tab = processedStateData.tab!
        //there are actions that work with states that have already been computed
        if actionType == .backButtonPressed {
            return backState(tab: tab, currentState: currentState)!
        }
        else if actionType == .forwardButtonPressed {
            return forwardState(tab: tab, currentState: currentState)!
        }
        else if actionType == .urlBackPressed {
            //do not return the previousState that is passed in this method, because it does not always coincide with the one from store. This should be corrected.
            if let prevState = previousStateFromStore(tab: tab) {
                return prevState
            }
            return previousState
        }
        else if actionType == .tabSelected {
            if let (state, distance) = BackForwardNavigationHelper.firstContentStateBeforeCurrent(of: .browse, tab: tab) {
                BackForwardNavigation.shared.decrementIndexByDistance(tab: tab, distance: distance)
                return state
            }
            else if let (state, distance) = BackForwardNavigationHelper.firstContentStateAfterCurrent(of: .browse, tab: tab) {
                BackForwardNavigation.shared.incrementIndexByDistance(tab: tab, distance: distance)
                return state
            }
            else if let currentState_Tab = BackForwardNavigation.shared.currentState(tab: tab) {
                return currentState_Tab
            }
        }
        else if actionType == .urlInBackground {
            //add a new tab
            //add the current state to the new tab in the Navigation
            if let url = processedStateData.url {
                let newTab = GeneralUtils.tabManager().addTab()
                var data = processedStateData
                newTab.url = URL(string: url)
                data.addTab(tab: newTab)
                let newStateBackground = currentState.sameStateWithNewData(newStateData: data)
                BackForwardNavigation.shared.addState(tab: newTab, state: newStateBackground)
            }
            return currentState
        }
        
        return ActionStateTransformer.transform(previousState: previousState, currentState: currentState, actionType: actionType, nextStateData: processedStateData)
    }
    
    //this is the general transform
    private class func transform(previousState: State, currentState: State, actionType: ActionType, nextStateData: StateData) -> State {

        let contentNextState = contentNavTransform(previousState: previousState.contentState, currentState: currentState.contentState, nextStateData: nextStateData, actionType: actionType)
        let urlBarNextState = urlBarTransform(prevState: previousState.urlBarState, currentState: currentState.urlBarState, nextStateData: nextStateData, actionType: actionType)
        
        //right now the state of the back and forwward that I set here as disabled does not affect the ui
        let state = State(contentState: contentNextState, urlBarState: urlBarNextState, stateData: nextStateData)
        
        //Attention: A tab should exist at this point. Force unwrapping is intentional here
        let tab = state.stateData.tab!
        
        //Store the state if necessary
        if actionType == .urlBackPressed {
            BackForwardNavigation.shared.decrementIndex(tab: tab)
        }
        
        let addOrReplace = BackForwardAddRule.addOrReplace(state: state, tab: tab, actionType: actionType)
        
        if addOrReplace == .add {
            BackForwardNavigation.shared.addState(tab: tab, state: state)
        }
        else if addOrReplace == .replace {
            BackForwardNavigation.shared.replaceCurrentState(tab: tab, newState: state)
        }
        
        return state
    }
    
    private class func contentNavTransform(previousState: ContentState, currentState: ContentState, nextStateData: StateData, actionType: ActionType) -> ContentState {
        
        if actionType == .urlProgressChanged || actionType == .urlIsModified {
            return currentState
        }
        
        var nextState = currentState
        
        if let newState = contentNextState(actionType: actionType, previousState: previousState, currentState: currentState, nextStateData: nextStateData) {
            nextState = newState
        }
        
        return nextState
    }
    
    private class func urlBarTransform(prevState: URLBarState, currentState: URLBarState, nextStateData: StateData, actionType: ActionType) -> URLBarState {
        var nextState = currentState
        
        if let newState = urlBarNextState(actionType: actionType, previousState: prevState, currentState: currentState, nextStateData: nextStateData) {
            nextState = newState
        }
        
        return nextState
    }
    
}

//Helpers
extension ActionStateTransformer {
    
    class func processStateData(nextStateData: StateData, currentState: State, actionType: ActionType) -> StateData {
        //merges the new data with the old one
        var alteredStateData = StateData.merge(lhs: nextStateData, rhs: currentState.stateData)
        
        //creates tab in case no tab is there.
        if let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager {
            if alteredStateData.tab == nil {
                let tab = tabManager.addTabAndSelect()
                let newStateData = StateData(query: nil, url: nil, tab: tab, detailsHost: nil)
                alteredStateData = StateData.merge(lhs: newStateData, rhs: alteredStateData)
            }
        }
        
        //clean query
        if currentState.urlBarState == .collapsedEmptyTransparent && actionType == .urlSearchPressed {
            let newStateData = StateData(query: "", url: nil, tab: nil, detailsHost: nil)
            alteredStateData = StateData.merge(lhs: newStateData, rhs: alteredStateData)
        }
        
        return alteredStateData
    }
    
    class func backState(tab: Tab, currentState: State) -> State? {
        
        if BackForwardNavigation.shared.canWebViewGoBack(tab: tab) && currentState.contentState == .browse {
            //if currentState.contentState == .browse, back and forward update correctly bacause of urlIsModified and urlProgressChanged
            return currentState
        }
        else if let prevState = BackForwardNavigation.shared.prevState(tab: tab) {
            BackForwardNavigation.shared.decrementIndex(tab: tab)
            BackForwardNavigation.shared.replaceCurrentState(tab: tab, newState: prevState)
            return prevState
        }
        else {
            //there should be a prevState if the button can be pressed
            NSException.init().raise()
        }
        
        return nil
    }
    
    class func forwardState(tab: Tab, currentState: State) -> State? {
        
        if BackForwardNavigation.shared.canWebViewGoForward(tab: tab) && currentState.contentState == .browse {
            //if currentState.contentState == .browse, back and forward update correctly bacause of urlIsModified and urlProgressChanged
            return currentState
        }
        else if let nextState = BackForwardNavigation.shared.nextState(tab: tab) {
            BackForwardNavigation.shared.incrementIndex(tab: tab)
            BackForwardNavigation.shared.replaceCurrentState(tab: tab, newState: nextState)
            return nextState
        }
        else {
            //there should be a nextState if the button can be pressed
            NSException.init().raise()
        }
        
        return nil
    }
    
    class func previousStateFromStore(tab: Tab) -> State? {
        if let prevState = BackForwardNavigation.shared.prevState(tab: tab) {
            BackForwardNavigation.shared.decrementIndex(tab: tab)
            BackForwardNavigation.shared.replaceCurrentState(tab: tab, newState: prevState)
            return prevState
        }
        else {
            //there should be a prevState if the back button can be pressed
            NSException.init().raise()
        }
        
        return nil
    }
}

//Decision Structures
extension ActionStateTransformer {
    //The following decisionStructures define the nextState for each currentState and ActionType
    
    //Attention: Actions are missing.
    //New actions should always be included in the dicts here.
    
    //the rule it this: If I ignore an action it means that the action does not affect the state of this component
    //if I only define nextStates for subset of the states, then the action leaves the currentState as it is for the states that are not covered.
    class func contentNextState(actionType: ActionType, previousState: ContentState, currentState: ContentState, nextStateData: StateData) -> ContentState? {
        
        //this is for selecting an empty tab
        //think of a better way
        //maybe the tab should have a property isEmpty, and determine using that.
        var tabSelectedSpecialState: ContentState = .browse
        
        if nextStateData.tab?.url == nil {
            tabSelectedSpecialState = .domains
        }
        
        var tabDonePressedSpecialState: ContentState = currentState
        
        if let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager {
            if currentState == .browse && tabManager.tabs.count == 0 {
                tabDonePressedSpecialState = .domains
            }
        }
        
        let contentTransformDict: [ActionType : [ContentState: ContentState]] = [
            .initialization : [.browse : .domains, .search: .domains, .domains: .domains, .details: .domains, .dash: .domains],
            //.urlBackPressed : [.search: previousState],
            .urlClearPressed : [.search: .search],
            .urlSearchPressed : [.browse: .search, .domains: .search, .details : .search, .dash: .search],
            .urlSearchTextChanged : [.browse: .search, .domains: .search, .details : .search, .dash: .search],
            .urlSelected : [.search : .browse, .domains: .browse, .details: .browse, .dash: .browse],
            .homeButtonPressed : [.browse : .domains, .search: .domains, .domains: .dash, .details: .domains, .dash: .domains],
            .tabSelected : [.search : tabSelectedSpecialState, .domains: tabSelectedSpecialState, .details: tabSelectedSpecialState, .dash: tabSelectedSpecialState, .browse: tabSelectedSpecialState],
            .detailBackPressed : [.details: .domains],
            .domainPressed : [.domains: .details],
            .tabDonePressed : [.browse : tabDonePressedSpecialState, .search: tabDonePressedSpecialState, .domains: tabDonePressedSpecialState, .details: tabDonePressedSpecialState, .dash: tabDonePressedSpecialState]
        ]
        
        if let actionDict = contentTransformDict[actionType], let nextState = actionDict[currentState] {
            return nextState
        }
        
        return nil
    }
    
    class func urlBarNextState(actionType: ActionType, previousState: URLBarState, currentState: URLBarState, nextStateData: StateData) -> URLBarState? {
        
        let query = nextStateData.query ?? ""
        
        let queryEmpty: Bool = query == "" ? true : false
        
        let specialState: URLBarState = query != "" ? .expandedTextWhite : .expandedEmptyWhite
        
        //this is for selecting an empty tab
        var tabSelectedSpecialState: URLBarState = .collapsedDomainBlue
        
        if nextStateData.tab?.url == nil {
            tabSelectedSpecialState = .collapsedEmptyTransparent
        }
        
        var tabDonePressedSpecialState: URLBarState = currentState //The state does not change when the tabs are shown. So the state before opening the tabs is the current state
        
        if let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager {
            if currentState == .collapsedDomainBlue && tabManager.tabs.count == 0 {
                tabDonePressedSpecialState = .collapsedEmptyTransparent
            }
        }
        
        let urlBarTransformDict: [ActionType: [URLBarState: URLBarState]] = [
            .initialization : [ .collapsedEmptyTransparent: .collapsedEmptyTransparent, .collapsedTextTransparent: .collapsedEmptyTransparent, .collapsedTextBlue: .collapsedEmptyTransparent, .collapsedDomainBlue: .collapsedEmptyTransparent, .expandedEmptyWhite: .collapsedEmptyTransparent, .expandedTextWhite: .collapsedEmptyTransparent],
            //.urlBackPressed : [ .collapsedEmptyTransparent: previousState, .collapsedTextTransparent: previousState, .collapsedTextBlue: previousState, .collapsedDomainBlue: previousState, .expandedEmptyWhite: previousState, .expandedTextWhite: previousState],
            .urlClearPressed : [.expandedTextWhite: .expandedEmptyWhite],
            .urlSearchPressed : [ .collapsedEmptyTransparent: specialState, .collapsedTextTransparent: specialState, .collapsedTextBlue: specialState, .collapsedDomainBlue: specialState],
            .urlSearchTextChanged : [.expandedTextWhite: queryEmpty ? .expandedEmptyWhite : .expandedTextWhite, .expandedEmptyWhite : .expandedTextWhite],
            .searchAutoSuggest: [ .collapsedEmptyTransparent: .expandedTextWhite, .collapsedTextTransparent: .expandedTextWhite, .collapsedTextBlue: .expandedTextWhite, .collapsedDomainBlue: .expandedTextWhite, .expandedEmptyWhite: .expandedTextWhite],
            //This is when user swipes up or down on the cards. I should change the state to collapsedSearch
            .searchStopEditing: [ .expandedEmptyWhite: .collapsedTextTransparent, .expandedTextWhite: .collapsedTextTransparent],
            .urlSelected: [ .collapsedEmptyTransparent: .collapsedDomainBlue, .collapsedTextTransparent: .collapsedDomainBlue, .expandedEmptyWhite: .collapsedDomainBlue, .expandedTextWhite: .collapsedDomainBlue],
            .urlIsModified: [.collapsedDomainBlue: .collapsedDomainBlue],
            .homeButtonPressed: [.collapsedTextTransparent: .collapsedEmptyTransparent, .collapsedDomainBlue: .collapsedEmptyTransparent ,.collapsedTextBlue: .collapsedEmptyTransparent, .expandedEmptyWhite: .collapsedEmptyTransparent, .expandedTextWhite: .collapsedEmptyTransparent],
            .tabSelected: [ .collapsedEmptyTransparent: tabSelectedSpecialState, .collapsedTextTransparent: tabSelectedSpecialState, .collapsedDomainBlue: tabSelectedSpecialState, .collapsedTextBlue: tabSelectedSpecialState, .expandedEmptyWhite: tabSelectedSpecialState, .expandedTextWhite: tabSelectedSpecialState],
            .detailBackPressed : [.collapsedTextTransparent: .collapsedEmptyTransparent, .collapsedDomainBlue: .collapsedEmptyTransparent, .collapsedTextBlue: .collapsedEmptyTransparent, .expandedEmptyWhite: .collapsedEmptyTransparent, .expandedTextWhite: .collapsedEmptyTransparent],
            .domainPressed : [.collapsedTextTransparent: .collapsedEmptyTransparent, .collapsedDomainBlue: .collapsedEmptyTransparent ,.collapsedTextBlue: .collapsedEmptyTransparent, .expandedEmptyWhite: .collapsedEmptyTransparent, .expandedTextWhite: .collapsedEmptyTransparent],
            .tabDonePressed : [ .collapsedEmptyTransparent: tabDonePressedSpecialState, .collapsedTextTransparent: tabDonePressedSpecialState, .collapsedTextBlue: tabDonePressedSpecialState, .collapsedDomainBlue: tabDonePressedSpecialState, .expandedEmptyWhite: tabDonePressedSpecialState, .expandedTextWhite: tabDonePressedSpecialState]
        ]
        
        if let actionDict = urlBarTransformDict[actionType], let newState = actionDict[currentState] {
            return newState
        }
        
        return nil
    }
}
