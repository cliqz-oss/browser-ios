//
//  AboutSettingsTableViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 4/26/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class AboutSettingsTableViewController: SubSettingsTableViewController {
    
    private let settings = [PrivacyPolicySetting(), EulaSetting(), LicenseAndAcknowledgementsSetting()]
    private let info = [("Version", AppStatus.sharedInstance.distVersion), ("Extension", AppStatus.sharedInstance.extensionVersion)]
    
    override func getViewName() -> String {
        return "about"
    }
    
    // MARK: - Table view data source
    
	override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return settings.count
        }
        #if BETA
            return 2
        #else
            return 1
        #endif
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if indexPath.section == 0 {
            cell = getUITableViewCell()
            let setting = settings[indexPath.row]
            cell.textLabel?.attributedText = setting.title
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        } else {
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: nil)
            cell.accessoryType = .none
            cell.selectionStyle = .none
            let infoTuple = info[indexPath.row]
            cell.textLabel?.text = infoTuple.0
            cell.detailTextLabel?.text = infoTuple.1
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            return
        }
        
        let setting = settings[indexPath.row]
        setting.onClick(self.navigationController)
    }

}
