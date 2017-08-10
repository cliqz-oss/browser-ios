//
//  StateAnimator.swift
//  StateAnimator
//
//  Created by Tim Palade on 8/3/17.
//  Copyright © 2017 Tim Palade. All rights reserved.
//

import UIKit

struct AnimationDetails {
    let curve: UIViewAnimationCurve
    let duration: TimeInterval
    let delayFactor: CGFloat
    
    init(duration: TimeInterval = 0.0, curve: UIViewAnimationCurve = .linear, delayFactor: CGFloat = 0.0) {
        self.curve = curve
        self.duration = duration
        self.delayFactor = delayFactor
    }
    
}

struct Transition {
    let beforeTransition: (() -> ())?
    let afterTransition:  (() -> ())?
    let endState: () -> ()
    let animationDetails: AnimationDetails
    
    init(endState: @escaping () -> (), beforeTransition: (() -> ())? = nil, afterTransition: (() -> ())? = nil, animationDetails: AnimationDetails = AnimationDetails()) {
        self.beforeTransition = beforeTransition
        self.afterTransition  = afterTransition
        self.endState = endState
        self.animationDetails = animationDetails
    }
    
}

struct Animator {
    let beforeTransitions: [() -> ()]
    let propertyAnimator: UIViewPropertyAnimator
}



final class StateAnimator {
    
    class func animate(animators: [Animator]) {
        for animator in animators {
            for beforeTransition in animator.beforeTransitions {
                beforeTransition()
            }
            
            animator.propertyAnimator.startAnimation()
        }
    }
    
    class func generateStates(transitions: [Transition]) -> [() -> ()] {
        return transitions.map({t in t.endState})
    }
    
    class func generateAnimators(state: [Transition], parentView: UIView) -> [Animator] {
        
        //propertyAnimators will have to following shape for smooth animations
        
        /*
         
         Animator(duration, curve, animations: {
         //transitions with the same duration, curve and delay == 0.0 are placed here
         transition1()
         transition2()
         ...
         
         }).addAnimations(delay, animations: {
         //transitions with the same duration, curve as the Animator they are attached to
         //are added here. Their delay != 0.0 and are grouped by delays
         //Ex: All transitions with delay 0.1 are here
         transition3() //delay == 0.1
         transition4() //delay == 0.1
         ...
         })
         ...
         //all other transitions grouped by delays follow.
         
         */
        
        func generateAnimator(duration: TimeInterval, curve: UIViewAnimationCurve, transitions: [Transition]) -> UIViewPropertyAnimator {
            return UIViewPropertyAnimator(duration: duration, curve: curve, animations: {
                for transition in transitions{
                    transition.endState()
                }
            })
        }
        
        func addTransitions2Animator(animator: UIViewPropertyAnimator, transitions: [Transition], delayFactor: CGFloat) {
            animator.addAnimations({
                for transition in transitions{
                    transition.endState()
                }
            }, delayFactor: delayFactor)
        }
        
        
        guard state.count > 0 else {
            return []
        }
        
        let grouped_dict = groupByDurationAndCurve(array: state)
        
        var animators: [Animator] = []
        
        //generate animators grouped by duration and curve
        for key in grouped_dict.keys {
            if let transitions_array = grouped_dict[key] {
                if transitions_array.count > 0 {
                    if let (curve, duration) = curveHash2Touple(hash: key) {
                        //generate the animator based on duration and curve
                        let delay_group_dict = groupByDelay(array: transitions_array)
                        let zeroTransitions = delay_group_dict[0.0] ?? []
                        let animator = generateAnimator(duration: duration, curve: curve, transitions: zeroTransitions)
                        
                        //add the rest of the transitions grouped by delay
                        for delay in delay_group_dict.keys {
                            if delay != 0.0 {
                                if let transitions = delay_group_dict[delay] {
                                    if transitions.count > 0 {
                                        addTransitions2Animator(animator: animator, transitions: transitions, delayFactor: delay)
                                    }
                                }
                            }
                        }
                        
                        //finally tell the parentView that it needs to layout.
                        animator.addAnimations({
                            parentView.layoutIfNeeded()
                        }, delayFactor: 0.0)
                        
                        //add completions in order 
                        animator.addCompletion({ (position) in
                            for transition in transitions_array {
                                if let completion = transition.afterTransition {
                                    completion()
                                }
                            }
                        })
                        
                        //prepare to add to array of animator
                        //what is left is to add the beforeTransition blocks
                        
                        var beforeTransitions: [() -> ()] = []
                        
                        for transition in transitions_array {
                            if let beforeTransition = transition.beforeTransition {
                                beforeTransitions.append(beforeTransition)
                            }
                        }
                        
                        animators.append(Animator(beforeTransitions: beforeTransitions, propertyAnimator: animator))
                    }
                }
            }
        }
        
        return animators
    }

    
    private class func curve2Hash(curve: UIViewAnimationCurve) -> String {
        
        if curve == .linear {
            return "linear"
        }
        else if curve == .easeIn {
            return "easeIn"
        }
        else if curve == .easeOut {
            return "easeOut"
        }
        else if curve == .easeInOut {
            return "easeInOut"
        }
        
        return "linear"
    }
    
    private class func hash2Curve(hash: String) -> UIViewAnimationCurve {
        
        if hash == "linear" {
            return .linear
        }
        else if hash == "easeIn" {
            return .easeIn
        }
        else if hash == "easeOut" {
            return .easeOut
        }
        else if hash == "easeInOut" {
            return .easeInOut
        }
        
        return .linear
    }
    
    private class func transitionHash(transition: Transition) -> String {
        
        return curve2Hash(curve: transition.animationDetails.curve) + "|" + String(transition.animationDetails.duration)
    }
    
    private class func curveHash2Touple(hash:String) -> (curve: UIViewAnimationCurve, duration: TimeInterval)? {
        let c = hash.components(separatedBy: "|")
        guard c.count == 2 else {
            return nil
        }
        let curveHash = hash2Curve(hash: c[0])
        let duration  = Double(c[1])
        
        //if the duration does not convert to a double, crash...there is a problem
        return (curveHash, duration!)
    }
    
    private class func groupBy<A, B:Hashable>(array:[A], hashF:(A) -> B) -> Dictionary<B, [A]>{
        var dict: Dictionary<B, [A]> = [:]
        
        for elem in array {
            let key = hashF(elem)
            if var array = dict[key] {
                array.append(elem)
                dict[key] = array
            }
            else {
                dict[key] = [elem]
            }
        }
        
        return dict
    }
    
    private class func groupByDurationAndCurve(array: [Transition]) -> Dictionary<String,[Transition]> {
        
        return groupBy(array: array, hashF: transitionHash)
        
    }
    
    private class func groupByDelay(array: [Transition]) -> Dictionary<CGFloat,[Transition]> {
        
        return groupBy(array: array, hashF: {transition in transition.animationDetails.delayFactor})
        
    }
    
}
