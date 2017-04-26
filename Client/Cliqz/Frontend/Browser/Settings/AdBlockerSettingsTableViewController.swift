//
//  AdBlockerSettingsTableViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 7/20/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class AdBlockerSettingsTableViewController: SubSettingsTableViewController {
    
    private let toggleTitles = [
        NSLocalizedString("Block Ads", tableName: "Cliqz", comment: "[Settings -> Block Ads] Block Ads"),
        NSLocalizedString("Fair Mode", tableName: "Cliqz", comment: "[Settings -> Block Ads] Fair Mode")
    ]
    
    private let sectionFooters = [
        NSLocalizedString("Block Ads footer", tableName: "Cliqz", comment: "[Settings -> Block Ads] Block Ads footer"),
        NSLocalizedString("Fair Mode footer", tableName: "Cliqz", comment: "[Settings -> Block Ads] Fair Mode footer")
    ]
    
    private lazy var toggles: [Bool] = {
		return [SettingsPrefs.getAdBlockerPref(), SettingsPrefs.getFairBlockingPref()]
    }()

    override func getSectionFooter(section: Int) -> String {
        guard section < sectionFooters.count else {
            return ""
        }
        return sectionFooters[section]
    }
    
    override func getViewName() -> String {
        return "block_ads"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = getUITableViewCell()
        
        cell.textLabel?.text = toggleTitles[indexPath.section]
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: #selector(AdBlockerSettingsTableViewController.switchValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        control.on = toggles[indexPath.section]
        cell.accessoryView = control
        cell.selectionStyle = .None
        control.tag = indexPath.section
        
        if self.toggles[0] == false && indexPath.section == 1 {
            cell.userInteractionEnabled = false
            cell.textLabel?.textColor = UIColor.grayColor()
            control.enabled = false
        } else {
            cell.userInteractionEnabled = true
            cell.textLabel?.textColor = UIColor.blackColor()
            control.enabled = true
        }
        
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.toggles[0].boolValue {
            return 2
        }
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 0
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    @objc func switchValueChanged(toggle: UISwitch) {
        
        self.toggles[toggle.tag] = toggle.on
        saveToggles()
        self.tableView.reloadData()
        
        // log telemetry signal
        let target = toggle.tag == 0 ? "enable" : "fair_blocking"
        let state = toggle.on == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.Settings("block_ads", "click", target, state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
	}

    private func saveToggles() {
        SettingsPrefs.updateAdBlockerPref(self.toggles[0])
		SettingsPrefs.updateFairBlockingPref(self.toggles[1])
	}

}
