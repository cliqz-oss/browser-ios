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
    override func onClick(navigationController: UINavigationController?) {
        let searchEnginePicker = SearchEnginePicker()
        // Order alphabetically, so that picker is always consistently ordered.
        // Every engine is a valid choice for the default engine, even the current default engine.
        searchEnginePicker.engines = profile.searchEngines.orderedEngines.sort { e, f in e.shortName < f.shortName }
        searchEnginePicker.delegate = self
        searchEnginePicker.selectedSearchEngineName = profile.searchEngines.defaultEngine.shortName
        navigationController?.pushViewController(searchEnginePicker, animated: true)
        
        let searchEngineSingal = TelemetryLogEventType.Settings("main", "click", "search_engine", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(searchEngineSingal)
    }
    
    func searchEnginePicker(searchEnginePicker: SearchEnginePicker?, didSelectSearchEngine engine: OpenSearchEngine?) -> Void {
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
    
    override var url: NSURL? {
        return NSURL(string: "https://cliqz.com/legal")
    }
    
    override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
        // log Telemerty signal
        let imprintSingal = TelemetryLogEventType.Settings("main", "click", "imprint", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(imprintSingal)
    }
}

//Cliqz: Added new settings item for Human Web
class HumanWebSetting: Setting {
    
    let profile: Profile
    
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        
        let humanWebTitle = NSLocalizedString("Human Web", tableName: "Cliqz", comment: "Label used as an item in Settings. When touched it will open a Human Web settings")
        super.init(title: NSAttributedString(string: humanWebTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }
    
    override func onClick(navigationController: UINavigationController?) {
        let viewController = HumanWebSettingsTableViewController()
        viewController.profile = self.profile
        navigationController?.pushViewController(viewController, animated: true)
        // log Telemerty signal
        let humanWebSingal = TelemetryLogEventType.Settings("main", "click", "human_web", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(humanWebSingal)
    }
}

class TestReact: Setting {
    
    let profile: Profile
    
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        
        let reactTitle = "Test React"
        super.init(title: NSAttributedString(string: reactTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }
    
    override func onClick(navigationController: UINavigationController?) {
        let viewController = UIViewController()
        viewController.view = Engine.sharedInstance.rootView

//        navigationController?.presentViewController(viewController, animated: true, completion: nil)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

//Cliqz: Added new settings item for Ad Blocker
class AdBlockerSetting: Setting {
    
    let profile: Profile
    
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        
        let blockAdsTitle = NSLocalizedString("Block Ads", tableName: "Cliqz", comment: "Label used as an item in Settings. When touched it will open a Block Ads settings")
        super.init(title: NSAttributedString(string: blockAdsTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }
    
    override func onClick(navigationController: UINavigationController?) {
        let viewController = AdBlockerSettingsTableViewController()
        viewController.profile = self.profile
        navigationController?.pushViewController(viewController, animated: true)
        
        // log Telemerty signal
        let blcokAdsSingal = TelemetryLogEventType.Settings("main", "click", "block_ads", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(blcokAdsSingal)
    }
}

//Cliqz: Added Settings for redirecting to feedback page
class SendCliqzFeedbackSetting: Setting {
    
    override init(title: NSAttributedString? = nil, delegate: SettingsDelegate?, enabled: Bool? = nil) {
        super.init(title: title, delegate: delegate, enabled: enabled)
        self.delegate = delegate
    }
    
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("FAQs & Support", tableName: "Cliqz", comment: "Menu item in settings used to open FAQs & Support cliqz url where people can submit feedback"),attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }
    
    override var url: NSURL? {
        return NSURL(string: "https://cliqz.com/support")
    }
    
    override func onClick(navigationController: UINavigationController?) {
        navigationController?.dismissViewControllerAnimated(true, completion: {})
        self.delegate?.settingsOpenURLInNewTab(self.url!)
        
        // Cliqz: log telemetry signal
        let contactSignal = TelemetryLogEventType.Settings("main", "click", "contact", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(contactSignal)
    }
    
}

//Cliqz: Added Setting for redirecting to report form
class ReportFormSetting: Setting {
    
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Report Website", tableName: "Cliqz", comment: "Menu item in settings used to redirect to Report Page where people can report pages"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }
    
    override var url: NSURL? {
        if let languageCode = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) where languageCode as! String == "de"{
            return NSURL(string: "https://cliqz.com/report-url")
        }
        return NSURL(string: "https://cliqz.com/en/report-url")
    }
    
    override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
        
        // Cliqz: log telemetry signal
        let contactSignal = TelemetryLogEventType.Settings("main", "click", "contact", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(contactSignal)
    }
    
}

// Cliqz: Custom Bool settings for News Push Notifications
class EnablePushNotifications: BoolSetting {
	
	@objc override func switchValueChanged(control: UISwitch) {
		super.switchValueChanged(control)
		if control.on {
			NewsNotificationPermissionHelper.sharedInstance.enableNewsNotifications()
        } else {
			NewsNotificationPermissionHelper.sharedInstance.disableNewsNotifications()
		}
	}

}

// Cliqz: setting to reset top sites
class ShowBlockedTopSitesSetting: Setting {
    
	let profile: Profile
	
	init(settings: SettingsTableViewController) {
		self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Show blocked topsites", tableName: "Cliqz", comment: "Show blocked top-sites from settings"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override func onClick(navigationController: UINavigationController?) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Show blocked topsites", tableName: "Cliqz", comment: "Title of the 'Show blocked top-sites' alert"),
            message: NSLocalizedString("All blocked topsites will be shown on the start page again.", tableName: "Cliqz", comment: "Text of the 'Show blocked top-sites' alert"),
            preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Cliqz", comment: "Cancel button in the 'Show blocked top-sites' alert"), style: .Cancel) { (action) in
                // log telemetry signal
                let cancelSignal = TelemetryLogEventType.Settings("restore_topsites", "click", "cancel", nil, nil)
                TelemetryLogger.sharedInstance.logEvent(cancelSignal)
            })
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("OK", tableName: "Cliqz", comment: "OK button in the 'Show blocked top-sites' alert"), style: .Default) { (action) in
                // reset top-sites
				self.profile.history.deleteAllHiddenTopSites()
				
                // log telemetry signal
                let confirmSignal = TelemetryLogEventType.Settings("restore_topsites", "click", "confirm", nil, nil)
                TelemetryLogger.sharedInstance.logEvent(confirmSignal)

            })
        navigationController?.presentViewController(alertController, animated: true, completion: nil)
        
        // log telemetry signal
        let restoreTopsitesSignal = TelemetryLogEventType.Settings("main", "click", "restore_topsites", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(restoreTopsitesSignal)
    }
}

// Cliqz: settings entry for showing Extension version
class ExtensionVersionSetting : VersionSetting {
    
    override var title: NSAttributedString? {
        let extensionVersion = "Extension: \(AppStatus.sharedInstance.extensionVersion)"
        return NSAttributedString(string: extensionVersion, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }
    
}


// Opens the search settings pane
class RegionalSetting: Setting {
    let profile: Profile
    
    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }
    
    override var style: UITableViewCellStyle { return .Value1 }
    
    override var status: NSAttributedString {
        var localizedRegionName: String?
        if let region = SettingsPrefs.getRegionPref() {
            localizedRegionName = RegionalSettingsTableViewController.getLocalizedRegionName(region)
        } else {
            localizedRegionName = RegionalSettingsTableViewController.getLocalizedRegionName(SettingsPrefs.getDefaultRegion())
            
        }
        return NSAttributedString(string: localizedRegionName!)
    }
    
    override var accessibilityIdentifier: String? { return "Search Results from" }
    
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Search Results from", tableName: "Cliqz" , comment: "Search Results from"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override func onClick(navigationController: UINavigationController?) {
        let viewController = RegionalSettingsTableViewController()
        navigationController?.pushViewController(viewController, animated: true)
        
        // log Telemerty signal
        let blcokAdsSingal = TelemetryLogEventType.Settings("main", "click", "search_results_from", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(blcokAdsSingal)
    }
}


