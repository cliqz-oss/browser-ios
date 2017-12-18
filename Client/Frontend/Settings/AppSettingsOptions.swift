/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper
import LocalAuthentication

// This file contains all of the settings available in the main settings screen of the app.

private var ShowDebugSettings: Bool = false
private var DebugSettingsClickCount: Int = 0

// For great debugging!
class HiddenSetting: Setting {
    unowned let settings: SettingsTableViewController

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var hidden: Bool {
        return !ShowDebugSettings
    }
}

// Sync setting for connecting a Firefox Account.  Shown when we don't have an account.
class ConnectSetting: WithoutAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Sign In to Firefox", comment: "Text message / button in the settings table view"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var accessibilityIdentifier: String? { return "SignInToFirefox" }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = FxAContentViewController()
        viewController.delegate = self
        //viewController.url = settings.profile.accountConfiguration.signInURL
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// Sync setting for disconnecting a Firefox Account.  Shown when we have an account.
class DisconnectSetting: WithAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .none }
    override var textAlignment: NSTextAlignment { return .center }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Log Out", comment: "Button in settings screen to disconnect from your account"), attributes: [NSForegroundColorAttributeName: UIConstants.DestructiveRed])
    }

    override var accessibilityIdentifier: String? { return "LogOut" }

    override func onClick(_ navigationController: UINavigationController?) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Log Out?", comment: "Title of the 'log out firefox account' alert"),
            message: NSLocalizedString("Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.", comment: "Text of the 'log out firefox account' alert"),
            preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label for Cancel button"), style: .cancel) { (action) in
                // Do nothing.
            })
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Log Out", comment: "Disconnect button in the 'log out firefox account' alert"), style: .destructive) { (action) in
                //self.settings.profile.removeAccount()
                self.settings.settings = self.settings.generateSettings()
                self.settings.SELfirefoxAccountDidChange()
            })
        navigationController?.present(alertController, animated: true, completion: nil)
    }
}

class SyncNowSetting: WithAccountSetting {
    static let NotificationUserInitiatedSyncManually = "NotificationUserInitiatedSyncManually"

    fileprivate lazy var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    fileprivate var syncNowTitle: NSAttributedString {
        return NSAttributedString(
            string: NSLocalizedString("Sync Now", comment: "Sync Firefox Account"),
            attributes: [
                NSForegroundColorAttributeName: self.enabled ? UIColor.black : UIColor.gray,
                NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFont
            ]
        )
    }

    fileprivate let syncingTitle = NSAttributedString(string: Strings.SyncingMessageWithEllipsis, attributes: [NSForegroundColorAttributeName: UIColor.gray, NSFontAttributeName: UIFont.systemFont(ofSize: DynamicFontHelper.defaultHelper.DefaultStandardFontSize, weight: UIFontWeightRegular)])

    override var accessoryType: UITableViewCellAccessoryType { return .none }

    override var style: UITableViewCellStyle { return .value1 }

    override var title: NSAttributedString? {
        return nil
    }

    override var status: NSAttributedString? {
        return nil
    }

    override var enabled: Bool {
        return false
    }

