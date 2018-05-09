//
//  SendTelemetrySetttingsController.swift
//  Client
//
//  Created by Sahakyan on 5/8/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import Foundation

class SendTelemetrySettingsController: SubSettingsTableViewController {
	
	private lazy var toggle: Bool = SettingsPrefs.shared.getSendTelemetryPref()
	
	override func getSectionFooter(section: Int) -> String {
		return NSLocalizedString("Send Telemetry footer", tableName: "Cliqz", comment: "[Settings -> Send Telemetry] Footer text")
	}
	
	override func getViewName() -> String {
		return "send_telemetry"
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = getUITableViewCell()
		cell.textLabel?.text = self.title
		let control = UISwitch()
		control.onTintColor = UIConstants.ControlTintColor
		control.addTarget(self, action: #selector(switchValueChanged(_:)), for: UIControlEvents.valueChanged)
		control.isOn = toggle
		control.accessibilityLabel = "send telemetry"
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
		SettingsPrefs.shared.updateSendTelemetryPref(self.toggle)
		
		// log telemetry signal
//		let state = toggle.isOn == true ? "off" : "on" // we log old value
	}
}
