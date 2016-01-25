//
//  TransitionAnimator.swift
//  Client
//
//  Created by Mahmoud Adam on 11/25/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import UIKit

public enum TransitionDirection {
    case Up
    case Down
}

class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration    = 0.5
    var presenting  = true
    var transitionDirection = TransitionDirection.Up
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?)-> NSTimeInterval {
        return duration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        
        
        let containerView = transitionContext.containerView()!
        let modalView = presenting ? toView : fromView
        containerView.addSubview(toView)
        containerView.bringSubviewToFront(modalView)
        
        
        let middelFrame = UIScreen.mainScreen().bounds
        let upperFrame = CGRectOffset(middelFrame, 0, -middelFrame.size.height)
        let lowerFrame = CGRectOffset(middelFrame, 0, middelFrame.size.height)
        
        if (transitionDirection == TransitionDirection.Up && presenting) ||
           (transitionDirection == TransitionDirection.Down && !presenting) {
            toView.frame = lowerFrame
            fromView.frame = middelFrame
        } else {
            toView.frame = upperFrame
            fromView.frame = middelFrame
        }

        
        UIView.animateWithDuration(duration,
            animations: {
                
                if (self.transitionDirection == TransitionDirection.Up && self.presenting) ||
                    (self.transitionDirection == TransitionDirection.Down && !self.presenting) {
                    toView.frame = middelFrame
                    fromView.frame = upperFrame
                } else {
                    toView.frame = middelFrame
                    fromView.frame = lowerFrame
                }
            }, completion:{_ in
                transitionContext.completeTransition(true)
        })

        
    }

}