    fileprivate lazy var troubleshootButton: UIButton = {
        let troubleshootButton = UIButton(type: UIButtonType.roundedRect)
        troubleshootButton.setTitle(Strings.FirefoxSyncTroubleshootTitle, for: .normal)
        troubleshootButton.addTarget(self, action: #selector(self.troubleshoot), for: .touchUpInside)
        troubleshootButton.tintColor = UIConstants.TableViewRowActionAccessoryColor
        troubleshootButton.titleLabel?.font = DynamicFontHelper.defaultHelper.DefaultSmallFont
        troubleshootButton.sizeToFit()
        return troubleshootButton
    }()

    fileprivate lazy var warningIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "AmberCaution"))
        imageView.sizeToFit()
        return imageView
    }()

    fileprivate lazy var errorIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "RedCaution"))
        imageView.sizeToFit()
        return imageView
    }()

    fileprivate let syncSUMOURL = SupportUtils.URLForTopic("sync-status-ios")

    @objc fileprivate func troubleshoot() {
        let viewController = SettingsContentViewController()
        viewController.url = syncSUMOURL
        settings.navigationController?.pushViewController(viewController, animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        cell.textLabel?.attributedText = title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping

        cell.accessoryView = nil
        
        cell.accessoryType = accessoryType
        cell.isUserInteractionEnabled = true
    }

    fileprivate func addIcon(_ image: UIImageView, toCell cell: UITableViewCell) {
        cell.contentView.addSubview(image)

        cell.textLabel?.snp_updateConstraints { make in
            make.leading.equalTo(image.snp_trailing).offset(5)
            make.trailing.lessThanOrEqualTo(cell.contentView)
            make.centerY.equalTo(cell.contentView)
        }

        image.snp_makeConstraints { make in
            make.leading.equalTo(cell.contentView).offset(17)
            make.top.equalTo(cell.textLabel!).offset(2)
        }
    }

    override func onClick(_ navigationController: UINavigationController?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: SyncNowSetting.NotificationUserInitiatedSyncManually), object: nil)
    }
}

// Sync setting that shows the current Firefox Account status.
class AccountStatusSetting: WithAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType {
//        if let account = profile.getAccount() {
//            switch account.actionNeeded {
//            case .needsVerification:
//                // We link to the resend verification email page.
//                return .disclosureIndicator
//            case .needsPassword:
//                 // We link to the re-enter password page.
//                return .disclosureIndicator
//            case .none, .needsUpgrade:
//                // In future, we'll want to link to /settings and an upgrade page, respectively.
//                return .none
//            }
//        }
        return .disclosureIndicator
    }

    override var title: NSAttributedString? {
//        if let account = profile.getAccount() {
//            return NSAttributedString(string: account.email, attributes: [NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFontBold, NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
//        }
        return nil
    }

    override var status: NSAttributedString? {
//        if let account = profile.getAccount() {
//            switch account.actionNeeded {
//            case .none:
//                return nil
//            case .needsVerification:
//                return NSAttributedString(string: NSLocalizedString("Verify your email address.", comment: "Text message in the settings table view"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
//            case .needsPassword:
//                let string = NSLocalizedString("Enter your password to connect.", comment: "Text message in the settings table view")
//                let range = NSRange(location: 0, length: string.characters.count)
//                let orange = UIColor(red: 255.0 / 255, green: 149.0 / 255, blue: 0.0 / 255, alpha: 1)
//                let attrs = [NSForegroundColorAttributeName : orange]
//                let res = NSMutableAttributedString(string: string)
//                res.setAttributes(attrs, range: range)
//                return res
//            case .needsUpgrade:
//                let string = NSLocalizedString("Upgrade Firefox to connect.", comment: "Text message in the settings table view")
//                let range = NSRange(location: 0, length: string.characters.count)
//                let orange = UIColor(red: 255.0 / 255, green: 149.0 / 255, blue: 0.0 / 255, alpha: 1)
//                let attrs = [NSForegroundColorAttributeName : orange]
//                let res = NSMutableAttributedString(string: string)
//                res.setAttributes(attrs, range: range)
//                return res
//            }
//        }
        return nil
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = FxAContentViewController()
        viewController.delegate = self

//        if let account = profile.getAccount() {
//            switch account.actionNeeded {
//            case .needsVerification:
//                var cs = URLComponents(url: account.configuration.settingsURL, resolvingAgainstBaseURL: false)
//                cs?.queryItems?.append(URLQueryItem(name: "email", value: account.email))
//                viewController.url = cs?.url
//            case .needsPassword:
//                var cs = URLComponents(url: account.configuration.forceAuthURL, resolvingAgainstBaseURL: false)
//                cs?.queryItems?.append(URLQueryItem(name: "email", value: account.email))
//                viewController.url = cs?.url
//            case .none, .needsUpgrade:
//                // In future, we'll want to link to /settings and an upgrade page, respectively.
//                return
//            }
//        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// For great debugging!
class RequirePasswordDebugSetting: WithAccountSetting {
    override var hidden: Bool {
        if !ShowDebugSettings {
            return true
        }
//        if let account = profile.getAccount(), account.actionNeeded != FxAActionNeeded.needsPassword {
//            return false
//        }
        return true
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Debug: require password", comment: "Debug option"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        //profile.getAccount()?.makeSeparated()
        settings.tableView.reloadData()
    }
}


// For great debugging!
class RequireUpgradeDebugSetting: WithAccountSetting {
    override var hidden: Bool {
        if !ShowDebugSettings {
            return true
        }
//        if let account = profile.getAccount(), account.actionNeeded != FxAActionNeeded.needsUpgrade {
//            return false
//        }
        return true
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Debug: require upgrade", comment: "Debug option"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        //profile.getAccount()?.makeDoghouse()
        settings.tableView.reloadData()
    }
}

// For great debugging!
class ForgetSyncAuthStateDebugSetting: WithAccountSetting {
    override var hidden: Bool {
        if !ShowDebugSettings {
            return true
        }
//        if let _ = profile.getAccount() {
//            return false
//        }
        return true
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Debug: forget Sync auth state", comment: "Debug option"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        //profile.getAccount()?.syncAuthState.invalidate()
        settings.tableView.reloadData()
    }
}


class DeleteExportedDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: delete exported databases", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: documentsPath)
            for file in files {
                if file.startsWith("browser.") || file.startsWith("logins.") {
                    try fileManager.removeItemInDirectory(documentsPath, named: file)
                }
            }
        } catch {
            print("Couldn't delete exported data: \(error).")
        }
    }
}

class ExportBrowserDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: copy databases to app container", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            let log = Logger.syncLogger
            try self.settings.profile.files.copyMatching(fromRelativeDirectory: "", toAbsoluteDirectory: documentsPath) { file in
                log.debug("Matcher: \(file)")
                return file.startsWith("browser.") || file.startsWith("logins.")
            }
        } catch {
            print("Couldn't export browser data: \(error).")
        }
    }
}

// Show the current version of Firefox
class VersionSetting : Setting {
    unowned let settings: SettingsTableViewController

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var title: NSAttributedString? {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        return NSAttributedString(string: String(format: NSLocalizedString("Version %@ (%@)", comment: "Version number of Firefox shown in settings"), appVersion, buildNumber), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        cell.selectionStyle = .none
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if AppConstants.BuildChannel != .Aurora {
            DebugSettingsClickCount += 1
            if DebugSettingsClickCount >= 5 {
                DebugSettingsClickCount = 0
                ShowDebugSettings = !ShowDebugSettings
                settings.tableView.reloadData()
            }
        }
    }
}

// Opens the the license page in a new tab
class LicenseAndAcknowledgementsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Licenses", tableName: "Cliqz", comment: "[Settings -> About] Licenses"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: URL? {
        return URL(string: WebServer.sharedInstance.URLForResource("license", module: "about"))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)

        // Cliqz: log telemetry signal
        let licenseSignal = TelemetryLogEventType.Settings("main", "click", "license", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(licenseSignal)
    }
}

