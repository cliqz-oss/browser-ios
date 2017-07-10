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
    
    var currentCount: Int = 0
    var currentTransform: CATransform3D = CATransform3DIdentity
    
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
    
    override func prepare() {
        if let count = self.collectionView?.numberOfItems(inSection: 0) {
            if count != currentCount {
                currentTransform = computeTransform(count: count)
                currentCount = count
            }
        }
    }
    
	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		guard let attrs = super.layoutAttributesForElements(in: rect) else {return nil}
        
        return attrs.map({ attr in
            return pimpedAttribute(attr)
        })
    }

    func pimpedAttribute(_ attribute: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        if let attr = attribute.copy() as? TabSwitcherLayoutAttributes {
            
            //attr.zIndex = attr.indexPath.item
            attr.displayTransform = currentTransform
            
            return attr
        }
        
        return attribute
    }
    
    func computeTransform(count:Int) -> CATransform3D {
        
        var t: CATransform3D = CATransform3DIdentity
        
        t.m34 = -1.0 / (CGFloat(1000))
        t = CATransform3DRotate(t, -CGFloat(Knobs.tiltAngle(count: count)), 1, 0, 0)
        
        //calculate how much down t will take the layer and then compensate for that.
        //this view must have the dimensions of the view this attr is going to be applied to.
        let view = UIView(frame: CGRect(x: 0, y: 0, width: Knobs.cellWidth(), height: Knobs.cellHeight()))
        view.layer.transform = t
        
        t = CATransform3DTranslate(t, 0, -view.layer.frame.origin.y, 0)
        
        return t
    }

}
