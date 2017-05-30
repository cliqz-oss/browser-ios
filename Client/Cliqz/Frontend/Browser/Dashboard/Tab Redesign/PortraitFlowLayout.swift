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
    
	override func copy(with zone: NSZone? = nil) -> Any {
		let _copy = super.copy(with: zone) as! TabSwitcherLayoutAttributes
        _copy.displayTransform = displayTransform
        return _copy
    }
    
	override func isEqual(_ object: Any?) -> Bool {
        guard let attr = object as? TabSwitcherLayoutAttributes else { return false }
        return super.isEqual(object) && CATransform3DEqualToTransform(displayTransform, attr.displayTransform)
    }
    
}

class PortraitFlowLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        self.minimumInteritemSpacing = UIScreen.main.bounds.size.width
        self.minimumLineSpacing = 0.0
        self.scrollDirection = .vertical
        self.sectionInset = UIEdgeInsetsMake(16, 0, 0, 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
	override class var layoutAttributesClass: AnyClass {
        return TabSwitcherLayoutAttributes.self
    }
    
	override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		let attr = super.layoutAttributesForItem(at: indexPath)
        attr?.zIndex = indexPath.item
        return attr
	}

	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		guard let attrs = super.layoutAttributesForElements(in: rect) else {return nil}
        
        return attrs.map({ attr in
            return pimpedAttribute(attr)
        })
    }

    func pimpedAttribute(_ attribute: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        if let attr = attribute.copy() as? TabSwitcherLayoutAttributes {
            
            attr.zIndex = attr.indexPath.item
            
            var t: CATransform3D = CATransform3DIdentity
            
            if let count = self.collectionView?.numberOfItems(inSection: 0) {//where count > 1 {
                
                t.m34 = -1.0 / (CGFloat(1000))
                
                let maxTilt = Knobs.maxTiltAngle()
                let minTilt = Knobs.minTiltAngle()
                
                let tiltAngle = maxTilt - (1/pow(Double(count), 0.85)) * (maxTilt - minTilt)
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
