//
//  OffrzViewController.swift
//  Client
//
//  Created by Sahakyan on 12/5/17.
//  Copyright © 2017 Cliqz. All rights reserved.
//

import Foundation

class OffrzViewController: UIViewController {

	weak var delegate: BrowsingDelegate?

    private var scrollView = UIScrollView()
    private var containerView = UIView()
    private var onboardingView = UIView()
    private let offrzPresentImageView = UIImageView(image: UIImage(named: "offrz_present"))
    private let offrzLabel = UILabel()
	private static let learnMoreURL = "https://cliqz.com/myoffrz"
    private var offrView: OffrView?
	private var myOffr: Offr?
	private let offrHeight: CGFloat = 510

	private var offrOverlay: UIView?

    weak var offrzDataSource : OffrzDataSource!

	private var startDate = Date()

    init(profile: Profile) {
        super.init(nibName: nil, bundle: nil)
        self.offrzDataSource = profile.offrzDataSource
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
		super.viewDidLoad()
        setStyles()
        setupComponents()
        
        if self.offrzDataSource.hasOffrz() {
            self.offrzDataSource.markCurrentOffrSeen()
        }
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.startDate = Date()
		TelemetryLogger.sharedInstance.logEvent(.Toolbar("show", nil, "offrz", nil, ["offer_count": self.offrzDataSource.hasOffrz() ? 1 : 0]))
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		TelemetryLogger.sharedInstance.logEvent(.Toolbar("hide", nil, "offrz", nil, ["show_duration": Date().timeIntervalSince(self.startDate)]))
	}

    private func setStyles() {
        self.view.backgroundColor = UIConstants.AppBackgroundColor
        containerView.backgroundColor = UIColor.clear
    }
    
    private func setupComponents() {
        
        self.view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(onboardingView)
        if offrzDataSource.hasOffrz(), let currentOffr = offrzDataSource.getCurrentOffr() {
			self.myOffr = currentOffr
            offrView = OffrView(offr: currentOffr)
            containerView.addSubview(offrView!)
			offrView?.addTapAction(self, action: #selector(openOffr))
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(expandOffr))
			offrView?.addGestureRecognizer(tapGesture)
        } else {
            containerView.addSubview(offrzPresentImageView)
            containerView.addSubview(offrzLabel)
            offrzLabel.text = NSLocalizedString("MyOffrz Empty Description", tableName: "Cliqz", comment: "[MyOffrz] No offers label")
            offrzLabel.textColor = UIColor.gray
        }
        
        setupOnboardingView()
		remakeConstaints(true)
    }
    
