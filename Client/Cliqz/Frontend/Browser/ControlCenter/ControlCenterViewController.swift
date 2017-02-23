//
//  ControlCenterViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 12/27/16.
//  Copyright © 2016 CLIQZ. All rights reserved.
//

import UIKit

//TODO: Localization & Telemetry
protocol ControlCenterViewDelegate: class {
    
    func controlCenterViewWillClose(antitrackingView: UIView)
    func reloadCurrentPage()
    
}

class ControlCenterViewController: UIViewController {
    
    //MARK: - Constants
    private let controlCenterThemeColor = UIConstants.CliqzThemeColor
    private let urlBarHeight: CGFloat = 40.0
    
    //MARK: - Private variables
    //MARK: Views
    private var blurryBackgroundView: UIVisualEffectView!
    private var backgroundView: UIView!
    private var panelSegmentedControl: UISegmentedControl!
    private var panelSegmentedSeparator = UIView()
    private var panelSegmentedContainerView = UIView()
    private var panelContainerView = UIView()
    
    //MARK: data
    private let trackedWebViewID: Int!
    private let isPrivateMode: Bool!
    private var currentURl: NSURL!
    
    
    //MARK: panels
    private lazy var antitrackingPanel: AntitrackingPanel = {
        let antitrackingPanel = AntitrackingPanel(webViewID: self.trackedWebViewID, url: self.currentURl, privateMode: self.isPrivateMode)
        antitrackingPanel.controlCenterPanelDelegate = self
        antitrackingPanel.delegate = self.delegate
        return antitrackingPanel
    }()
    
    private lazy var adBlockerPanel: AdBlockerPanel = {
        let adBlockerPanel = AdBlockerPanel(webViewID: self.trackedWebViewID, url: self.currentURl, privateMode: self.isPrivateMode)
        adBlockerPanel.controlCenterPanelDelegate = self
        adBlockerPanel.delegate = self.delegate
        return adBlockerPanel
    }()
    
    private lazy var antiPhishingPanel: AntiPhishingPanel = {
        let antiPhishingPanel = AntiPhishingPanel(webViewID: self.trackedWebViewID, url: self.currentURl, privateMode: self.isPrivateMode)
        antiPhishingPanel.controlCenterPanelDelegate = self
        antiPhishingPanel.delegate = self.delegate
        return antiPhishingPanel
    }()

    //MARK: Delegates
    weak var controlCenterDelegate: ControlCenterViewDelegate? = nil
    weak var delegate: BrowserNavigationDelegate? = nil

