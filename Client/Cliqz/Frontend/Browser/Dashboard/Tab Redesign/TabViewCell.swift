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
    private var cliqzLogoImageView: UIImageView
    
    var deleteButton: UIButton
    var isPrivateTabCell: Bool = false
    var clickedElement: String?
    
    private var currentTransform: CATransform3D?
    
    func showShadow(_ visible: Bool) {
        if visible{
            layer.shadowColor = UIColor.black.cgColor
        }
        else{
            layer.shadowColor = UIColor.clear.cgColor
        }
    }
    
    func makeCellPrivate() {
        self.isPrivateTabCell = true
        self.displayView.backgroundColor = UIColor.darkGray
        self.deleteButton.imageView?.tintColor = UIColor.white
        self.descriptionLabel.textColor = UIConstants.PrivateModeTextColor
    }
    
    func makeCellUnprivate() {
        self.isPrivateTabCell = false
        self.displayView.backgroundColor = UIColor.white
        self.deleteButton.imageView?.tintColor = UIColor.darkGray
        self.descriptionLabel.textColor = UIConstants.NormalModeTextColor
    }
    
    func isSmallUpperLogoNil() -> Bool {
        return self.logoImageView.image == nil
    }
    
    func setSmallUpperLogo(_ image: UIImage?) {
        guard let image = image else { return }
        self.logoImageView.image = image
    }
    
    func setBigLogo(image:UIImage?, cliqzLogo: Bool) {
        guard let image = image else { return }
        
        if cliqzLogo {
            self.bigLogoImageView.backgroundColor = UIConstants.CliqzThemeColor
            self.cliqzLogoImageView.image = image
            return
        }
        
        self.smallCenterImageView.image = image
        let bg_color = image.getPixelColor(pos: CGPoint(x: 10,y: 10))
        self.bigLogoImageView.backgroundColor = bg_color
    }
    
    func setSmallUpperLogoView(_ view: UIView?) {
        guard let view = view else { return }
        self.fakeLogoView = view
        self.displayView.addSubview(view)
        self.displayView.bringSubview(toFront: view)
        view.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalTo(self.logoImageView)
        }
    }
    
    func setBigLogoView(_ view: UIView?) {
        guard let view = view else { return }
        self.fakeSmallCenterView = view
        self.displayView.addSubview(view)
        self.displayView.bringSubview(toFront: view)
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
        small_logo_imageview.layer.masksToBounds = true
        small_logo_imageview.layer.cornerRadius = 2
        small_logo_imageview.backgroundColor = UIColor.clear
        displayView.addSubview(small_logo_imageview)
        logoImageView = small_logo_imageview
        
        //deleteButton
        
        let delete_button = UIButton(type:.custom)
        delete_button.setImage(UIImage(named: "TabClose")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate), for: .normal)
        displayView.addSubview(delete_button)
        deleteButton = delete_button
        deleteButton.accessibilityLabel = "closeTab"
        
        //domainLabel
        let domain_label = UILabel()
        domain_label.textColor = UIColor(colorString: "0086E0")
        domain_label.font = UIFont.boldSystemFont(ofSize: 16)
        domain_label.text = ""
        displayView.addSubview(domain_label)
        domainLabel = domain_label
        
        //descriptionLabel
        let description_label = UILabel()
        description_label.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
        description_label.text = ""
        description_label.numberOfLines = 0
        displayView.addSubview(description_label)
        descriptionLabel = description_label
        
        //bigLogoImage
        let big_logo_imageView = UIImageView()
        big_logo_imageView.backgroundColor = UIColor(colorString:"E5E4E5")
        big_logo_imageView.layer.masksToBounds = true
        big_logo_imageView.layer.cornerRadius = 3
        displayView.addSubview(big_logo_imageView)
        bigLogoImageView = big_logo_imageView
        
        
        //smaller image view in the center - this displays the actual logo
        let smaller_imageView = UIImageView()
        smaller_imageView.backgroundColor = UIColor.clear
        bigLogoImageView.addSubview(smaller_imageView)
        smallCenterImageView = smaller_imageView
        
        //new tab cliqz logo image view
        
        let cliqz_imgView = UIImageView()
        cliqz_imgView.backgroundColor = UIColor.clear
        cliqz_imgView.contentMode = .scaleAspectFit
        bigLogoImageView.addSubview(cliqz_imgView)
        cliqzLogoImageView = cliqz_imgView

        super.init(frame: frame)
        
        self.displayView.accessibilityLabel = "New Tab, Most visited sites and News"
        
		self.deleteButton.addTarget(self, action: #selector(didPressDelete), for: .touchUpInside)
		
        displayView.layer.frame = displayView.bounds
        //displayView.layer.shouldRasterize = true
        
        //corner radius
        displayView.layer.masksToBounds = true
        displayView.layer.cornerRadius = 4
        
        //shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 6.0
        layer.shadowOffset = CGSize(width:0, height: -2.0)
        layer.shadowOpacity = 0.6
        
        contentView.addSubview(displayView)
        
        //add the constraints
        self.setConstraints()
        
        // add motion effect
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "layer.transform",
            type: .tiltAlongVerticalAxis)
        
        var tranformMinRelative = CATransform3DIdentity
        tranformMinRelative = CATransform3DRotate(tranformMinRelative, CGFloat(M_PI / 10), 1, 0, 0);
        
        var tranformMaxRelative = CATransform3DIdentity
		tranformMaxRelative = CATransform3DRotate(tranformMaxRelative, CGFloat(-M_PI / 10), 1, 0, 0);
		
		verticalMotionEffect.minimumRelativeValue = NSValue(caTransform3D: tranformMinRelative)
		verticalMotionEffect.maximumRelativeValue = NSValue(caTransform3D: tranformMaxRelative)
		
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
        self.cliqzLogoImageView.image = nil
        
        self.fakeLogoView?.removeFromSuperview()
        self.fakeSmallCenterView?.removeFromSuperview()
        self.fakeLogoView = nil
        self.fakeSmallCenterView = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setConstraints()
    }
    
	override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
		super.apply(layoutAttributes)
		
        if let attr = layoutAttributes as? TabSwitcherLayoutAttributes {
            displayView.layer.transform = attr.displayTransform
            currentTransform = attr.displayTransform
        }
    }

    
	override func willTransition(from oldLayout: UICollectionViewLayout, to newLayout: UICollectionViewLayout) {
		super.willTransition(from: oldLayout, to: newLayout)
        self.contentView.setNeedsLayout()
    }

    func setConstraints() {
        
		let screenSize = UIScreen.main.bounds.size
        let isPortrait = screenSize.height > screenSize.width
        
        if isPortrait {
			self.displayView.snp.remakeConstraints { (make) in
                self.showShadow(true)
                make.left.right.top.equalTo(self.contentView)
                make.height.equalTo(Knobs.cellHeight) //* Knobs.cellHeightMultiplier)
            }
            
            self.logoImageView.snp_remakeConstraints { (make) in
                self.logoImageView.isHidden = false
                make.centerY.equalTo(self.domainLabel)
                make.left.equalTo(self.displayView).inset(10)
                make.width.height.equalTo(30)
            }
            
			self.deleteButton.snp.remakeConstraints({ (make) in
                make.top.equalTo(self.displayView)
                make.right.equalTo(self.displayView)//.inset(10)
                make.width.height.equalTo(44.0)
            })
            
            self.domainLabel.snp_remakeConstraints { (make) in
                make.top.equalTo(self.displayView).inset(14)
                make.left.equalTo(self.logoImageView).offset(40.0)
                make.right.equalTo(self.deleteButton).inset(44.0)
                make.height.equalTo(30.0)
            }
            
			self.descriptionLabel.snp.remakeConstraints { (make) in
                self.descriptionLabel.isHidden = false
                make.top.equalTo(self.domainLabel.snp.bottom)
                make.left.right.equalTo(self.displayView).inset(10.0)
                make.height.equalTo(50.0)//54
            }
            
			self.bigLogoImageView.snp.remakeConstraints { (make) in
                make.top.equalTo(self.descriptionLabel.snp.bottom)
                make.left.right.bottom.equalTo(self.displayView).inset(10)
            }
            
			self.smallCenterImageView.snp.remakeConstraints { (make) in
                make.center.equalTo(self.bigLogoImageView)
                make.height.width.equalTo(80.0)//80
            }
            
            self.cliqzLogoImageView.snp_remakeConstraints({ (make) in
                make.center.equalTo(self.bigLogoImageView)
                make.left.right.equalTo(self.bigLogoImageView).inset(50)
            })
        }
        
        else {
            self.displayView.snp_remakeConstraints { (make) in
                self.showShadow(false)
                make.left.right.top.bottom.equalTo(self.contentView)
            }
            
			self.logoImageView.snp.remakeConstraints({ (make) in
				self.logoImageView.isHidden = true
			})
			
			self.deleteButton.snp.remakeConstraints({ (make) in
                make.top.equalTo(self.displayView)
                make.right.equalTo(self.displayView)//.inset(10)
                make.width.height.equalTo(44.0)
            })
            
			self.domainLabel.snp.remakeConstraints({ (make) in
                make.top.equalTo(self.displayView)
                make.left.equalTo(self.displayView).offset(10.0)
                make.right.equalTo(self.deleteButton).inset(44.0)
                make.height.equalTo(44.0)
            })
            
			self.descriptionLabel.snp.remakeConstraints({ (make) in
				self.descriptionLabel.isHidden = true
			})
			
			self.bigLogoImageView.snp.remakeConstraints { (make) in
                make.top.equalTo(self.domainLabel.snp.bottom)
                make.left.right.bottom.equalTo(self.displayView).inset(10)
            }
            
			self.smallCenterImageView.snp.remakeConstraints { (make) in
                make.center.equalTo(self.bigLogoImageView)
                make.height.width.equalTo(40.0)//80
            }
            self.cliqzLogoImageView.snp_remakeConstraints({ (make) in
                make.center.equalTo(self.bigLogoImageView)
                make.left.right.equalTo(self.bigLogoImageView).inset(50)
            })
        }
        
        
    }
    
 
    
    @objc
    func didPressDelete(sender: UIButton) {
		self.delegate?.removeTab(cell: self, swipe: .None)
    }
    
    func tapPressed(gestureRecognizer: UIGestureRecognizer) {
		let touchLocation = gestureRecognizer.location(in: self.displayView)
		
        if self.descriptionLabel.frame.contains(touchLocation) {
            clickedElement = "title"
        } else if self.domainLabel.frame.contains(touchLocation) {
            clickedElement = "url"
        } else if self.bigLogoImageView.frame.contains(touchLocation) {
            clickedElement = "logo"
        }
    }
    
    func handlePan(recognizer: UIPanGestureRecognizer) {
        
        let screenSize = UIScreen.main.bounds.size
        let isPortrait = screenSize.height > screenSize.width
        
        if !isPortrait{
            return
        }
        
        switch recognizer.state {
        case .changed:
			let translation = recognizer.translation(in: self.superview)
            let transform = displayView.layer.transform
            displayView.layer.transform = CATransform3DTranslate(transform, translation.x, 0, 0)
			recognizer.setTranslation(CGPoint.zero, in: displayView)
			
        case .cancelled, .ended:
            
			let velocity = recognizer.velocity(in: self)
			let aboveTreshold = abs(velocity.x) > self.velocityTreshold
			
			UIView.animate(withDuration: 0.3, animations: { () -> Void in
                if let transform = self.currentTransform {
                    let cellWidth = self.frame.width
                    if aboveTreshold {
                        let deltaX = velocity.x > 0 ? cellWidth : -cellWidth
                        self.displayView.layer.transform = CATransform3DTranslate(transform, deltaX, 0, 0)
                        self.alpha = 0.0
                    }
                    else {
                        self.displayView.layer.transform = transform
                    }
                }
                }, completion: { finished in
                    if finished && aboveTreshold {
						self.delegate?.removeTab(cell: self, swipe: velocity.x > 0 ? .Right : .Left)
                    }
            })
            
        default: break
        }
    }
    
}

extension TabViewCell: UIGestureRecognizerDelegate {
    
    // fix hard to scroll vertically
	override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
			let velocity = pan.velocity(in: displayView)
            return fabs(velocity.x) > fabs(velocity.y);
        }
        return true
    }
    
}
