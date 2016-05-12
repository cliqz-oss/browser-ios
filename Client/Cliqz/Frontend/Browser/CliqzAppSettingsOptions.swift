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
    }
    
    func searchEnginePicker(searchEnginePicker: SearchEnginePicker, didSelectSearchEngine searchEngine: OpenSearchEngine?) {
        if let engine = searchEngine {
            profile.searchEngines.defaultEngine = engine
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
    }
}

//Cliqz: Added new settings item for Human Web
class HumanWebSetting: Setting {
    
    let profile: Profile
    
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        
        let humanWebTitle = NSLocalizedString("Human Web", tableName: "", comment: "Label used as an item in Settings. When touched it will open a Human Web settings")
        super.init(title: NSAttributedString(string: humanWebTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }
    
    override func onClick(navigationController: UINavigationController?) {
        let viewController = HumanWebSettingsTableViewController()
        viewController.profile = self.profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

//Cliqz: Added Settings for sending email feedback
class SendCliqzFeedbackSetting: SendFeedbackSetting, MFMailComposeViewControllerDelegate {
    
    override func onClick(navigationController: UINavigationController?) {
        if MFMailComposeViewController.canSendMail() {
            let emailViewController = MFMailComposeViewController()
            emailViewController.setSubject(NSLocalizedString("Feedback to iOS Cliqz Browser", tableName: "Cliqz", comment: "Send Feedback Email Subject"))
            emailViewController.setToRecipients(["feedback@cliqz.com"])
            emailViewController.mailComposeDelegate = self
            let footnote = NSLocalizedString("Feedback to Cliqz Browser (Version %@) for iOS (Version %@) from %@", tableName: "Cliqz", comment: "Footnote message for feedback")
            emailViewController.setMessageBody(String(format: "\n\n" + footnote, AppStatus.sharedInstance.getCurrentAppVersion(), UIDevice.currentDevice().systemVersion, UIDevice.currentDevice().deviceType.rawValue), isHTML: false)
            navigationController?.presentViewController(emailViewController, animated: false, completion: nil)
        } else {
            let alertController = UIAlertController(
                title: NSLocalizedString("No Email account title", tableName: "Cliqz", comment: "Title for No Email account pop-up"),
                message: NSLocalizedString("No Email account message", tableName: "Cliqz", comment: "Text for the missing email account for sending feedback pop-up"),
                preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .Default, handler: nil))
            navigationController?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}

// Cliqz: Custom Bool settings for News Push Notifications
class EnablePushNotifications: BoolSetting {
	
	@objc override func switchValueChanged(control: UISwitch) {
		super.switchValueChanged(control)
		if control.on {
			let notificationSettings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Badge, UIUserNotificationType.Sound, UIUserNotificationType.Alert], categories: nil)
			UIApplication.sharedApplication().registerForRemoteNotifications()
			UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
            TelemetryLogger.sharedInstance.logEvent(.NewsNotification("enable"))
		} else {
			UIApplication.sharedApplication().unregisterForRemoteNotifications()
            TelemetryLogger.sharedInstance.logEvent(.NewsNotification("disalbe"))
		}
	}

}

// Cliqz: setting to reset top sites
class ShowBlockedTopSitesSetting: Setting {
    
    init() {
        super.init(title: NSAttributedString(string: NSLocalizedString("Show blocked topsites", tableName: "Cliqz", comment: "Show blocked top-sites from settings"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }
    
    override func onClick(navigationController: UINavigationController?) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Show blocked topsites", tableName: "Cliqz", comment: "Title of the 'Show blocked top-sites' alert"),
            message: NSLocalizedString("All blocked topsites will be shown on the start page again.", tableName: "Cliqz", comment: "Text of the 'Show blocked top-sites' alert"),
            preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Cliqz", comment: "Cancel button in the 'Show blocked top-sites' alert"), style: .Cancel) { (action) in
                // Do nothing.
            })
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("OK", tableName: "Cliqz", comment: "OK button in the 'Show blocked top-sites' alert"), style: .Default) { (action) in
                // reset top-sites
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationShowBlockedTopSites, object: nil)

            })
        navigationController?.presentViewController(alertController, animated: true, completion: nil)
    }
}