//
//  StateGenerator.swift
//  Client
//
//  Created by Tim Palade on 9/14/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//


//Definition of Transform
//tranform : (State, action) -> (State)
//this transform can be composed of smaller transforms
//transform = contentTransf + urlBarTransf + ToolTransf + ...

//The following dicts define the nextState for each currentState and ActionTyoe

let mainTransformDict: [ActionType : [MainState: MainState]] = [
    .initialization : [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .urlBackPressed : [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .urlClearPressed : [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .urlSearchPressed : [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .urlSearchTextChanged : [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    //.searchTextChanged: [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
//    .searchTextCleared: [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .searchAutoSuggest: [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .searchStopEditing: [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .urlSelected: [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .urlIsModified: [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
//    .urlBarCancelEditing: [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .homeButtonPressed: [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .tabsPressed: [.other: .tabsVisible, .reminderVisible: .tabsVisible, .actionSheetVisible: .tabsVisible],
    .sharePressed: [.other: .actionSheetVisible, .reminderVisible: .actionSheetVisible, .tabsVisible: .actionSheetVisible],
    .backButtonPressed: [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .forwardButtonPressed: [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other],
    .remindersPressed: [.other: .reminderVisible, .actionSheetVisible: .reminderVisible, .tabsVisible: .reminderVisible],
    .tabSelected: [.reminderVisible: .other, .actionSheetVisible: .other, .tabsVisible: .other]
    //.visitAddedInDB - nothing should happen for this one
]


//Attention: Actions are missing.
//New actions should always be included in the dicts here.

//the rule it this: If I ignore an action it means that the action does not affect the state of this component
//if I only define nextStates for subset of the states, then the action leaves the currentState as it is for the states that are not covered.

func contentNextState(actionType: ActionType, previousState: ContentState, currentState: ContentState, nextStateData: StateData) -> ContentState? {
    
    //this is for selecting an empty tab
    //think of a better way
    //maybe the tab should have a property isEmpty, and determine using that.
    var specialState: ContentState = .browse
    
    if let url = nextStateData.url {
        if url.contains("localhost") {
            specialState = .domains
        }
    }
    else {
        specialState = .domains
    }
    
    let contentTransformDict: [ActionType : [ContentState: ContentState]] = [
        .initialization : [.browse : .domains, .search: .domains, .domains: .domains, .details: .domains, .dash: .domains],
        .urlBackPressed : [.search: .prevState],
        .urlClearPressed : [.search: .search],
        .urlSearchPressed : [.browse: .search, .domains: .search, .details : .search, .dash: .search],
        .urlSearchTextChanged : [.browse: .search, .domains: .search, .details : .search, .dash: .search],
        //    .searchTextChanged : [.browse: .search, .domains: .search, .details : .search, .dash: .search],
        //    .searchTextCleared : [.search : .prevState],
        //searchAutoSuggest
        //searchStopEditing
        .urlSelected : [.search : .browse, .domains: .browse, .details: .browse, .dash: .browse],
        //urlIsModified
        //    .urlBarCancelEditing : [.search: .prevState],
        .homeButtonPressed : [.browse : .domains, .search: .domains, .domains: .dash, .details: .domains, .dash: .domains],
        //.tabsPressed
        //.sharePressed
        //.backButtonPressed
        //.forwardButtonPressed
        //.remindersPressed
        .tabSelected : [.search : specialState, .domains: specialState, .details: specialState, .dash: specialState, .browse: specialState],
        .detailBackPressed : [.details: .domains],
        .domainPressed : [.domains: .details]
        //.visitAddedInDB - nothing should happen for this one
    ]
    
    if let actionDict = contentTransformDict[actionType], let nextState = actionDict[currentState] {
        return nextState
    }

    return nil
}



func urlBarNextState(actionType: ActionType, previousState: URLBarState, currentState: URLBarState, nextStateData: StateData) -> URLBarState? {
    
    let query = nextStateData.query ?? ""
    
    let queryEmpty: Bool = query == "" ? true : false
    
    let expandedTextIsPrev: Bool = previousState == .expandedTextWhite
    
    let specialState: URLBarState = expandedTextIsPrev ? .prevState : .expandedEmptyWhite
    
    //this is for selecting an empty tab
    var tabSelectedSpecialState: URLBarState = .collapsedDomainBlue
    
    if let url = nextStateData.url {
        if url.contains("localhost") {
            tabSelectedSpecialState = .collapsedEmptyTransparent
        }
    }
    else {
        tabSelectedSpecialState = .collapsedEmptyTransparent
    }
    
    //When I go back to search, if the previous state is also search, take the data from there (so that the text remains).
    
    //Problem - how is decision made to go either to collapsedTextBlue or collapsedDomainBlue?
    
    let urlBarTransformDict: [ActionType: [URLBarState: URLBarState]] = [
        .initialization : [ .collapsedEmptyTransparent: .collapsedEmptyTransparent, .collapsedTextTransparent: .collapsedEmptyTransparent, .collapsedTextBlue: .collapsedEmptyTransparent, .collapsedDomainBlue: .collapsedEmptyTransparent, .expandedEmptyWhite: .collapsedEmptyTransparent, .expandedTextWhite: .collapsedEmptyTransparent],
        //[ .collapsedEmptyTransparent: , .collapsedTextTransparent: , .collapsedTextBlue: , .expandedEmptyWhite: , .expandedTextWhite: ]
        .urlBackPressed : [ .collapsedEmptyTransparent: .prevState, .collapsedTextTransparent: .prevState, .collapsedTextBlue: .prevState, .collapsedDomainBlue: .prevState, .expandedEmptyWhite: .prevState, .expandedTextWhite: .prevState],
        .urlClearPressed : [.expandedTextWhite: .expandedEmptyWhite],
        .urlSearchPressed : [ .collapsedEmptyTransparent: specialState, .collapsedTextTransparent: specialState, .collapsedTextBlue: specialState, .collapsedDomainBlue: specialState],
        .urlSearchTextChanged : [.expandedTextWhite: queryEmpty ? .expandedEmptyWhite : .expandedTextWhite, .expandedEmptyWhite : .expandedTextWhite],
        .searchAutoSuggest: [ .collapsedEmptyTransparent: .expandedTextWhite, .collapsedTextTransparent: .expandedTextWhite, .collapsedTextBlue: .expandedTextWhite, .collapsedDomainBlue: .expandedTextWhite, .expandedEmptyWhite: .expandedTextWhite],
        //This is when user swipes up or down on the cards. I should change the state to collapsedSearch
        .searchStopEditing: [ .expandedEmptyWhite: .collapsedTextTransparent, .expandedTextWhite: .collapsedTextTransparent],
        .urlSelected: [ .collapsedEmptyTransparent: .collapsedDomainBlue, .collapsedTextTransparent: .collapsedDomainBlue, .expandedEmptyWhite: .collapsedDomainBlue, .expandedTextWhite: .collapsedDomainBlue],
        .urlIsModified: [.collapsedDomainBlue: .collapsedDomainBlue],
        .homeButtonPressed: [.collapsedTextTransparent: .collapsedEmptyTransparent, .collapsedDomainBlue: .collapsedEmptyTransparent ,.collapsedTextBlue: .collapsedEmptyTransparent, .expandedEmptyWhite: .collapsedEmptyTransparent, .expandedTextWhite: .collapsedEmptyTransparent],
        //.tabsPressed: [:],
        //.sharePressed: [:],
        //.backButtonPressed: [:],
        //.forwardButtonPressed: [:],
        //.remindersPressed: [:],
        .tabSelected: [ .collapsedEmptyTransparent: tabSelectedSpecialState, .collapsedTextTransparent: tabSelectedSpecialState, .collapsedDomainBlue: tabSelectedSpecialState, .collapsedTextBlue: tabSelectedSpecialState, .expandedEmptyWhite: tabSelectedSpecialState, .expandedTextWhite: tabSelectedSpecialState],
        .detailBackPressed : [.collapsedTextTransparent: .collapsedEmptyTransparent, .collapsedDomainBlue: .collapsedEmptyTransparent, .collapsedTextBlue: .collapsedEmptyTransparent, .expandedEmptyWhite: .collapsedEmptyTransparent, .expandedTextWhite: .collapsedEmptyTransparent],
        .domainPressed : [.collapsedTextTransparent: .collapsedEmptyTransparent, .collapsedDomainBlue: .collapsedEmptyTransparent ,.collapsedTextBlue: .collapsedEmptyTransparent, .expandedEmptyWhite: .collapsedEmptyTransparent, .expandedTextWhite: .collapsedEmptyTransparent]
        //.visitAddedInDB - nothing should happen for this one
    ]
    
    if let actionDict = urlBarTransformDict[actionType], let newState = actionDict[currentState] {
        return newState
    }
    
    return nil
}

//TO DO: update dicts above to include all actions
final class ActionStateTransformer {
    //define possible states
    //define the possible transformations
    
    
    class func nextState(previousState: State, currentState: State, actionType: ActionType, nextStateData: StateData) -> State {
        //work with the currently selected tab.
        
        //2 types of actions: [back, forward] and the other.
        //if the action is either back or forward, then:
        //1. get the state
        //2. increment/decrement
        //3. return state
        //if action is other, then:
        //1. get the state
        //2. add the state to the BackForwardNavigation (with rules)
        //3. return state
        
        
        //TO DO: Refactor this - Think about how to encapsulate the add rules
        
        //there should always be a selected tab!!!
        if let tab = currentState.stateData.tab {
            
            if actionType == .backButtonPressed, var state = BackForwardNavigation.shared.prevState(tab: tab) {
                BackForwardNavigation.shared.decrementIndex(tab: tab)
                state.toolBackState  = BackForwardNavigation.shared.hasPrevState(tab: tab) ? .enabled : .disabled
                state.toolForwardState = BackForwardNavigation.shared.hasNextState(tab: tab) ? .enabled : .disabled
                return state
            }
            else if actionType == .forwardButtonPressed, var state = BackForwardNavigation.shared.nextState(tab: tab) {
                BackForwardNavigation.shared.incrementIndex(tab: tab)
                state.toolBackState  = BackForwardNavigation.shared.hasPrevState(tab: tab) ? .enabled : .disabled
                state.toolForwardState = BackForwardNavigation.shared.hasNextState(tab: tab) ? .enabled : .disabled
                return state
            }
        }
        
        var state = ActionStateTransformer.transform(previousState: previousState, currentState: currentState, actionType: actionType, nextStateData: nextStateData)
        //register the new state
        
        if let tab = state.stateData.tab {
            
            //Register rules
            //No need for replacement for Browse. Add when there is a new entry in the DB.
            //If urlIsModified then I should replace the last browse with this one.
            if BrowseAddRule.canAdd(newState: state, tab: tab, actionType: actionType) {
                BackForwardNavigation.shared.addState(tab: tab, state: state)
            }
            else if SearchAddRule.shouldReplaceCurrent(newState: state, tab: tab, actionType: actionType) {
                BackForwardNavigation.shared.replaceCurrentState(tab: tab, newState: state)
            }
            else if SearchAddRule.canAdd(newState: state, tab: tab, actionType: actionType) {
                BackForwardNavigation.shared.addState(tab: tab, state: state)
            }
            else if DomainsAddRule.canAdd(newState: state, tab: tab, actionType: actionType) {
                BackForwardNavigation.shared.addState(tab: tab, state: state)
            }
            
            //update since something might have been added.
            state.toolBackState  = BackForwardNavigation.shared.hasPrevState(tab: tab) ? .enabled : .disabled
            state.toolForwardState = BackForwardNavigation.shared.hasNextState(tab: tab) ? .enabled : .disabled
        }
        
        return state
    }
    
    //this is the general transform
    private class func transform(previousState: State, currentState: State, actionType: ActionType, nextStateData: StateData) -> State {
        
        //The idea is that state data changes only when modified. If a url is not modified, then it remains like that. It is considered the last visited url.
        //The part about state data should be refactored.
        var alteredStateData = StateData.merge(lhs: nextStateData, rhs: currentState.stateData)
        
        //There should always be a tab selected. This makes sure that is true.
        if let appDel = UIApplication.shared.delegate as? AppDelegate, let tabManager = appDel.tabManager {
            if alteredStateData.tab == nil {
                let tab = tabManager.addTabAndSelect()
                let newStateData = StateData(query: nil, url: nil, tab: tab, indexPath: nil, image: nil)
                alteredStateData = StateData.merge(lhs: newStateData, rhs: alteredStateData)
            }
        }
        
        var mainNextState = mainContTransform(prevState: previousState.mainState, currentState: currentState.mainState, actionType: actionType)
        var contentNextState = contentNavTransform(previousState: previousState.contentState, currentState: currentState.contentState, actionType: actionType, nextStateData: nextStateData)
        var urlBarNextState = urlBarTransform(prevState: previousState.urlBarState, currentState: currentState.urlBarState, actionType: actionType, nextStateData: nextStateData)
        var toolBarNextState = toolBarTransform(currentState: currentState.toolBarState, actionType: actionType)
        
        var toolBackNextState: ToolBarBackState = .disabled
        var toolForwardNextState: ToolBarForwardState = .disabled
        
        
        var toolShareNextState = toolBarShareTransform(currentState: currentState.toolShareState, actionType: actionType)
        
        if mainNextState == .prevState {
            mainNextState = previousState.mainState
        }
        
        if contentNextState == .prevState {
            contentNextState = previousState.contentState
        }
        
        if urlBarNextState == .prevState {
            urlBarNextState = previousState.urlBarState
        }
        else if urlBarNextState == .collapsedTextTransparent {
            alteredStateData = currentState.stateData
        }
        
        if toolBarNextState == .prevState {
            toolBarNextState = previousState.toolBarState
        }
        
        if toolBackNextState == .prevState {
            toolBackNextState = previousState.toolBackState
        }
        
        if toolBackNextState == .prevState {
            toolBackNextState = previousState.toolBackState
        }
        
        if toolForwardNextState == .prevState {
            toolForwardNextState = previousState.toolForwardState
        }
        
        if toolShareNextState == .prevState {
            toolShareNextState = previousState.toolShareState
        }
        
        return State(mainState: mainNextState, contentState: contentNextState, urlBarState: urlBarNextState, toolBarState: toolBarNextState, toolBackState: toolBackNextState, toolForwardState: toolForwardNextState, toolShareState: toolShareNextState, stateData: alteredStateData)
        
    }
    
    private class func mainContTransform(prevState: MainState, currentState: MainState, actionType: ActionType) -> MainState {
        var nextState = currentState
        
        if let actionDict = mainTransformDict[actionType], let newState = actionDict[currentState] {
            nextState = newState
        }
        
        return nextState
    }
    
    private class func contentNavTransform(previousState: ContentState, currentState: ContentState, actionType: ActionType, nextStateData: StateData) -> ContentState {
        
        var nextState = currentState
        
        if let newState = contentNextState(actionType: actionType, previousState: previousState, currentState: currentState, nextStateData: nextStateData) {
            nextState = newState
        }
        
        return nextState
    }
    
    private class func urlBarTransform(prevState: URLBarState, currentState: URLBarState, actionType: ActionType, nextStateData: StateData) -> URLBarState {
        var nextState = currentState
        
        if let newState = urlBarNextState(actionType: actionType, previousState: prevState, currentState: currentState, nextStateData: nextStateData) {
            nextState = newState
        }
        
        return nextState
    }
    
    //the toolBar's state should be set by the action .didChangeOrientation, but we don't have it here yet.
    private class func toolBarTransform(currentState: ToolBarState, actionType: ActionType) -> ToolBarState {
        return currentState
    }
    
    //    class func toolBarBackTransform(prevState: ToolBarBackState, currentState: ToolBarBackState, action: ActionType) -> ToolBarBackState {
    //        return currentState
    //    }
    //
    //    class func toolBarForwardTransform(prevState: ToolBarForwardState, currentState: ToolBarForwardState, action: ActionType) -> ToolBarForwardState {
    //        return currentState
    //    }
    
    private class func toolBarShareTransform(currentState: ToolBarShareState, actionType: ActionType) -> ToolBarShareState {
        return currentState
    }
    
}
