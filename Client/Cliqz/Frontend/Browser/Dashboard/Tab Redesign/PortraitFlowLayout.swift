//
//  PortraitFlowLayout.swift
//  TabsRedesign
//
//  Created by Tim Palade on 3/29/17.
//  Copyright © 2017 Tim Palade. All rights reserved.
//

import UIKit

class TabSwitcherLayoutAttributes: UICollectionViewLayoutAttributes {
    
    var displayTransform: CATransform3D = CATransform3DIdentity
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! TabSwitcherLayoutAttributes
        copy.displayTransform = displayTransform
        return copy
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        guard let attr = object as? TabSwitcherLayoutAttributes else { return false }
        return super.isEqual(object) && CATransform3DEqualToTransform(displayTransform, attr.displayTransform)
    }
    
}

class PortraitFlowLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        self.minimumInteritemSpacing = UIScreen.mainScreen().bounds.size.width
        self.minimumLineSpacing = 0.0
        self.scrollDirection = .Vertical
        self.sectionInset = UIEdgeInsetsMake(16, 0, 0, 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class func layoutAttributesClass() -> AnyClass {
        return TabSwitcherLayoutAttributes.self
    }
    
    override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = super.initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath)
        attr?.zIndex = itemIndexPath.item
        return attr
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attrs = super.layoutAttributesForElementsInRect(rect) else {return nil}
        
        return attrs.map({ attr in
            return pimpedAttribute(attr)
        })
    }
    
    func pimpedAttribute(attribute: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        if let attr = attribute.copy() as? TabSwitcherLayoutAttributes {
            
            attr.zIndex = attr.indexPath.item
            
            var t: CATransform3D = CATransform3DIdentity
            
            if let count = self.collectionView?.numberOfItemsInSection(0) {//where count > 1 {
                
                t.m34 = -1.0 / (CGFloat(1000))
                
                let tiltAngle = Knobs.maxTiltAngle - (1/pow(Double(count), 0.85)) * (Knobs.maxTiltAngle - Knobs.minTiltAngle)
                t = CATransform3DRotate(t, -CGFloat(tiltAngle), 1, 0, 0)
                //attr.transform = CGAffineTransformIdentity
            }
            
            //t = CATransform3DScale(t, 0.95, 0.95, 1)
            attr.displayTransform = t
            
            return attr
        }
        return attribute
        
    }
}
