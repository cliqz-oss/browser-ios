//
//  OffrzViewController.swift
//  Client
//
//  Created by Sahakyan on 12/5/17.
//  Copyright © 2017 Cliqz. All rights reserved.
//

import Foundation

class OffrzViewController: UIViewController {
    private var scrollView = UIScrollView()
    private var containerView = UIView()
    private var onboardingView = UIView()
    private let offrzPresentImageView = UIImageView(image: UIImage(named: "offrz_present"))
    private let offerzLabel = UILabel()
    
    weak var offrzDataSource : OffrzDataSource!
    
    init(profile: Profile) {
        super.init(nibName: nil, bundle: nil)
        self.offrzDataSource = profile.offrzDataSource
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
		super.viewDidLoad()
//        OffrzDataService.shared.getMyOffrz { (offrz, error) in
//            print("Hello ---- \(offrz)")
//        }
        setStyles()
        setupComponents()
        
	}
    
    private func setStyles() {
        self.view.backgroundColor = UIConstants.AppBackgroundColor
        containerView.backgroundColor = UIColor.clear
    }
    
    private func setupComponents() {
        
        self.view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(offrzPresentImageView)
        containerView.addSubview(offerzLabel)
        offerzLabel.text = NSLocalizedString("Here you'll find a new offer every week", tableName: "Cliqz", comment: "[MyOffrz] No offers label")
        offerzLabel.textColor = UIColor.gray
        
        remakeConstaints()
        setupOnboardingView()
    }
    
    private func setupOnboardingView() {
        guard offrzDataSource.hasOffrz() && offrzDataSource.shouldShowOnBoarding() else { return }
        
        onboardingView.backgroundColor = UIColor(colorString: "ABD8EA")
        containerView.addSubview(onboardingView)

        // Components
        let hideButton = UIButton(type: .custom)
        hideButton.setImage(UIImage(named: "closeTab"), for: .normal)
        hideButton.addTarget(self, action: #selector(hideOnboardingView) , for: .touchUpInside)
        onboardingView.addSubview(hideButton)
        
        
        onboardingView.addSubview(offrzPresentImageView)
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = NSLocalizedString("Receive attractive discounts and bargains with MyOffrz", tableName: "Cliqz", comment: "[MyOffrz] MyOffrz description")
        descriptionLabel.textColor = UIColor.gray
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 2
        onboardingView.addSubview(descriptionLabel)
        
        let moreButton = UIButton(type: .custom)
        moreButton.setTitle(NSLocalizedString("LEARN MORE", tableName: "Cliqz", comment: "[MyOffrz] Learn more button title"), for: .normal)
        moreButton.setTitleColor(UIColor.blue, for: .normal)
        onboardingView.addSubview(moreButton)
        
        // Constraints
        hideButton.snp.makeConstraints { (make) in
            make.top.right.equalTo(onboardingView).inset(10)
        }
        offrzPresentImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(onboardingView)
            make.top.equalTo(onboardingView).inset(10)
        }
        descriptionLabel.snp.makeConstraints { (make) in
            make.right.left.equalTo(onboardingView).inset(25)
            make.top.equalTo(offrzPresentImageView.snp.bottom).offset(10)
        }
        moreButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(onboardingView)
            make.bottom.equalTo(onboardingView)
        }
    }
    
    @objc private func hideOnboardingView() {
        self.onboardingView.removeFromSuperview()
        self.offrzDataSource?.hideOnBoarding()
    }
    
    private func remakeConstaints() {
        self.scrollView.snp.remakeConstraints({ (make) in
            make.top.left.bottom.right.equalTo(self.view)
        })
        
        self.containerView.snp.remakeConstraints({ (make) in
            make.top.left.bottom.right.equalTo(scrollView)
            make.height.width.equalTo(self.view)
        })
        
        if offrzDataSource.hasOffrz() {
            if offrzDataSource.shouldShowOnBoarding() {
                self.onboardingView.snp.remakeConstraints({ (make) in
                    make.top.left.right.equalTo(containerView)
                    make.height.equalTo(175)
                })
            }
        } else {
            offrzPresentImageView.snp.remakeConstraints({ (make) in
                make.center.equalTo(containerView)
            })
            offerzLabel.snp.remakeConstraints({ (make) in
                make.centerX.equalTo(containerView)
                make.top.equalTo(offrzPresentImageView.snp.bottom).offset(10)
            })
        }
    }
}
