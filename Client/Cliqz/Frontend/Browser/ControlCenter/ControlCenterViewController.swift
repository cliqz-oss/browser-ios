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
	
    func controlCenterViewWillClose(_ antitrackingView: UIView)
    func reloadCurrentPage()

}

class ControlCenterViewController: UIViewController {
	
    //MARK: - Constants
    fileprivate let controlCenterThemeColor = UIConstants.CliqzThemeColor
    fileprivate let urlBarHeight: CGFloat = 40.0
	
    //MARK: - Variables
    internal var visible = false
	
    //MARK: Views
    fileprivate var blurryBackgroundView: UIVisualEffectView!
    fileprivate var backgroundView: UIView!
    fileprivate var panelSegmentedControl: UISegmentedControl!
    fileprivate var panelSegmentedSeparator = UIView()
    fileprivate var panelSegmentedContainerView = UIView()
    fileprivate var panelContainerView = UIView()
	
    //MARK: data
    fileprivate let trackedWebViewID: Int!
    fileprivate let isPrivateMode: Bool!
    fileprivate var currentURl: URL!
	
    
    //MARK: panels
    fileprivate lazy var antitrackingPanel: AntitrackingPanel = {
		// Temporary changing forget mode design for Control Center
        let antitrackingPanel = AntitrackingPanel(webViewID: self.trackedWebViewID, url: self.currentURl, privateMode: false)
        antitrackingPanel.controlCenterPanelDelegate = self
        antitrackingPanel.delegate = self.delegate
        return antitrackingPanel
    }()
	
    fileprivate lazy var adBlockerPanel: AdBlockerPanel = {
		// Temporary changing forget mode design for Control Center
        let adBlockerPanel = AdBlockerPanel(webViewID: self.trackedWebViewID, url: self.currentURl, privateMode: false)
        adBlockerPanel.controlCenterPanelDelegate = self
        adBlockerPanel.delegate = self.delegate
        return adBlockerPanel
    }()
	
    fileprivate lazy var antiPhishingPanel: AntiPhishingPanel = {
		// Temporary changing forget mode design for Control Center
        let antiPhishingPanel = AntiPhishingPanel(webViewID: self.trackedWebViewID, url: self.currentURl, privateMode: false)
        antiPhishingPanel.controlCenterPanelDelegate = self
        antiPhishingPanel.delegate = self.delegate
        return antiPhishingPanel
    }()

    //MARK: Delegates
    weak var controlCenterDelegate: ControlCenterViewDelegate? = nil
    weak var delegate: BrowserNavigationDelegate? = nil

