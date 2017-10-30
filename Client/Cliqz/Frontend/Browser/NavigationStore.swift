//
//  BackForwardNavigation.swift
//  Client
//
//  Created by Tim Palade on 9/21/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//


final class NavigationStore {
    
//    static let shared = BackForwardNavigation()
    
    struct StateChain {
        var states: [State]
        var currentIndex: Int
    }
    
    /*private*/ var tabStateChains: [Tab: StateChain] = [:]
    
    func addState(tab: Tab, state: State) {
        
        //Tab exists in the dict 
        //Subcases:
        //1. Add state at the end.
        //2. Add state in between. Rule: Discard all other after the current index, and add state at the end
        //Tab does not exist in the dict
        //Then create a stateChain and assign it to tabStateChains[tab]
        
        //Idea: I should add a rule such that if a state that is identical to the previous one is added (except for the state data), it should replace the old one. 
        //This works for search, where I am interested only in the last query
        //But it does not work for browse where I am interested in all browsed urls
        
        if var stateChain = tabStateChains[tab] {
            
            var states = stateChain.states
            var currentIndex = stateChain.currentIndex
            
            //If a state is completely identical to the current one (including state data), then ignore it.
            //No duplicates
            if let currentState = self.state(tab: tab, index: currentIndex) {
                if State.equalWithTheSameData(lhs: currentState, rhs: state) {
                    return
                }
            } else {
                //current state has to exist!!!
                NSException.init(name: NSExceptionName(rawValue: "CurrentState must exist"), reason: "Current state cannot be nil here. Something is wrong.", userInfo: nil).raise()
            }
            
            if hasNextState(tab: tab) { //I need to discard all states after the current one and then add this new one at the end
                //remove elements after currentIndex
                states = GeneralUtils.removeElementsAfter(index: currentIndex, array: states)
            }
            
            states.append(state)
            currentIndex += 1
            
            //assign
            stateChain.states = states
            stateChain.currentIndex = currentIndex
            
            tabStateChains[tab] = stateChain
        }
        else {
            tabStateChains[tab] = StateChain(states: [state], currentIndex: 0)
        }
        
    }
    
    func replaceCurrentState(tab: Tab, newState: State) {
        if var stateChain = tabStateChains[tab] {
            //assumption is that the currentIndex is within bounds
            let currentIndex = stateChain.currentIndex
            var states = stateChain.states
            
            if currentIndex >= 0 && currentIndex < stateChain.states.count {
                states[currentIndex] = newState
                stateChain.states = states
                tabStateChains[tab] = stateChain
            }
            else {
                //current state has to exist!!!
                NSException.init(name: NSExceptionName(rawValue: "CurrentIndex is out of bounds"), reason: "Current Index should never be out of bounds", userInfo: nil).raise()
            }
        }
    }
    
    func removeState(tab: Tab, index: Int) {
        if let stateChain = tabStateChains[tab] {
            if index >= 0 && index < stateChain.states.count {
                var states = stateChain.states
                let currentIndex = stateChain.currentIndex - 1
                states.remove(at: index)
                tabStateChains[tab] = StateChain(states: states, currentIndex: currentIndex)
            }
        }
    }
    
    func removeTab(tab: Tab) {
        tabStateChains.removeValue(forKey: tab)
    }
 
    func state(tab: Tab, index: Int) -> State? {
        if let stateChain = tabStateChains[tab] {
            if index >= 0 && index < stateChain.states.count {
                return stateChain.states[index]
            }
        }
        return nil
    }
    
    func currentState(tab: Tab) -> State? {
        if let currentIndex = currentIndex(tab: tab) {
            return state(tab: tab, index: currentIndex)
        }
        
        return nil
    }
    
    func currentIndex(tab: Tab) -> Int? {
        return tabStateChains[tab]?.currentIndex
    }
    
    func incrementIndex(tab: Tab) {
        if var stateChain = tabStateChains[tab] {
            let currentIndex = stateChain.currentIndex
            if currentIndex + 1 <= stateChain.states.count - 1 {
                stateChain.currentIndex = currentIndex + 1
                tabStateChains[tab] = stateChain
            }
            else {
                NSException.init(name: NSExceptionName(rawValue: "Incrementing out of bounds"), reason: "If you want to increment the current index, first add a state and then increment.", userInfo: nil).raise()
            }
        }
    }
    
    func decrementIndex(tab: Tab) {
        if var stateChain = tabStateChains[tab] {
            let currentIndex = stateChain.currentIndex
            if currentIndex - 1 >= 0 {
                stateChain.currentIndex = currentIndex - 1
                tabStateChains[tab] = stateChain
            }
            else {
                NSException.init(name: NSExceptionName(rawValue: "Decrementing out of bounds"), reason: "Current Index has cannot be decremented below 0", userInfo: nil).raise()
            }
        }
    }
    
    func hasNextState(tab: Tab) -> Bool {
        
        if let stateChain = tabStateChains[tab] {
            return stateChain.currentIndex >= 0 && stateChain.currentIndex < stateChain.states.count - 1
        }
        
        return false
    }
    
    func hasPrevState(tab: Tab) -> Bool {
        
        if let stateChain = tabStateChains[tab] {
            return stateChain.currentIndex > 0 && stateChain.currentIndex < stateChain.states.count
        }
        
        return false
    }
    
    func nextState(tab: Tab) -> State? {

        if let currentIndex = currentIndex(tab: tab) {
            return state(tab: tab, index: currentIndex + 1)
        }
        
        return nil
    }
    
    func prevState(tab: Tab) -> State? {
        
        if let currentIndex = currentIndex(tab: tab) {
            return state(tab: tab, index: currentIndex - 1)
        }
        
        return nil
    }
    
}
