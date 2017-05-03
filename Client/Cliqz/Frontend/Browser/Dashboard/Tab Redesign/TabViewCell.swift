//
//  TabViewCell.swift
//  TabSwitcherViewDemo
//
//  Created by Amornchai Kanokpullwad on 7/26/2558 BE.
//  Copyright (c) 2558 zoonref. All rights reserved.
//

import UIKit
import QuartzCore
import SnapKit
import Shared

protocol TabViewCellDelegate: class {
    func removeTab(cell: TabViewCell, swipe: SwipeType)
}

enum SwipeType {
    case None
    case Left
    case Right
}

class TabViewCell: UICollectionViewCell {

    let velocityTreshold = CGFloat(100.0)//to be adjusted on real device
    let displayView: UIView
    let gradientView: UIView
    weak var delegate: TabViewCellDelegate?
    private var logoImageView: UIImageView
    private var fakeLogoView: UIView?
    var domainLabel: UILabel
    var descriptionLabel: UILabel
    private var bigLogoImageView: UIImageView
    private var smallCenterImageView: UIImageView
    private var fakeSmallCenterView: UIView?
    
    var deleteButton: UIButton
    var isPrivateTabCell: Bool = false
    var clickedElement: String?
    
    private var currentTransform: CATransform3D?
    
    func showShadow(visible:Bool) {
        if visible{
            layer.shadowColor = UIColor.blackColor().CGColor
        }
        else{
            layer.shadowColor = UIColor.clearColor().CGColor
        }
    }
    
    func makeCellPrivate() {
        self.isPrivateTabCell = true
        self.displayView.backgroundColor = UIColor.darkGrayColor()
        self.deleteButton.imageView?.tintColor = UIColor.whiteColor()
        self.descriptionLabel.textColor = UIConstants.PrivateModeTextColor
    }
    
    func makeCellUnprivate() {
        self.isPrivateTabCell = false
        self.displayView.backgroundColor = UIColor.whiteColor()
        self.deleteButton.imageView?.tintColor = UIColor.darkGrayColor()
        self.descriptionLabel.textColor = UIConstants.NormalModeTextColor
    }
    
    func setSmallUpperLogo(image:UIImage?) {
        guard let image = image else { return }
        self.logoImageView.image = image
    }
    
    func setBigLogo(image:UIImage?) {
        guard let image = image else { return }
        self.smallCenterImageView.image = image
        let bg_color = image.getPixelColor(CGPoint(x: 10,y: 10))
        self.bigLogoImageView.backgroundColor = bg_color
    }
    
    func setSmallUpperLogoView(view:UIView?) {
        guard let view = view else { return }
        self.fakeLogoView = view
        self.displayView.addSubview(view)
        self.displayView.bringSubviewToFront(view)
        view.snp_makeConstraints { (make) in
            make.top.left.right.bottom.equalTo(self.logoImageView)
        }
    }
    