    //MARK: - Init
    init(webViewID: Int, url: URL, privateMode: Bool = false) {
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
		let blurEffect = UIBlurEffect(style: .light)
        self.blurryBackgroundView = UIVisualEffectView(effect: blurEffect)
		self.view.insertSubview(blurryBackgroundView, at: 0)
		// Hack to change blurriness color of the background according to the design requirment. UIVisualEffectView doesn't provide API to change the color, it assigns default grey color, but we need white.
		for i in self.blurryBackgroundView.subviews {
			if i.backgroundColor != nil {
				i.backgroundColor = self.backgroundColor().withAlphaComponent(0.7)
			}
		}

        self.backgroundView = UIView()
        self.backgroundView.backgroundColor =  UIColor.clear
        self.view.addSubview(self.backgroundView)

        // Segmented control
        panelSegmentedContainerView.backgroundColor = self.controlCenterThemeColor
        self.view.addSubview(panelSegmentedContainerView)
        
        let antiTrakcingTitle = NSLocalizedString("Anti-Tracking", tableName: "Cliqz", comment: "Anti-Trakcing panel name on control center.")
        let adBlockingTitle = NSLocalizedString("Ad-Blocking", tableName: "Cliqz", comment: "Ad-Blocking panel name on control center.")
        let antiPhishingTitle = NSLocalizedString("Anti-Phishing", tableName: "Cliqz", comment: "Anti-Phishing panel name on control center.")
        
        panelSegmentedControl = UISegmentedControl(items: [antiTrakcingTitle, adBlockingTitle, antiPhishingTitle])
        panelSegmentedControl.tintColor = UIColor.white
		panelSegmentedControl.backgroundColor = self.controlCenterThemeColor
        panelSegmentedControl.addTarget(self, action: #selector(switchPanel), for: .valueChanged)
        self.panelSegmentedControl.selectedSegmentIndex = 0
        
        panelSegmentedContainerView.addSubview(panelSegmentedControl)

        panelSegmentedSeparator.backgroundColor = UIColor(rgb: 0xB1B1B1)
        panelSegmentedContainerView.addSubview(panelSegmentedSeparator)

        view.addSubview(panelContainerView)
		
		// Temporary changing forget mode design for Control Center
		/*
        if let privateMode = self.isPrivateMode, privateMode == true {
            panelSegmentedContainerView.backgroundColor = self.backgroundColor().withAlphaComponent(0.0)
        } */
		
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isPrivateMode {
            self.panelSegmentedSeparator.isHidden = true
        }
        else {
            self.panelSegmentedSeparator.isHidden = false
        }
        self.showPanelViewController(self.antitrackingPanel)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.setupConstraints()
    }

    //MARK: - Helper methods
    
    fileprivate func setupConstraints() {
        
        
        let panelLayout = OrientationUtil.controlPanelLayout()
		blurryBackgroundView.snp.makeConstraints { (make) in
			make.left.right.bottom.equalTo(self.view)
			make.top.equalTo(self.view)
		}

        if panelLayout != .landscapeRegularSize {
            backgroundView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalTo(self.view)
                make.top.equalTo(self.view)
            }
            
            panelSegmentedContainerView.snp.makeConstraints { make in
                make.left.right.equalTo(self.view)
                make.top.equalTo(self.view)
                make.height.equalTo(45)
            }
            panelSegmentedControl.snp.makeConstraints { make in
                make.centerY.equalTo(panelSegmentedContainerView)
                make.left.equalTo(panelSegmentedContainerView).offset(10)
                make.right.equalTo(panelSegmentedContainerView).offset(-10)
                make.height.equalTo(30)
            }
            panelContainerView.snp.makeConstraints { make in
                make.top.equalTo(self.panelSegmentedContainerView.snp.bottom).offset(10)
                make.left.right.bottom.equalTo(self.view)
            }
            panelSegmentedSeparator.snp.makeConstraints { make in
                make.left.equalTo(panelSegmentedContainerView)
                make.width.equalTo(panelSegmentedContainerView)
                make.bottom.equalTo(panelSegmentedContainerView)
                make.height.equalTo(1)
            }
        }
        else
        {
            backgroundView.snp.makeConstraints { (make) in
                make.top.left.right.bottom.equalTo(self.view)
            }
            
            panelSegmentedContainerView.snp.makeConstraints { make in
                make.left.right.equalTo(self.view)
                make.top.equalTo(self.view)
                make.height.equalTo(45)
            }
            panelSegmentedControl.snp.makeConstraints { make in
                make.centerY.equalTo(panelSegmentedContainerView)
                make.left.equalTo(panelSegmentedContainerView).offset(10)
                make.right.equalTo(panelSegmentedContainerView).offset(-10)
                make.height.equalTo(30)
            }
            panelContainerView.snp.makeConstraints { make in
                make.top.equalTo(self.panelSegmentedContainerView.snp.bottom).offset(10)
                make.left.right.bottom.equalTo(self.view)
            }
            panelSegmentedSeparator.snp.makeConstraints { make in
                make.left.equalTo(panelSegmentedContainerView)
                make.width.equalTo(panelSegmentedContainerView)
                make.bottom.equalTo(panelSegmentedContainerView)
                make.height.equalTo(1)
            }
        }
        
    }
    
    fileprivate func backgroundColor() -> UIColor {
        if self.isPrivateMode == true {
			// Temporary changing forget mode design for Control Center
            return UIColor.white //UIColor(rgb: 0x222222)
        }
        return UIColor.white
    }

    //MARK: Switching panels
    @objc fileprivate func switchPanel(_ sender: UISegmentedControl) {
        self.hideCurrentPanelViewController()
        var newPanel: ControlCenterPanel?
        
        switch sender.selectedSegmentIndex {
        case 0:
            newPanel = self.antitrackingPanel
        case 1:
            newPanel = self.adBlockerPanel
        case 2:
            newPanel = self.antiPhishingPanel
        default:
            break
        }
        if let panel = newPanel {
            TelemetryLogger.sharedInstance.logEvent(.ControlCenter("click", nil, panel.getViewName(), nil))
            self.showPanelViewController(panel)
        }
    }
    
    fileprivate func showPanelViewController(_ viewController: UIViewController) {
        addChildViewController(viewController)
        self.panelContainerView.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { make in
            make.top.left.right.bottom.equalTo(self.panelContainerView)
        }
        viewController.didMove(toParentViewController: self)
    }
    
    fileprivate func hideCurrentPanelViewController() {
        if let panel = childViewControllers.first {
            panel.willMove(toParentViewController: nil)
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
        
        if panelLayout != .landscapeRegularSize {
            UIView.animate(withDuration: 0.2, animations: {
                var p = self.view.center
                p.y -= self.view.frame.size.height
                self.view.center = p
            }, completion: { (finished) in
                if finished {
                    self.view.removeFromSuperview()
                    self.removeFromParentViewController()
                }
            }) 
        }
        else{
            UIView.animate(withDuration: 0.08, animations: {
                self.view.frame.origin.x = self.view.frame.origin.x + self.view.frame.size.width
            }, completion: { (finished) in
                if finished {
                    self.view.removeFromSuperview()
                    self.removeFromParentViewController()
                }
            }) 
        }
        
        
    }
	
    func reloadCurrentPage() {
        self.controlCenterDelegate?.reloadCurrentPage()
    }
}