// Opens about:rights page in the content view controller
class YourRightsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Your Rights", comment: "Your Rights settings section title"), attributes:
            [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: URL? {
        return URL(string: "https://www.mozilla.org/about/legal/terms/firefox/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens the on-boarding screen again
class ShowIntroductionSetting: Setting {
    let profile: Profile

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Show Tour", comment: "Show the on-boarding screen again from the settings"), attributes: [NSForegroundColorAttributeName: UIConstants.HighlightBlue]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
		navigationController?.dismiss(animated: true, completion: {
			InteractiveIntro.sharedInstance.reset()
		})
        // Cliqz: log telemetry signal
        let showTourSignal = TelemetryLogEventType.Settings("main", "click", "show_tour", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(showTourSignal)
    }
}

class SendFeedbackSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Send Feedback", comment: "Menu item in settings used to open input.mozilla.org where people can submit feedback"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: URL? {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        return URL(string: "https://input.mozilla.org/feedback/fxios/\(appVersion)")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

class SendAnonymousUsageDataSetting: BoolSetting {
    init(prefs: Prefs, delegate: SettingsDelegate?) {
        super.init(
            prefs: prefs, prefKey: "settings.sendUsageData", defaultValue: true,
            attributedTitleText: NSAttributedString(string: NSLocalizedString("Send Anonymous Usage Data", tableName: "SendAnonymousUsageData", comment: "See http://bit.ly/1SmEXU1")),
            attributedStatusText: NSAttributedString(string: NSLocalizedString("More Info…", tableName: "SendAnonymousUsageData", comment: "See http://bit.ly/1SmEXU1"), attributes: [NSForegroundColorAttributeName: UIConstants.HighlightBlue]),
            settingDidChange: { AdjustIntegration.setEnabled($0) }
        )
    }

    override var url: URL? {
        return SupportUtils.URLForTopic("adjust")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens the the SUMO page in a new tab
class OpenSupportPageSetting: Setting {
    init(delegate: SettingsDelegate?) {
        super.init(title: NSAttributedString(string: NSLocalizedString("Help", comment: "Show the SUMO support page from the Support section in the settings. see http://mzl.la/1dmM8tZ"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]),
            delegate: delegate)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true) {
            if let url = URL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.settingsOpenURLInNewTab(url)
            }
        }
    }
}

// Opens the search settings pane
class SearchSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var style: UITableViewCellStyle { return .value1 }

    override var status: NSAttributedString { return NSAttributedString(string: profile.searchEngines.defaultEngine.shortName) }

    override var accessibilityIdentifier: String? { return "Search" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Complementary Search", tableName: "Cliqz", comment: "[Settings] Complementary Search"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SearchSettingsTableViewController()
        viewController.model = profile.searchEngines
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class ClearPrivateDataSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var accessibilityIdentifier: String? { return "ClearPrivateData" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let clearTitle = Strings.SettingsClearPrivateDataSectionName
        super.init(title: NSAttributedString(string: clearTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = ClearPrivateDataTableViewController()
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
        
        // Cliqz: log telemetry signal
        let privateDataSignal = TelemetryLogEventType.Settings("main", "click", "private_data", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(privateDataSignal)
    }
}

class PrivacyPolicySetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Privacy Policy", tableName: "Cliqz", comment: "[Settings -> About] Privacy Policy"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: URL? {
        //Cliqz: replaced FireFox Privacy Policy URL with Cliqz one
//        return NSURL(string: "https://www.mozilla.org/privacy/firefox/")
        return URL(string: "https://cliqz.com/mobile/privacy-cliqz-for-ios")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
        
        // Cliqz: log telemetry signal
        let privacySignal = TelemetryLogEventType.Settings("main", "click", "privacy_statement", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(privacySignal)
    }
}


class TipsAndTricksSetting: Setting {
    
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }
    
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Get the best out of CLIQZ", tableName: "Cliqz", comment: "[Settings] Get the best out of CLIQZ"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }
    
    override var url: URL? {
        return URL(string: "https://cliqz.com/tips-ios")
    }
    
    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
        
        // Cliqz: log telemetry signal
        let privacySignal = TelemetryLogEventType.Settings("main", "click", "tips_tricks", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(privacySignal)
    }
}


class ChinaSyncServiceSetting: WithoutAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .none }
    var prefs: Prefs { return settings.profile.prefs }
    let prefKey = "useChinaSyncService"

    override var title: NSAttributedString? {
        return NSAttributedString(string: "本地同步服务", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "禁用后使用全球服务同步数据", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewHeaderTextColor])
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: #selector(ChinaSyncServiceSetting.switchValueChanged(_:)), for: UIControlEvents.valueChanged)
        control.isOn = prefs.boolForKey(prefKey) ?? true
        cell.accessoryView = control
        cell.selectionStyle = .none
    }

    @objc func switchValueChanged(_ toggle: UISwitch) {
        prefs.setObject(toggle.isOn, forKey: prefKey)
    }
}

class HomePageSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var accessibilityIdentifier: String? { return "HomePageSetting" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        super.init(title: NSAttributedString(string: Strings.SettingsHomePageSectionName, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = HomePageSettingsViewController()
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }

}