    func setBigLogoView(view:UIView?) {
        guard let view = view else { return }
        self.fakeSmallCenterView = view
        self.displayView.addSubview(view)
        self.displayView.bringSubviewToFront(view)
        view.snp_remakeConstraints { (make) in
            make.top.left.right.bottom.equalTo(self.smallCenterImageView)
        }
        let bg_color = view.backgroundColor
        self.bigLogoImageView.backgroundColor = bg_color
    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {

        displayView = UIView()
        gradientView = UIView(frame: displayView.bounds)
        
        //logoImageView
        let small_logo_imageview = UIImageView()
        small_logo_imageview.backgroundColor = UIColor(colorString:"E5E4E5")
        displayView.addSubview(small_logo_imageview)
        logoImageView = small_logo_imageview
        
        //deleteButton
        
        let delete_button = UIButton(type:.Custom)
        delete_button.setImage(UIImage(named: "find_close")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: .Normal)
        displayView.addSubview(delete_button)
        deleteButton = delete_button
        deleteButton.accessibilityLabel = "closeTab"
        
        //domainLabel
        let domain_label = UILabel()
        domain_label.textColor = UIColor(colorString: "0086E0")
        domain_label.font = UIFont.boldSystemFontOfSize(16)
        domain_label.text = ""
        displayView.addSubview(domain_label)
        domainLabel = domain_label
        
        //descriptionLabel
        let description_label = UILabel()
        description_label.font = UIFont.boldSystemFontOfSize(18)
        description_label.text = ""
        description_label.numberOfLines = 0
        displayView.addSubview(description_label)
        descriptionLabel = description_label
        //descriptionLabel.accessibilityLabel = "New Tab, Most visited sites and News"
        
        //bigLogoImage
        let big_logo_imageView = UIImageView()
        big_logo_imageView.backgroundColor = UIColor(colorString:"E5E4E5")
        displayView.addSubview(big_logo_imageView)
        bigLogoImageView = big_logo_imageView
        
        //smaller image view in the center - this displays the actual logo
        let smaller_imageView = UIImageView()
        smaller_imageView.backgroundColor = UIColor.clearColor()
        bigLogoImageView.addSubview(smaller_imageView)
        smallCenterImageView = smaller_imageView

        super.init(frame: frame)
        
        self.displayView.accessibilityLabel = "New Tab, Most visited sites and News"
        
        self.deleteButton.addTarget(self, action: #selector(didPressDelete), forControlEvents: .TouchUpInside)
        
        displayView.layer.frame = displayView.bounds
        //displayView.layer.shouldRasterize = true
        
        //corner radius
        displayView.layer.masksToBounds = true
        displayView.layer.cornerRadius = 4
        
        //shadow
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 6.0
        layer.shadowOffset = CGSize(width:0, height: -2.0)
        layer.shadowOpacity = 0.6
        
        contentView.addSubview(displayView)
        
        //add the constraints
        self.setConstraints()
        
        // add motion effect
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "layer.transform",
            type: .TiltAlongVerticalAxis)
        
        var tranformMinRelative = CATransform3DIdentity
        tranformMinRelative = CATransform3DRotate(tranformMinRelative, CGFloat(M_PI / 10), 1, 0, 0);
        
        var tranformMaxRelative = CATransform3DIdentity
        tranformMaxRelative = CATransform3DRotate(tranformMaxRelative, CGFloat(-M_PI / 10), 1, 0, 0);
        
        verticalMotionEffect.minimumRelativeValue = NSValue(CATransform3D: tranformMinRelative)
        verticalMotionEffect.maximumRelativeValue = NSValue(CATransform3D: tranformMaxRelative)
        
        displayView.addMotionEffect(verticalMotionEffect)
        
        // add pan gesture
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        gesture.delegate = self
        displayView.addGestureRecognizer(gesture)
        
        // tab gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapPressed))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        self.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    override func prepareForReuse() {
        self.domainLabel.text = ""
        self.descriptionLabel.text = ""
        self.logoImageView.image = nil
        self.bigLogoImageView.image = nil
        self.bigLogoImageView.backgroundColor = UIColor(colorString:"E5E4E5")
        self.smallCenterImageView.image = nil
        
        self.fakeLogoView?.removeFromSuperview()
        self.fakeSmallCenterView?.removeFromSuperview()
        self.fakeLogoView = nil
        self.fakeSmallCenterView = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setConstraints()
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        
        if let attr = layoutAttributes as? TabSwitcherLayoutAttributes {
            displayView.layer.transform = attr.displayTransform
            currentTransform = attr.displayTransform
        }
    }

    
    override func willTransitionFromLayout(oldLayout: UICollectionViewLayout, toLayout newLayout: UICollectionViewLayout) {
        super.willTransitionFromLayout(oldLayout, toLayout: newLayout)
        self.contentView.setNeedsLayout()
    }

    func setConstraints() {
        
        let screenSize = UIScreen.mainScreen().bounds.size
        let isPortrait = screenSize.height > screenSize.width
        
        if isPortrait {
            self.displayView.snp_remakeConstraints { (make) in
                self.showShadow(true)
                make.left.right.top.equalTo(self.contentView)
                make.height.equalTo(self.contentView.frame.width * Knobs.cellHeightMultiplier)
            }
            
            self.logoImageView.snp_remakeConstraints { (make) in
                self.logoImageView.hidden = false
                make.top.equalTo(self.displayView)
                make.left.equalTo(self.displayView).inset(10)
                make.width.height.equalTo(44.0)
            }
            
            self.deleteButton.snp_remakeConstraints { (make) in
                make.top.equalTo(self.displayView)
                make.right.equalTo(self.displayView)//.inset(10)
                make.width.height.equalTo(44.0)
            }
            
            self.domainLabel.snp_remakeConstraints { (make) in
                make.top.equalTo(self.displayView)
                make.left.equalTo(self.logoImageView).offset(54.0)
                make.right.equalTo(self.deleteButton).inset(44.0)
                make.height.equalTo(44.0)
            }
            
            self.descriptionLabel.snp_remakeConstraints { (make) in
                self.descriptionLabel.hidden = false
                make.top.equalTo(self.domainLabel.snp_bottom)
                make.left.right.equalTo(self.displayView).inset(10.0)
                make.height.equalTo(54.0)//54
            }
            
            self.bigLogoImageView.snp_remakeConstraints { (make) in
                make.top.equalTo(self.descriptionLabel.snp_bottom)
                make.left.right.bottom.equalTo(self.displayView).inset(10)
            }
            
            self.smallCenterImageView.snp_remakeConstraints { (make) in
                make.center.equalTo(self.bigLogoImageView)
                make.height.width.equalTo(80.0)//80
            }
        }
        
        else {
            self.displayView.snp_remakeConstraints { (make) in
                self.showShadow(false)
                make.left.right.top.bottom.equalTo(self.contentView)
            }
            
            self.logoImageView.snp_remakeConstraints { (make) in
                self.logoImageView.hidden = true
            }
            
            self.deleteButton.snp_remakeConstraints { (make) in
                make.top.equalTo(self.displayView)
                make.right.equalTo(self.displayView)//.inset(10)
                make.width.height.equalTo(44.0)
            }
            
            self.domainLabel.snp_remakeConstraints { (make) in
                make.top.equalTo(self.displayView)
                make.left.equalTo(self.displayView).offset(10.0)
                make.right.equalTo(self.deleteButton).inset(44.0)
                make.height.equalTo(44.0)
            }
            
            self.descriptionLabel.snp_remakeConstraints { (make) in
                self.descriptionLabel.hidden = true
            }
            
            self.bigLogoImageView.snp_remakeConstraints { (make) in
                make.top.equalTo(self.domainLabel.snp_bottom)
                make.left.right.bottom.equalTo(self.displayView).inset(10)
            }
            
            self.smallCenterImageView.snp_remakeConstraints { (make) in
                make.center.equalTo(self.bigLogoImageView)
                make.height.width.equalTo(40.0)//80
            }
        }
        
        
    }
    
 
    
    @objc
    func didPressDelete(sender:UIButton) {
        self.delegate?.removeTab(self, swipe: .None)
    }
    
    func tapPressed(gestureRecognizer: UIGestureRecognizer) {
        
        let touchLocation = gestureRecognizer.locationInView(self.displayView)
        
        if self.descriptionLabel.frame.contains(touchLocation) {
            clickedElement = "title"
        } else if self.domainLabel.frame.contains(touchLocation) {
            clickedElement = "url"
        } else if self.bigLogoImageView.frame.contains(touchLocation) {
            clickedElement = "logo"
        }
    }
    
    func handlePan(recognizer: UIPanGestureRecognizer) {
        
        let screenSize = UIScreen.mainScreen().bounds.size
        let isPortrait = screenSize.height > screenSize.width
        
        if !isPortrait{
            return
        }
        
        switch recognizer.state {
        case .Changed:
            let translation = recognizer.translationInView(self.superview)
            let transform = displayView.layer.transform
            displayView.layer.transform = CATransform3DTranslate(transform, translation.x, 0, 0)
            recognizer.setTranslation(CGPoint.zero, inView: displayView)
            
        case .Cancelled, .Ended:
            
            let velocity = recognizer.velocityInView(self)
            let aboveTreshold = abs(velocity.x) > self.velocityTreshold
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                if let transform = self.currentTransform {
                    let cellWidth = self.frame.width
                    if aboveTreshold {
                        let deltaX = velocity.x > 0 ? cellWidth : -cellWidth
                        self.displayView.layer.transform = CATransform3DTranslate(transform, deltaX, 0, 0)
                        self.alpha = 0.0
                    }
                    else{
                        self.displayView.layer.transform = transform
                    }
                }
                },completion: { finished in
                    if finished && aboveTreshold{
                        self.delegate?.removeTab(self, swipe: velocity.x > 0 ? .Right : .Left)
                    }
            })
            
        default: break
        }
    }
    
}

extension TabViewCell: UIGestureRecognizerDelegate {
    
    // fix hard to scroll vertically
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = pan.velocityInView(displayView)
            return fabs(velocity.x) > fabs(velocity.y);
        }
        return true
    }
    
}
