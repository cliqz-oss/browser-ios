//
//  BubbleCell.swift
//  Client
//
//  Created by Mahmoud Adam on 11/9/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
protocol BubbleCellSwipeDelegate: class {
    func didSwipe(atCell: UITableViewCell, direction: SwipeDirection)
}

class BubbleCell: ClickableUITableViewCell {
    let bubbleContainerView = UIView()
    
    let is24Hours = isTime24HoursFormatted()
    private let velocityTreshold = CGFloat(100.0)
    
    weak var swipeDelegate: BubbleCellSwipeDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupComponents()
        setStyles()
        setConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.remakeConstraints()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bubbleContainerView.layer.transform = CATransform3DIdentity
    }
    
    func setupComponents() {
        self.contentView.addSubview(bubbleContainerView)
        
        // add pan gesture
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        gesture.delegate = self
        bubbleContainerView.addGestureRecognizer(gesture)
    }
    
    func setStyles() {
        
    }
    
    func setConstraints() {
        bubbleContainerView.snp.makeConstraints { (make) in
            make.top.right.bottom.left.equalTo(self.contentView)
        }
    }
    
    
    func remakeConstraints() {
        
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let recognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = recognizer.translation(in: self.superview)
            return abs(translation.x) > abs(translation.y)
        }
        return true
    }
    
    func handlePan(recognizer: UIPanGestureRecognizer) {
        
        switch recognizer.state {
        case .changed:
            let translation = recognizer.translation(in: self.superview)
            let transform = bubbleContainerView.layer.transform
            bubbleContainerView.layer.transform = CATransform3DTranslate(transform, translation.x, 0, 0)
            recognizer.setTranslation(CGPoint.zero, in: bubbleContainerView)
            
        case .cancelled, .ended:
            
            let velocity = recognizer.velocity(in: self)
            let aboveTreshold = abs(velocity.x) > self.velocityTreshold
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                let cellWidth = self.frame.width
                if aboveTreshold {
                    let deltaX = velocity.x > 0 ? cellWidth : -cellWidth
                    self.bubbleContainerView.layer.transform = CATransform3DTranslate(CATransform3DIdentity, deltaX, 0, 0)
                    self.alpha = 0.0
                }
                else {
                    self.bubbleContainerView.layer.transform = CATransform3DIdentity
                }

            }, completion: { finished in
                if finished && aboveTreshold {
                    self.swipeDelegate?.didSwipe(atCell: self, direction: velocity.x > 0 ? .Right : .Left)
                }
            })
            
        default: break
        }
    }
    
    
}
