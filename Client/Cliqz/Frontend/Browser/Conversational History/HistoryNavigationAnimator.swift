//
//  HistoryNavigationAnimator.swift
//  Client
//
//  Created by Tim Palade on 12/8/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

//import UIKit
//
//class HistoryNavigationAnimator: NSObject {
//    
//}
//
//extension HistoryNavigationAnimator: UIViewControllerAnimatedTransitioning {
//    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
//        return 2.0
//    }
//    
//    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
//        
//        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
//        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
//        
//        transitionContext.containerView.addSubview((toViewController?.view)!)
//        //toViewController?.view.alpha = 0.0
//        toViewController?.view.transform = CGAffineTransform.init(translationX: (toViewController?.view.bounds.width)!, y: 0)
//        
//        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
//            //fromViewController?.view.transform = CGAffineTransform.init(translationX: -(fromViewController?.view.bounds.width)!, y: 0.0)
//            toViewController?.view.transform = CGAffineTransform.identity
//            //toViewController?.view.alpha = 1.0
//        }) { (finished) in
//            fromViewController?.view.transform = CGAffineTransform.identity
//            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
//        }
//    }
//}

