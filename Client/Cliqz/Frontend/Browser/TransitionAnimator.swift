//
//  TransitionAnimator.swift
//  Client
//
//  Created by Mahmoud Adam on 11/25/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import UIKit

public enum TransitionDirection {
    case up
    case down
}

class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration    = 0.5
    var presenting  = true
    var transitionDirection = TransitionDirection.up
    var isAnimating = false
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?)-> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        isAnimating = true
        
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        
        
        let containerView = transitionContext.containerView
        let modalView = presenting ? toView : fromView
        containerView.addSubview(toView)
        containerView.bringSubview(toFront: modalView)
        
        
        let middelFrame = UIScreen.main.bounds
        let upperFrame = middelFrame.offsetBy(dx: 0, dy: -middelFrame.size.height)
        let lowerFrame = middelFrame.offsetBy(dx: 0, dy: middelFrame.size.height)
        
        if (transitionDirection == TransitionDirection.up && presenting) ||
           (transitionDirection == TransitionDirection.down && !presenting) {
            toView.frame = lowerFrame
            fromView.frame = middelFrame
        } else {
            toView.frame = upperFrame
            fromView.frame = middelFrame
        }

        self.isAnimating = false
        
        UIView.animate(withDuration: duration,
            animations: {
                
                if (self.transitionDirection == TransitionDirection.up && self.presenting) ||
                    (self.transitionDirection == TransitionDirection.down && !self.presenting) {
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
