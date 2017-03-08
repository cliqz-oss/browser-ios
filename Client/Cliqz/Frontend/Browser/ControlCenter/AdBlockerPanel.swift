//
//  AdBlockerPanel.swift
//  Client
//
//  Created by Mahmoud Adam on 12/29/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class AdBlockerPanel: AntitrackingPanel {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        secondViewTitleLabel.text = NSLocalizedString("AdBlocking Information", tableName: "Cliqz", comment: "AAdBlocking Information text for landscape mode.")
        if let label = toTableViewButton.subviews.first as? UILabel {
            label.text = NSLocalizedString("AdBlocking Information", tableName: "Cliqz", comment: "AdBlocking Information text for landscape mode.")
        }
    }
    
    //MARK: - Abstract methods implementation
    override func getPanelTitle() -> String {
        if isFeatureEnabled() && isFeatureEnabledForCurrentWebsite() {
            return NSLocalizedString("You surf the web without ads", tableName: "Cliqz", comment: "AdBlocker panel title in the control center when it is enabled.")
        } else {
            return NSLocalizedString("You surf the web with ads", tableName: "Cliqz", comment: "AdBlocker panel title in the control center when it is disabled.")
        }
    }
    
    override func getPanelSubTitle() -> String {
        if isFeatureEnabled() {
            if isFeatureEnabledForCurrentWebsite() {
                return NSLocalizedString("Ads have been blocked", tableName: "Cliqz", comment: "AdBlocker panel subtitle in the control center when it is enabled.")
            } else {
                return NSLocalizedString("Ad-Blocking is turned off for this website", tableName: "Cliqz", comment: "AdBlocker panel subtitle in the control center when it is disabled for the current website.")
            }
        } else {
            return NSLocalizedString("Ad-Blocking is turned off", tableName: "Cliqz", comment: "AdBlocker panel subtitle in the control center when it is disabled globally from settigns.")
        }
    }
    
    override func getPanelIcon() -> UIImage? {
        return UIImage(named: "AdBlockerIcon")
    }
    
    override func getLearnMoreURL() -> NSURL? {
        return NSURL(string: "https://cliqz.com/whycliqz/adblocking")
    }
    
    override func setupConstraints() {
        super.setupConstraints()
    }
    override func getThemeColor() -> UIColor {
        if isFeatureEnabled() && isFeatureEnabledForCurrentWebsite() {
            return enabledColor
        } else if isFeatureEnabled(){
            return partiallyDisabledColor
        }
        return disabledColor
    }
    override func isFeatureEnabled() -> Bool {
        return SettingsPrefs.getAdBlockerPref() //&& AdblockingModule.sharedInstance.isAdblockEnabled()
    }
    
    override func enableFeature() {
        SettingsPrefs.updateAdBlockerPref(true)
        self.updateView()
        self.setupConstraints()
        self.controlCenterPanelDelegate?.reloadCurrentPage()
        logTelemetrySignal("click", target: "activate", customData: nil)
    }
    
    override func isFeatureEnabledForCurrentWebsite() -> Bool {
        //INVESTIGATE
        if let urlString = self.currentURL.absoluteString {
            return isFeatureEnabled() && !AdblockingModule.sharedInstance.isUrlBlackListed(urlString)
        }
        return true
    }
    
    override func toggleFeatureForCurrentWebsite() {
        logDomainSwitchTelemetrySignal()
        AdblockingModule.sharedInstance.toggleUrl(self.currentURL)
        self.updateView()
        self.setupConstraints()
        self.controlCenterPanelDelegate?.reloadCurrentPage()
    }
    
    override func updateTrackers() {
        trackersList = AdblockingModule.sharedInstance.getAdBlockingStatistics(self.currentURL)
        trackersCount = trackersList.reduce(0){$0 + $1.1}
    }
    
    override func getViewName() -> String {
        return "adblock"
    }
    
    override func getAdditionalInfoName() -> String {
        return "info_ad"
    }
    
}
