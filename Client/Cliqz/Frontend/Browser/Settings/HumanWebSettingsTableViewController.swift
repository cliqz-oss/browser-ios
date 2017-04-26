//
//  HumanWebSettingsTableViewController.swift
//  Client
//
//  Created by Sahakyan on 2/15/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class HumanWebSettingsTableViewController: SubSettingsTableViewController {
    
	private lazy var toggle: Bool = SettingsPrefs.getHumanWebPref()
    
    override func getSectionFooter(section: Int) -> String {
        return NSLocalizedString("Human Web footer", tableName: "Cliqz", comment: "[Settings -> Human Web]Footer text for Fair Blocking section")
    }
    
    override func getViewName() -> String {
        return "human_web"
    }

    
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = getUITableViewCell()
        cell.textLabel?.text = self.title
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: #selector(HumanWebSettingsTableViewController.switchValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        control.on = toggle
        cell.accessoryView = control
        cell.selectionStyle = .None
        control.tag = indexPath.item
        
		return cell
	}
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	@objc func switchValueChanged(toggle: UISwitch) {
		self.toggle = toggle.on
        SettingsPrefs.updateHumanWebPref(self.toggle)
        
        // log telemetry signal
        let state = toggle.on == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.Settings("human_web", "click", "enable", state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
	}
}
