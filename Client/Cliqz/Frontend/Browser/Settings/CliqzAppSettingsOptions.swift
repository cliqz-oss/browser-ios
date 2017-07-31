//
//  CliqzAppSettingsOptions.swift
//  Client
//
//  Created by Mahmoud Adam on 3/4/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import MessageUI
import Shared

import React

//Cliqz: Added to modify the behavior of changing default search engine 
class CliqzSearchSetting: SearchSetting, SearchEnginePickerDelegate {
    
    //Cliqz: override onclick to directly go to default search engine selection
    override func onClick(_ navigationController: UINavigationController?) {
        let searchEnginePicker = SearchEnginePicker()
        searchEnginePicker.title = self.title?.string
        // Order alphabetically, so that picker is always consistently ordered.
        // Every engine is a valid choice for the default engine, even the current default engine.
        searchEnginePicker.engines = profile.searchEngines.orderedEngines.sorted { e, f in e.shortName < f.shortName }
        searchEnginePicker.delegate = self
        searchEnginePicker.selectedSearchEngineName = profile.searchEngines.defaultEngine.shortName
        navigationController?.pushViewController(searchEnginePicker, animated: true)
        
        let searchEngineSingal = TelemetryLogEventType.Settings("main", "click", "search_engine", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(searchEngineSingal)
    }
    
    func searchEnginePicker(_ searchEnginePicker: SearchEnginePicker?, didSelectSearchEngine engine: OpenSearchEngine?) -> Void {
        if let searchEngine = engine {
            profile.searchEngines.defaultEngine = searchEngine
        }
    }
}


//Cliqz: Added Settings for legal page
class ImprintSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Imprint", tableName: "Cliqz", comment: "Show Cliqz legal page. See https://cliqz.com/legal"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }
    
    override var url: URL? {
        return URL(string: "https://cliqz.com/legal")
    }
    
    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
        // log Telemerty signal
        let imprintSingal = TelemetryLogEventType.Settings("main", "click", "imprint", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(imprintSingal)
    }
}

//Cliqz: Added new settings item for Human Web
class HumanWebSetting: Setting {
    
    let profile: Profile

    override var style: UITableViewCellStyle { return .value1 }

    override var status: NSAttributedString {
        return NSAttributedString(string: SettingsPrefs.getHumanWebPref() ? Setting.onStatus : Setting.offStatus)
    }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        
        let title = NSLocalizedString("Human Web", tableName: "Cliqz", comment: "[Settings] Human Web")
        
        super.init(title: NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }
    
    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = HumanWebSettingsTableViewController()
        viewController.title = self.title?.string
        navigationController?.pushViewController(viewController, animated: true)
        // log Telemerty signal
        let humanWebSingal = TelemetryLogEventType.Settings("main", "click", "human_web", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(humanWebSingal)
    }
}

class AboutSetting: Setting {
    
    override var style: UITableViewCellStyle { return .value1 }

    override var status: NSAttributedString { return NSAttributedString(string: "Version \(AppStatus.sharedInstance.distVersion)") }
    
    init() {
        let title = NSLocalizedString("About", tableName: "Cliqz", comment: "[Settings] About")
        super.init(title: NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
#if BETA
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    
    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = AboutSettingsTableViewController()
        viewController.title = self.title?.string
        navigationController?.pushViewController(viewController, animated: true)
    }
#endif
}

class RateUsSetting: Setting {
    let AppId = "1065837334"
    
    init() {
        super.init(title: NSAttributedString(string: NSLocalizedString("Rate Us", tableName: "Cliqz", comment: "[Settings] Rate Us"), attributes: [NSForegroundColorAttributeName: UIConstants.HighlightBlue]))
    }
    
    override func onClick(_ navigationController: UINavigationController?) {
        
        if let url = URL(string: "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(AppId)&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8") {
            UIApplication.shared.openURL(url)
        }
    }
}


class TestReact: Setting {
    
    let profile: Profile
    
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        
        let reactTitle = "Test React"
        super.init(title: NSAttributedString(string: reactTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }
    
    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = UIViewController()
        viewController.view = Engine.sharedInstance.rootView
        navigationController?.pushViewController(viewController, animated: true)
    }
}

//Cliqz: Added new settings item for Ad Blocker
class AdBlockerSetting: Setting {
    
    let profile: Profile

    override var style: UITableViewCellStyle { return .value1 }
    
