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

    
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = getUITableViewCell()
        cell.textLabel?.text = self.title
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: #selector(switchValueChanged(_:)), for: UIControlEvents.valueChanged)
        control.isOn = toggle
        control.accessibilityLabel = "Human Web Switch"
        cell.accessoryView = control
        cell.selectionStyle = .none
        control.tag = indexPath.item
        
		return cell
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	func tableView(tableView_ : UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	@objc func switchValueChanged(_ toggle: UISwitch) {
		self.toggle = toggle.isOn
        SettingsPrefs.updateHumanWebPref(self.toggle)
        
        // log telemetry signal
        let state = toggle.isOn == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.Settings("human_web", "click", "enable", state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
	}
}
