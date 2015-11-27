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
        
        
        if transitionDirection == TransitionDirection.Up {
            if presenting {
                toView.frame = lowerFrame
            } else {
                fromView.frame = middelFrame
            }
        } else {
            if presenting {
                toView.frame = upperFrame
            } else {
                fromView.frame = middelFrame
            }
        }
        
        UIView.animateWithDuration(duration,
            animations: {
                
                if self.transitionDirection == TransitionDirection.Up {
                    if self.presenting {
                        toView.frame = middelFrame
                    } else {
                        fromView.frame = lowerFrame
                    }
                } else {
                    if self.presenting {
                        toView.frame = middelFrame
                    } else {
                        fromView.frame = upperFrame
                    }
                }
            }, completion:{_ in
                transitionContext.completeTransition(true)
        })

        
    }

}