    private func setupOnboardingView() {
        guard offrzDataSource.hasOffrz() && offrzDataSource.shouldShowOnBoarding() else {
            onboardingView.removeFromSuperview()
            return
        }
        TelemetryLogger.sharedInstance.logEvent(.Onboarding("show", "offrz", nil))
        onboardingView.backgroundColor = UIColor(colorString: "ABD8EA")
        containerView.addSubview(onboardingView)

        // Components
        let hideButton = UIButton(type: .custom)
        hideButton.setImage(UIImage(named: "closeTab"), for: .normal)
        hideButton.addTarget(self, action: #selector(hideOnboardingView) , for: .touchUpInside)
        onboardingView.addSubview(hideButton)
        onboardingView.addSubview(offrzPresentImageView)

        let descriptionLabel = UILabel()
        descriptionLabel.text = NSLocalizedString("MyOffrz Onboarding", tableName: "Cliqz", comment: "[MyOffrz] MyOffrz description")
        descriptionLabel.textColor = UIColor.gray
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 2
        onboardingView.addSubview(descriptionLabel)

        let moreButton = UIButton(type: .custom)
        moreButton.setTitle(NSLocalizedString("LEARN MORE", tableName: "Cliqz", comment: "[MyOffrz] Learn more button title"), for: .normal)
        moreButton.setTitleColor(UIConstants.CliqzThemeColor, for: .normal)
		moreButton.addTarget(self, action: #selector(openLearnMore), for: .touchUpInside)
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
		TelemetryLogger.sharedInstance.logEvent(.Onboarding("hide", nil, ["view" : "offrz"]))
        self.onboardingView.removeFromSuperview()
        self.offrzDataSource?.hideOnBoarding()
		self.remakeConstaints(false)
    }
    
	private func remakeConstaints(_ withOnboarding: Bool) {
        self.scrollView.snp.remakeConstraints({ (make) in
            make.top.left.bottom.right.equalTo(self.view)
        })
        
        self.containerView.snp.remakeConstraints({ (make) in
            make.top.left.right.bottom.equalTo(scrollView)
            make.width.equalTo(self.view)
			if withOnboarding && offrzDataSource.shouldShowOnBoarding() {
				make.height.equalTo(offrHeight + 200)
			} else {
				make.height.equalTo(offrHeight + 30)
			}
        })

        if offrzDataSource.hasOffrz() {
            if withOnboarding && offrzDataSource.shouldShowOnBoarding() {
                self.onboardingView.snp.remakeConstraints({ (make) in
                    make.top.left.right.equalTo(containerView)
                    make.height.equalTo(175)
                })
            }
            if let offrView = self.offrView {
                offrView.snp.remakeConstraints({ (make) in
                    if withOnboarding && offrzDataSource.shouldShowOnBoarding() {
                        make.top.equalTo(onboardingView.snp.bottom).offset(25)
                    } else {
                        make.top.equalTo(containerView).offset(25)
                    }
                    make.left.equalTo(containerView).offset(50)
					make.right.equalTo(containerView).offset(-50)
                    make.height.equalTo(offrHeight)
                })
            }
            
        } else {
            offrzPresentImageView.snp.remakeConstraints({ (make) in
                make.centerX.equalTo(containerView)
                make.centerY.equalTo(containerView).dividedBy(2)
            })
            offrzLabel.snp.remakeConstraints({ (make) in
                make.centerX.equalTo(containerView)
                make.top.equalTo(offrzPresentImageView.snp.bottom).offset(10)
            })
        }
    }

	@objc
	private func openLearnMore() {
		TelemetryLogger.sharedInstance.logEvent(.Onboarding("click", nil, ["view" : "offrz"]))
		if let url = URL(string: OffrzViewController.learnMoreURL) {
			self.delegate?.didSelectURL(url)
		}
	}

	@objc
	private func openOffr() {
		if self.offrOverlay != nil {
			self.shrinkOffr()
		}
		TelemetryLogger.sharedInstance.logEvent(.MyOffrz("click", "use"))
		if let urlStr = self.myOffr?.url,
			let url = URL(string: urlStr) {
			self.delegate?.didSelectURL(url)
		}
	}

	@objc
	private func expandOffr() {
		if let w = getApp().window,
			let offr = self.myOffr {
			let overlay = UIView()
			overlay.backgroundColor = UIColor.clear
			w.addSubview(overlay)
			overlay.snp.remakeConstraints({ (make) in
				make.top.left.right.bottom.equalTo(w)
			})

			let blurEffect = UIBlurEffect(style: .dark)
			let blurView = UIVisualEffectView(effect: blurEffect)
			overlay.addSubview(blurView)
			blurView.snp.makeConstraints({ (make) in
				make.top.left.right.bottom.equalTo(overlay)
			})
			let expandedOffrView = OffrView(offr: offr)
			overlay.addSubview(expandedOffrView)
			expandedOffrView.expand()
			expandedOffrView.snp.makeConstraints({ (make) in
					make.top.equalTo(overlay).offset(45)
					make.bottom.equalTo(overlay).offset(-25)
					make.left.right.equalTo(overlay).inset(50)
			})
			expandedOffrView.addTapAction(self, action: #selector(openOffr))
			self.offrOverlay = overlay

			let closeBtn = UIButton(type: .custom)
			closeBtn.setBackgroundImage(UIImage(named:"closeOffr"), for: .normal)
			overlay.addSubview(closeBtn)
			closeBtn.snp.makeConstraints({ (make) in
				make.top.equalTo(overlay).offset(40)
				make.left.equalTo(overlay).offset(45)
			})
			closeBtn.addTarget(self, action: #selector(self.shrinkOffr), for: .touchUpInside)
		}
	}

	@objc
	private func shrinkOffr() {
		self.offrOverlay?.removeFromSuperview()
		self.offrOverlay = nil
	}
}
