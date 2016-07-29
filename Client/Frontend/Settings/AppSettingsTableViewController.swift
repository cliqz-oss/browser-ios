/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import Account

/// App Settings Screen (triggered by tapping the 'Gear' in the Tab Tray Controller)
class AppSettingsTableViewController: SettingsTableViewController {
    private let SectionHeaderIdentifier = "SectionHeaderIdentifier"

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Settings", comment: "Settings")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"),
            style: UIBarButtonItemStyle.Done,
            target: navigationController, action: Selector("SELdone"))
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "AppSettingsTableViewController.navigationItem.leftBarButtonItem"

        tableView.accessibilityIdentifier = "AppSettingsTableViewController.tableView"
    }

    override func generateSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        let privacyTitle = NSLocalizedString("Privacy", comment: "Privacy section title")
        let accountDebugSettings: [Setting]
        if AppConstants.BuildChannel != .Aurora {
            accountDebugSettings = [
                // Debug settings:
                RequirePasswordDebugSetting(settings: self),
                RequireUpgradeDebugSetting(settings: self),
                ForgetSyncAuthStateDebugSetting(settings: self),
            ]
        } else {
            accountDebugSettings = []
        }

        let prefs = profile.prefs
        var generalSettings = [
            //Cliqz: replaced SearchSetting by CliqzSearchSetting to verride the behavior of selecting search engine
//            SearchSetting(settings: self),
            CliqzSearchSetting(settings: self),
            EnablePushNotifications(prefs: prefs, prefKey: "enableNewsPushNotifications", defaultValue: false,
				titleText: NSLocalizedString("Enable News Push Notifications", tableName: "Cliqz", comment: "Enable News Push Notifications")),
            BoolSetting(prefs: prefs, prefKey: "blockPopups", defaultValue: true,
                titleText: NSLocalizedString("Block Pop-up Windows", comment: "Block pop-up windows setting")),
            BoolSetting(prefs: prefs, prefKey: "saveLogins", defaultValue: true,
                titleText: NSLocalizedString("Save Logins", comment: "Setting to enable the built-in password manager")),
            // Cliqz: Commented settings for enabling third party keyboards according to our policy.
			/*
            BoolSetting(prefs: prefs, prefKey: AllowThirdPartyKeyboardsKey, defaultValue: false,
                titleText: NSLocalizedString("Allow Third-Party Keyboards", comment: "Setting to enable third-party keyboards"), statusText: NSLocalizedString("Firefox needs to reopen for this change to take effect.", comment: "Setting value prop to enable third-party keyboards")),
			*/
            BoolSetting(prefs: prefs, prefKey: "blockContent", defaultValue: true, titleText: NSLocalizedString("Block Explicit Content", tableName: "Cliqz", comment: "Block explicit content setting")),
            AdBlockerSetting(settings: self),
            ImprintSetting(),
            HumanWebSetting(settings: self)

        ]
        
        //Cliqz: removed unused sections from Settings table
//        let accountChinaSyncSetting: [Setting]
//        let locale = NSLocale.currentLocale()
//        if locale.localeIdentifier != "zh_CN" {
//            accountChinaSyncSetting = []
//        } else {
//            accountChinaSyncSetting = [
//                // Show China sync service setting:
//                ChinaSyncServiceSetting(settings: self)
//            ]
//        }
        // There is nothing to show in the Customize section if we don't include the compact tab layout
        // setting on iPad. When more options are added that work on both device types, this logic can
        // be changed.
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            generalSettings +=  [
                BoolSetting(prefs: prefs, prefKey: "CompactTabLayout", defaultValue: true,
                    titleText: NSLocalizedString("Use Compact Tabs", comment: "Setting to enable compact tabs in the tab overview"))
            ]
        }

        //Cliqz: removed unused sections from Settings table
//        settings += [
//            SettingSection(title: nil, children: [
//                // Without a Firefox Account:
//                ConnectSetting(settings: self),
//                // With a Firefox Account:
//                AccountStatusSetting(settings: self),
//                SyncNowSetting(settings: self)
//            ] + accountChinaSyncSetting + accountDebugSettings)
//        ]

        //Cliqz: removed unused sections from Settings table
//        if !profile.hasAccount() {
//            settings += [SettingSection(title: NSAttributedString(string: NSLocalizedString("Sign in to get your tabs, bookmarks, and passwords from your other devices.", comment: "Clarify value prop under Sign In to Firefox in Settings.")), children: [])]
//        }

        settings += [ SettingSection(title: NSAttributedString(string: NSLocalizedString("General", comment: "General settings section title")), children: generalSettings)]

        
        var privacySettings = [Setting]()
        if AppConstants.MOZ_LOGIN_MANAGER {
            privacySettings.append(LoginsSetting(settings: self, delegate: settingsDelegate))
        }

        //Cliqz: removed passcode settings as it is not working
//        if AppConstants.MOZ_AUTHENTICATION_MANAGER {
//            privacySettings.append(TouchIDPasscodeSetting(settings: self))
//        }

        privacySettings.append(ClearPrivateDataSetting(settings: self))

        if #available(iOS 9, *) {
            privacySettings += [
                BoolSetting(prefs: prefs,
                    prefKey: "settings.closePrivateTabs",
                    defaultValue: false,
                    titleText: NSLocalizedString("Close Private Tabs", tableName: "PrivateBrowsing", comment: "Setting for closing private tabs"),
                    statusText: NSLocalizedString("When Leaving Private Browsing", tableName: "PrivateBrowsing", comment: "Will be displayed in Settings under 'Close Private Tabs'"))
            ]
        }

        //Cliqz: removed unused sections from Settings table
        privacySettings += [
//            BoolSetting(prefs: prefs, prefKey: "crashreports.send.always", defaultValue: false,
//                titleText: NSLocalizedString("Send Crash Reports", comment: "Setting to enable the sending of crash reports"),
//                settingDidChange: { configureActiveCrashReporter($0) }),
            ShowBlockedTopSitesSetting(),
            PrivacyPolicySetting()
        ]


        settings += [
            SettingSection(title: NSAttributedString(string: privacyTitle), children: privacySettings),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("Support", comment: "Support section title")), children: [
                ShowIntroductionSetting(settings: self),
                //Cliqz: replaced feedback setting by Cliqz feedback setting to overrid the behavior of sending feedback
//                SendFeedbackSetting(),
                SendCliqzFeedbackSetting(),

                //Cliqz: removed unused sections from Settings table
//                SendAnonymousUsageDataSetting(prefs: prefs, delegate: settingsDelegate),
//                OpenSupportPageSetting(delegate: settingsDelegate),
            ]),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("About", comment: "About settings section title")), children: [
                VersionSetting(settings: self),
                LicenseAndAcknowledgementsSetting(),
                //Cliqz: removed unused sections from Settings table
//                YourRightsSetting(),
//                ExportBrowserDataSetting(settings: self),
//                DeleteExportedDataSetting(settings: self),
            ])]
        //Cliqz: removed unused sections from Settings table
//            if (profile.hasAccount()) {
//                settings += [
//                    SettingSection(title: nil, children: [
//                        DisconnectSetting(settings: self),
//                        ])
//                ]
//            }

        return settings
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !profile.hasAccount() {
            let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderIdentifier) as! SettingsTableSectionHeaderFooterView
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