    //MARK: - Init
    init(webViewID: Int, url: NSURL, privateMode: Bool = false) {
        trackedWebViewID = webViewID
        isPrivateMode = privateMode
        self.currentURl = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    //MARK: - View LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Background
        let blurEffect = UIBlurEffect(style: .Light)
        self.blurryBackgroundView = UIVisualEffectView(effect: blurEffect)
        self.view.insertSubview(blurryBackgroundView, atIndex: 0)
        
        self.backgroundView = UIView()
        self.backgroundView.backgroundColor = self.backgroundColor().colorWithAlphaComponent(0.8)
        self.view.addSubview(self.backgroundView)
        
        // Segmented control
        panelSegmentedContainerView.backgroundColor = UIConstants.AppBackgroundColor
        view.addSubview(panelSegmentedContainerView)
        
        let antiTrakcingTitle = NSLocalizedString("Anti-Tracking", tableName: "Cliqz", comment: "Anti-Trakcing panel name on control center.")
        let adBlockingTitle = NSLocalizedString("Ad-Blocking", tableName: "Cliqz", comment: "Ad-Blocking panel name on control center.")
        let antiPhishingTitle = NSLocalizedString("Anti-Phishing", tableName: "Cliqz", comment: "Anti-Phishing panel name on control center.")
        
        panelSegmentedControl = UISegmentedControl(items: [antiTrakcingTitle, adBlockingTitle, antiPhishingTitle])
        panelSegmentedControl.tintColor = self.controlCenterThemeColor
        panelSegmentedControl.addTarget(self, action: #selector(switchPanel), forControlEvents: .ValueChanged)
        self.panelSegmentedControl.selectedSegmentIndex = 0
        
        panelSegmentedContainerView.addSubview(panelSegmentedControl)

        panelSegmentedSeparator.backgroundColor = UIColor(rgb: 0xB1B1B1)
        panelSegmentedContainerView.addSubview(panelSegmentedSeparator)

        view.addSubview(panelContainerView)
        
        // Close tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapRecognizer))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.switchPanel(self.panelSegmentedControl)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.setupConstraints()
    }

    //MARK: - Helper methods
    
    private func setupConstraints() {
        
        
        let panelLayout = OrientationUtil.controlPanelLayout()
        
        if panelLayout != .LandscapeRegularSize {
            blurryBackgroundView.snp_makeConstraints { (make) in
                make.left.right.bottom.equalTo(self.view)
                make.top.equalTo(self.view).offset(urlBarHeight)
            }
            backgroundView.snp_makeConstraints { (make) in
                make.left.right.bottom.equalTo(self.view)
                make.top.equalTo(self.view).offset(urlBarHeight)
            }
            
            panelSegmentedContainerView.snp_makeConstraints { make in
                make.left.right.equalTo(self.view)
                make.top.equalTo(self.view).offset(urlBarHeight)
                make.height.equalTo(45)
            }
            panelSegmentedControl.snp_makeConstraints { make in
                make.centerY.equalTo(panelSegmentedContainerView)
                make.left.equalTo(panelSegmentedContainerView).offset(10)
                make.right.equalTo(panelSegmentedContainerView).offset(-10)
                make.height.equalTo(30)
            }
            panelContainerView.snp_makeConstraints { make in
                make.top.equalTo(self.panelSegmentedContainerView.snp_bottom).offset(10)
                make.left.right.bottom.equalTo(self.view)
            }
            panelSegmentedSeparator.snp_makeConstraints { make in
                make.left.equalTo(panelSegmentedContainerView)
                make.width.equalTo(panelSegmentedContainerView)
                make.bottom.equalTo(panelSegmentedContainerView)
                make.height.equalTo(1)
            }
        }
        else
        {
            backgroundView.snp_makeConstraints { (make) in
                make.left.right.bottom.equalTo(self.view)
                make.top.equalTo(self.view).offset(urlBarHeight)
            }
            
            panelSegmentedContainerView.snp_makeConstraints { make in
                make.left.right.equalTo(self.view)
                make.top.equalTo(self.view).offset(urlBarHeight)
                make.height.equalTo(45)
            }
            panelSegmentedControl.snp_makeConstraints { make in
                make.centerY.equalTo(panelSegmentedContainerView)
                make.left.equalTo(panelSegmentedContainerView).offset(10)
                make.right.equalTo(panelSegmentedContainerView).offset(-10)
                make.height.equalTo(30)
            }
            panelContainerView.snp_makeConstraints { make in
                make.top.equalTo(self.panelSegmentedContainerView.snp_bottom).offset(10)
                make.left.right.bottom.equalTo(self.view)
            }
            panelSegmentedSeparator.snp_makeConstraints { make in
                make.left.equalTo(panelSegmentedContainerView)
                make.width.equalTo(panelSegmentedContainerView)
                make.bottom.equalTo(panelSegmentedContainerView)
                make.height.equalTo(1)
            }
        }
        
    }
    
    private func backgroundColor() -> UIColor {
        if self.isPrivateMode == true {
            return UIColor(rgb: 0x222222)
        }
        return UIColor(rgb: 0xE8E8E8)
    }
    
    @objc private func tapRecognizer(sender: UITapGestureRecognizer) {
        let p = sender.locationInView(self.view)
        if p.y <= urlBarHeight {
            closeControlCenter()
        }
    }

    //MARK: Switching panels
    @objc private func switchPanel(sender: UISegmentedControl) {
        self.hideCurrentPanelViewController()
        
        switch sender.selectedSegmentIndex {
        case 0:
            self.showPanelViewController(self.antitrackingPanel)
        case 1:
            self.showPanelViewController(self.adBlockerPanel)
        case 2:
            self.showPanelViewController(self.antiPhishingPanel)
        default:
            break
        }
    }
    
    private func showPanelViewController(viewController: UIViewController) {
        addChildViewController(viewController)
        self.panelContainerView.addSubview(viewController.view)
        viewController.view.snp_makeConstraints { make in
            make.top.left.right.bottom.equalTo(self.panelContainerView)
        }
        viewController.didMoveToParentViewController(self)
    }
    
    private func hideCurrentPanelViewController() {
        if let panel = childViewControllers.first {
            panel.willMoveToParentViewController(nil)
            panel.view.removeFromSuperview()
            panel.removeFromParentViewController()
        }
    }
    
}

//MARK: - ControlCenterPanelDelegate

extension ControlCenterViewController : ControlCenterPanelDelegate {
    
    func closeControlCenter() {
        
        let panelLayout = OrientationUtil.controlPanelLayout()
        
        self.controlCenterDelegate?.controlCenterViewWillClose(self.view)
        
        if panelLayout != .LandscapeRegularSize {
            UIView.animateWithDuration(0.2, animations: {
                var p = self.view.center
                p.y -= self.view.frame.size.height
                self.view.center = p
            }) { (finished) in
                if finished {
                    self.view.removeFromSuperview()
                    self.removeFromParentViewController()
                }
            }
        }
        else{
            UIView.animateWithDuration(0.08, animations: {
                self.view.frame.origin.x = self.view.frame.origin.x + self.view.frame.size.width
            }) { (finished) in
                if finished {
                    self.view.removeFromSuperview()
                    self.removeFromParentViewController()
                }
            }
        }
        
        
    }
    
    func reloadCurrentPage() {
        self.controlCenterDelegate?.reloadCurrentPage()
    }
}
