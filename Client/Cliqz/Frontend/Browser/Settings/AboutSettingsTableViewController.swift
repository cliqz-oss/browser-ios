//
//  AboutSettingsTableViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 4/26/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class AboutSettingsTableViewController: SubSettingsTableViewController {
    
    private let settings = [PrivacyPolicySetting(), LicenseAndAcknowledgementsSetting()]
    private let info = [("Version", AppStatus.sharedInstance.distVersion), ("Extension", AppStatus.sharedInstance.extensionVersion)]
    
    override func getViewName() -> String {
        return "about"
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
#if BETA
        return 2
#else
        return 1
#endif
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if indexPath.section == 0 {
            cell = getUITableViewCell()
            let setting = settings[indexPath.row]
            cell.textLabel?.attributedText = setting.title
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        } else {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: nil)
            cell.accessoryType = .None
            cell.selectionStyle = .None
            let infoTuple = info[indexPath.row]
            cell.textLabel?.text = infoTuple.0
            cell.detailTextLabel?.text = infoTuple.1
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 0 else {
            return
        }
        
        let setting = settings[indexPath.row]
        setting.onClick(self.navigationController)
    }
    
    
}