    override var status: NSAttributedString {
        return NSAttributedString(string: SettingsPrefs.getAdBlockerPref() ? Setting.onStatus : Setting.offStatus)
    }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        
        let title = NSLocalizedString("Block Ads", tableName: "Cliqz", comment: "[Settings] Block Ads")
        super.init(title: NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }
    
    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = AdBlockerSettingsTableViewController()
        viewController.title = self.title?.string
        navigationController?.pushViewController(viewController, animated: true)
        
        // log Telemerty signal
        let blcokAdsSingal = TelemetryLogEventType.Settings("main", "click", "block_ads", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(blcokAdsSingal)
    }
}

//Cliqz: Added Settings for redirecting to feedback page
class SupportSetting: Setting {
        
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("FAQ & Support", tableName: "Cliqz", comment: "[Settings] FAQ & Support"),attributes: [NSForegroundColorAttributeName: UIConstants.HighlightBlue])
    }
    
    override var url: URL? {
        return URL(string: "https://cliqz.com/support")
    }
    
    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true, completion: {})
        self.delegate?.settingsOpenURLInNewTab(self.url!)
        
        // Cliqz: log telemetry signal
        let contactSignal = TelemetryLogEventType.Settings("main", "click", "contact", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(contactSignal)
    }
    
}

//Cliqz: Added Setting for redirecting to report form
class ReportWebsiteSetting: Setting {
    
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }
    
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Report Website", tableName: "Cliqz", comment: "[Settings] Report Website"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }
    
    override var url: URL? {
        if let languageCode = Locale.current.regionCode, languageCode == "de"{
            return URL(string: "https://cliqz.com/report-url")
        }
        return URL(string: "https://cliqz.com/en/report-url")
    }
    
    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
        
        // Cliqz: log telemetry signal
        let contactSignal = TelemetryLogEventType.Settings("main", "click", "contact", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(contactSignal)
    }
    
}

// Cliqz: Custom Bool settings for News Push Notifications
class EnablePushNotifications: BoolSetting {
	
	@objc override func switchValueChanged(_ control: UISwitch) {
		super.switchValueChanged(control)
		if control.isOn {
			NewsNotificationPermissionHelper.sharedInstance.enableNewsNotifications()
        } else {
			NewsNotificationPermissionHelper.sharedInstance.disableNewsNotifications()
		}
	}

}

// Cliqz: setting to reset top sites
class RestoreTopSitesSetting: Setting {
    
	let profile: Profile
	weak var settingsViewController: SettingsTableViewController?
    
	init(settings: SettingsTableViewController) {
		self.profile = settings.profile
        self.settingsViewController = settings
        let hiddenTopsitesCount = self.profile.history.getHiddenTopSitesCount()
        var attributes: [String : AnyObject]?
        if hiddenTopsitesCount > 0 {
            attributes = [NSForegroundColorAttributeName: UIConstants.HighlightBlue]
        } else {
            attributes = [NSForegroundColorAttributeName: UIColor.lightGray]
        }
        
        super.init(title: NSAttributedString(string: NSLocalizedString("Restore Most Visited Websites", tableName: "Cliqz", comment: "[Settings] Restore Most Visited Websites"), attributes: attributes))
    }
    
    override func onClick(_ navigationController: UINavigationController?) {
        guard self.profile.history.getHiddenTopSitesCount() > 0 else {
            return
        }
        
        let alertController = UIAlertController(
            title: "",
            message: NSLocalizedString("All most visited websites will be shown again on the startpage.", tableName: "Cliqz", comment: "[Settings] Text of the 'Restore Most Visited Websites' alert"),
            preferredStyle: UIAlertControllerStyle.actionSheet)
        
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Cliqz", comment: "Cancel button in the 'Show blocked top-sites' alert"), style: .cancel) { (action) in
                // log telemetry signal
                let cancelSignal = TelemetryLogEventType.Settings("restore_topsites", "click", "cancel", nil, nil)
                TelemetryLogger.sharedInstance.logEvent(cancelSignal)
            })
        alertController.addAction(
            UIAlertAction(title: self.title?.string, style: .destructive) { (action) in
                // reset top-sites
				self.profile.history.deleteAllHiddenTopSites()
                
                self.settingsViewController?.reloadSettings()
                
                // log telemetry signal
                let confirmSignal = TelemetryLogEventType.Settings("restore_topsites", "click", "confirm", nil, nil)
                TelemetryLogger.sharedInstance.logEvent(confirmSignal)

            })
        navigationController?.present(alertController, animated: true, completion: nil)
        
        // log telemetry signal
        let restoreTopsitesSignal = TelemetryLogEventType.Settings("main", "click", "restore_topsites", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(restoreTopsitesSignal)
    }
}

