/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import Account

/// App Settings Screen (triggered by tapping the 'Gear' in the Tab Tray Controller)
class AppSettingsTableViewController: SettingsTableViewController {
    fileprivate let SectionHeaderIdentifier = "SectionHeaderIdentifier"

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Settings", comment: "Settings")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"),
            style: UIBarButtonItemStyle.done,
            target: navigationController, action: Selector("SELdone"))
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "AppSettingsTableViewController.navigationItem.leftBarButtonItem"

        tableView.accessibilityIdentifier = "AppSettingsTableViewController.tableView"
        
        // Cliqz: Add observers for Connection features
        NotificationCenter.default.addObserver(self, selector: #selector(dismissView), name: ShowBrowserViewControllerNotification, object: nil)

    }
    
    deinit {
        // Cliqz: removed observers for Connect features
        NotificationCenter.default.removeObserver(self, name: ShowBrowserViewControllerNotification, object: nil)
        
    }
    
    // Called when send tab notification sent from Connect while dashboard is presented
    func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }

    // Cliqz: Redesign Settings
    override func generateSettings() -> [SettingSection] {
        
        let prefs = profile.prefs
        
        // Search settings Section
        let regionalSetting                 = RegionalSetting(settings: self)
        let querySuggestionSettings         = BoolSetting(prefs: prefs, prefKey: SettingsPrefs.querySuggestionPrefKey, defaultValue: SettingsPrefs.getQuerySuggestionPref(),
                                                          titleText: NSLocalizedString("Search Query Suggestions", tableName: "Cliqz", comment: "[Settings] Search Query Suggestions"))
        let blockExplicitContentSettings    = BoolSetting(prefs: prefs, prefKey: SettingsPrefs.BlockExplicitContentPrefKey, defaultValue: SettingsPrefs.getBlockExplicitContentPref(),
                                                          titleText: NSLocalizedString("Block Explicit Content", tableName: "Cliqz", comment: "[Settings] Block explicit content"))
        let humanWebSetting                 = HumanWebSetting(settings: self)
        let cliqzSearchSetting              = CliqzSearchSetting(settings: self)
        

        var searchSection: [Setting]!
        if QuerySuggestions.querySuggestionEnabledForCurrentRegion() {
            searchSection = [regionalSetting, querySuggestionSettings, blockExplicitContentSettings, humanWebSetting, cliqzSearchSetting]
        } else {
            searchSection = [regionalSetting, blockExplicitContentSettings, humanWebSetting, cliqzSearchSetting]
        }
        
        
        // Browsing & History Section
        let connectSetting              = CliqzConnectSetting(settings: self)
        let blockPopupsSetting          = BoolSetting(prefs: prefs, prefKey: SettingsPrefs.blockPopupsPrefKey, defaultValue: true, titleText: NSLocalizedString("Block Pop-up Windows", tableName: "Cliqz", comment: " [Settings] Block pop-up windows"))
        let autoForgetTabSetting        = AutoForgetTabSetting(settings: self)
        let limitMobileDataUsageSetting = LimitMobileDataUsageSetting(settings: self)
        let adBlockerSetting            = AdBlockerSetting(settings: self)
        let clearPrivateDataSetting     = ClearPrivateDataSetting(settings: self)
        let restoreTopSitesSetting      = RestoreTopSitesSetting(settings: self)
        let resetSubscriptionsSetting   = ResetSubscriptionsSetting(settings: self)
        
        var browsingAndHistorySection = [Setting]()
        
        if ConnectManager.sharedInstance.isDeviceSupported() {
            browsingAndHistorySection += [connectSetting]
        }
        
        browsingAndHistorySection += [blockPopupsSetting, autoForgetTabSetting, limitMobileDataUsageSetting, adBlockerSetting, clearPrivateDataSetting, restoreTopSitesSetting, resetSubscriptionsSetting]
        
#if React_Debug
        browsingAndHistorySection += [TestReact(settings: self)]
#endif
        // Cliqz: temporarly hide news notification settings
//            EnablePushNotifications(prefs: prefs, prefKey: "enableNewsPushNotifications", defaultValue: false,
//				titleText: NSLocalizedString("Enable News Push Notifications", tableName: "Cliqz", comment: "Enable News Push Notifications"))

        // Cliqz Tab section
        let showTopSitesSetting          = BoolSetting(prefs: prefs, prefKey: SettingsPrefs.ShowTopSitesPrefKey, defaultValue: true, titleText: NSLocalizedString("Show most visited websites", tableName: "Cliqz", comment: "[Settings] Show most visited websites"))
        let showNewsSetting          = BoolSetting(prefs: prefs, prefKey: SettingsPrefs.ShowNewsPrefKey, defaultValue: true, titleText: NSLocalizedString("Show News", tableName: "Cliqz", comment: "[Settings] Show News"))
        let cliqzTabSection = [showTopSitesSetting, showNewsSetting]
        
        
        // Help Section
        let supportSetting          = SupportSetting(delegate: settingsDelegate)
        let tipsAndTricksSetting    = TipsAndTricksSetting()
        let reportWebsiteSetting    = ReportWebsiteSetting()
        
        let helpSection: [Setting] = [supportSetting, tipsAndTricksSetting, reportWebsiteSetting]
        
        
        // About Cliqz Section
        let rateSetting     = RateUsSetting()
        let aboutSetting    = AboutSetting()
        
        let AboutCliqzSection: [Setting] = [rateSetting, aboutSetting]
        
        // Combine All sections together
        var settings = [
            SettingSection(title: NSAttributedString(string: NSLocalizedString("Search", tableName: "Cliqz", comment: "[Settings] Search section title")), children: searchSection),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("Browsing & History", tableName: "Cliqz", comment: "[Settings] Browsing & History section header")), children: browsingAndHistorySection),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("Cliqz Tab", tableName: "Cliqz", comment: "[Settings] Cliqz Tab section header")), children: cliqzTabSection),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("Help", tableName: "Cliqz", comment: "[Settings] Help section header")), children: helpSection),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("About Cliqz", tableName: "Cliqz", comment: "[Settings] About Cliqz section header")), children: AboutCliqzSection)
                        ]

        
        #if BETA
            let betaSection = [BoolSetting(prefs: prefs, prefKey: SettingsPrefs.LogTelemetryPrefKey, defaultValue: false, titleText: "Log Telemetry Signals"),
                                        ShowIntroductionSetting(settings: self),
                                        ExportLocalDatabaseSetting(settings: self)]
            
            settings += [SettingSection(title: NSAttributedString(string: "Beta Settings"), children: betaSection)]
        #endif
        
        
        return settings
    
    }
    /*
    override func generateSettings() -> [SettingSection] {
        var settings = [SettingSection]()
        
        let privacyTitle = NSLocalizedString("Privacy", comment: "Privacy section title")
        let accountDebugSettings: [Setting]
        if AppConstants.BuildChannel != .aurora {
            accountDebugSettings = [
                // Debug settings:
                RequirePasswordDebugSetting(settings: self),
                RequireUpgradeDebugSetting(settings: self),
                ForgetSyncAuthStateDebugSetting(settings: self),
                StageSyncServiceDebugSetting(settings: self),
            ]
        } else {
            accountDebugSettings = []
        }
        
        let prefs = profile.prefs
        var generalSettings: [Setting] = [
            SearchSetting(settings: self),
            NewTabPageSetting(settings: self),
            HomePageSetting(settings: self),
            OpenWithSetting(settings: self),
            BoolSetting(prefs: prefs, prefKey: "blockPopups", defaultValue: true,
                titleText: NSLocalizedString("Block Pop-up Windows", comment: "Block pop-up windows setting")),
            BoolSetting(prefs: prefs, prefKey: "saveLogins", defaultValue: true,
                titleText: NSLocalizedString("Save Logins", comment: "Setting to enable the built-in password manager")),
            BoolSetting(prefs: prefs, prefKey: AllowThirdPartyKeyboardsKey, defaultValue: false,
                titleText: NSLocalizedString("Allow Third-Party Keyboards", comment: "Setting to enable third-party keyboards"), statusText: NSLocalizedString("Firefox needs to reopen for this change to take effect.", comment: "Setting value prop to enable third-party keyboards")),
            ]
        
        let accountChinaSyncSetting: [Setting]
        if !profile.isChinaEdition {
            accountChinaSyncSetting = []
        } else {
            accountChinaSyncSetting = [
                // Show China sync service setting:
                ChinaSyncServiceSetting(settings: self)
            ]
        }
        // There is nothing to show in the Customize section if we don't include the compact tab layout
        // setting on iPad. When more options are added that work on both device types, this logic can
        // be changed.
        if UIDevice.current.userInterfaceIdiom == .phone {
            generalSettings +=  [
                BoolSetting(prefs: prefs, prefKey: "CompactTabLayout", defaultValue: true,
                    titleText: NSLocalizedString("Use Compact Tabs", comment: "Setting to enable compact tabs in the tab overview"))
            ]
        }
        
        settings += [
            SettingSection(title: nil, children: [
                // Without a Firefox Account:
                ConnectSetting(settings: self),
                // With a Firefox Account:
                AccountStatusSetting(settings: self),
                SyncNowSetting(settings: self)
                ] + accountChinaSyncSetting + accountDebugSettings)]
        
        if !profile.hasAccount() {
            settings += [SettingSection(title: NSAttributedString(string: NSLocalizedString("Sign in to get your tabs, bookmarks, and passwords from your other devices.", comment: "Clarify value prop under Sign In to Firefox in Settings.")), children: [])]
        }
        
        settings += [ SettingSection(title: NSAttributedString(string: NSLocalizedString("General", comment: "General settings section title")), children: generalSettings)]
        
        var privacySettings = [Setting]()
        privacySettings.append(LoginsSetting(settings: self, delegate: settingsDelegate))
        privacySettings.append(TouchIDPasscodeSetting(settings: self))
        
        privacySettings.append(ClearPrivateDataSetting(settings: self))
        
        privacySettings += [
            BoolSetting(prefs: prefs,
                prefKey: "settings.closePrivateTabs",
                defaultValue: false,
                titleText: NSLocalizedString("Close Private Tabs", tableName: "PrivateBrowsing", comment: "Setting for closing private tabs"),
                statusText: NSLocalizedString("When Leaving Private Browsing", tableName: "PrivateBrowsing", comment: "Will be displayed in Settings under 'Close Private Tabs'"))
        ]
        
        privacySettings += [
            PrivacyPolicySetting()
        ]
        
        settings += [
            SettingSection(title: NSAttributedString(string: privacyTitle), children: privacySettings),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("Support", comment: "Support section title")), children: [
                ShowIntroductionSetting(settings: self),
                SendFeedbackSetting(),
                SendAnonymousUsageDataSetting(prefs: prefs, delegate: settingsDelegate),
                OpenSupportPageSetting(delegate: settingsDelegate),
                ]),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("About", comment: "About settings section title")), children: [
                VersionSetting(settings: self),
                LicenseAndAcknowledgementsSetting(),
                YourRightsSetting(),
                ExportBrowserDataSetting(settings: self),
                DeleteExportedDataSetting(settings: self),
                EnableBookmarkMergingSetting(settings: self)
                ])]
        
        if profile.hasAccount() {
            settings += [
                SettingSection(title: nil, children: [
                    DisconnectSetting(settings: self),
                    ])
            ]
        }
        
        return settings
    }
    */
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !profile.hasAccount() {
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderIdentifier) as! SettingsTableSectionHeaderFooterView
            let sectionSetting = settings[section]
            headerView.titleLabel.text = sectionSetting.title?.string
            
            // Cliqz: remove all FireFox header customizations due to hiding unneeded sections
            return super.tableView(tableView, viewForHeaderInSection: section)
            /*
            switch section {
                // Hide the bottom border for the Sign In to Firefox value prop
                case 1:
                    headerView.titleAlignment = .Top
                    headerView.titleLabel.numberOfLines = 0
                    headerView.showBottomBorder = false
                    headerView.titleLabel.snp_updateConstraints { make in
                        make.right.equalTo(headerView).offset(-50)
                    }

                // Hide the top border for the General section header when the user is not signed in.
                case 2:
                    headerView.showTopBorder = false
                default:
                    return super.tableView(tableView, viewForHeaderInSection: section)
            }
            return headerView
            */
        }
        
        return super.tableView(tableView, viewForHeaderInSection: section)
    }
}

extension AppSettingsTableViewController {
    func navigateToLoginsList() {
        let viewController = LoginListViewController(profile: profile)
        viewController.settingsDelegate = settingsDelegate
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension AppSettingsTableViewController: PasscodeEntryDelegate {
    @objc func passcodeValidationDidSucceed() {
        navigationController?.dismiss(animated: true) {
            self.navigateToLoginsList()
        }
    }
}
