//
//  AdBlockerPanel.swift
//  Client
//
//  Created by Mahmoud Adam on 12/29/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class AdBlockerPanel: AntitrackingPanel {
    
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
        } else {
            return disabledColor
        }
    }
    override func isFeatureEnabled() -> Bool {
        return AdblockingModule.sharedInstance.isAdblockEnabled()
    }
    
    override func enableFeature() {
        AdblockingModule.sharedInstance.setAdblockEnabled(true)
        SettingsPrefs.updateAdBlockerPref(true)
        self.updateView()
        self.setupConstraints()
        self.controlCenterPanelDelegate?.reloadCurrentPage()
    }
    
    override func isFeatureEnabledForCurrentWebsite() -> Bool {
        if let urlString = self.currentURL.absoluteString {
            return AdblockingModule.sharedInstance.isUrlBlackListed(urlString)
        }
        return false
    }
    
    override func toggleFeatureForCurrentWebsite() {
        AdblockingModule.sharedInstance.toggleUrl(self.currentURL)
        self.updateView()
        self.setupConstraints()
        self.controlCenterPanelDelegate?.reloadCurrentPage()
    }
    
    override func updateTrackers() {
        trackersList = AdblockingModule.sharedInstance.getAdBlockingStatistics(self.currentURL)
        trackersCount = trackersList.reduce(0){$0 + $1.1}
    }
}