// Opens the search settings pane
class RegionalSetting: Setting {
    let profile: Profile
    
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }
    
    override var style: UITableViewCellStyle { return .value1 }
    
    override var status: NSAttributedString {
        var localizedRegionName: String?
        if let region = SettingsPrefs.getRegionPref() {
            localizedRegionName = RegionalSettingsTableViewController.getLocalizedRegionName(region)
        } else {
            localizedRegionName = RegionalSettingsTableViewController.getLocalizedRegionName(SettingsPrefs.getDefaultRegion())
            
        }
        return NSAttributedString(string: localizedRegionName!)
    }
    
    override var accessibilityIdentifier: String? { return "Search Results for" }
    
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        let title = NSLocalizedString("Search Results for", tableName: "Cliqz" , comment: "[Settings] Search Results for")
        super.init(title: NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = RegionalSettingsTableViewController()
        viewController.title = self.title?.string
        navigationController?.pushViewController(viewController, animated: true)
        
        // log Telemerty signal
        let blcokAdsSingal = TelemetryLogEventType.Settings("main", "click", "search_results_from", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(blcokAdsSingal)
    }
}




//Cliqz: Added new settings item sending local data
class ExportLocalDatabaseSetting: Setting, MFMailComposeViewControllerDelegate {
    
    let profile: Profile
    
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        
        super.init(title: NSAttributedString(string: "Export Local Database", attributes: [NSForegroundColorAttributeName: UIConstants.HighlightBlue]))
    }
    
    override func onClick(_ navigationController: UINavigationController?) {
        let localDataBaseFile = try! profile.files.getAndEnsureDirectory()
		let path = URL(fileURLWithPath: localDataBaseFile)
		if let data = try? Data(contentsOf: path.appendingPathComponent("browser.db"), options: []) {
			if MFMailComposeViewController.canSendMail() {
				let mailComposeViewController = configuredMailComposeViewController(data: data)
				navigationController?.present(mailComposeViewController, animated: true, completion: nil)
			}
        }
    }
    
    func configuredMailComposeViewController(data: Data) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setSubject("CLIQZ Local Database")
        mailComposerVC.addAttachmentData(data, mimeType: "application/sqlite", fileName: "browser.sqlite")
        
        return mailComposerVC
    }
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

class LimitMobileDataUsageSetting: Setting {
    
    let profile: Profile
    
    override var style: UITableViewCellStyle { return .value1 }
    
    override var status: NSAttributedString {
        return NSAttributedString(string: SettingsPrefs.getLimitMobileDataUsagePref() ? Setting.onStatus : Setting.offStatus)
    }
    
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        
        let title = NSLocalizedString("Limit Mobile Data Usage", tableName: "Cliqz", comment: "[Settings] Limit Mobile Data Usage")
        super.init(title: NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }
    
    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = LimitMobileDataUsageTableViewController()
        viewController.title = self.title?.string
        navigationController?.pushViewController(viewController, animated: true)
        
        // log Telemerty signal
        let limitMobileDataUsageSingal = TelemetryLogEventType.Settings("main", "click", viewController.getViewName(), nil, nil)
        TelemetryLogger.sharedInstance.logEvent(limitMobileDataUsageSingal)
    }
}


class AutoForgetTabSetting: Setting {
    
    let profile: Profile
    
    override var style: UITableViewCellStyle { return .value1 }
    
    override var status: NSAttributedString {
        return NSAttributedString(string: SettingsPrefs.getAutoForgetTabPref() ? Setting.onStatus : Setting.offStatus)
    }
    
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        
        let title = NSLocalizedString("Automatic Forget Tab", tableName: "Cliqz", comment: " [Settings] Automatic Forget Tab")
        super.init(title: NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }
    
    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = AutoForgetTabTableViewController()
        viewController.title = self.title?.string
        navigationController?.pushViewController(viewController, animated: true)
        
        // log Telemerty signal
        let limitMobileDataUsageSingal = TelemetryLogEventType.Settings("main", "click", viewController.getViewName(), nil, nil)
        TelemetryLogger.sharedInstance.logEvent(limitMobileDataUsageSingal)
    }
}


class CliqzConnectSetting: Setting {
    
    let profile: Profile
    
    
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        
        let title = NSLocalizedString("Connect", tableName: "Cliqz", comment: "[Settings] Connect")
        super.init(title: NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }
    
    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = ConnectTableViewController()
        viewController.title = self.title?.string
        navigationController?.pushViewController(viewController, animated: true)
        
        // log Telemerty signal
        let connectSingal = TelemetryLogEventType.Settings("main", "click", "connect", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(connectSingal)
    }
}
