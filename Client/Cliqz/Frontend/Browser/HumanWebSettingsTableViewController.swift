//
//  HumanWebSettingsTableViewController.swift
//  Client
//
//  Created by Sahakyan on 2/15/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

private let SectionToggle = 0
private let SectionDetails = 1
private let HeaderFooterHeight: CGFloat = 44
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

class HumanWebSettingsTableViewController: UITableViewController {

    var profile: Profile!
    // added to calculate the duration spent on settings page
    var settingsOpenTime : Double?
	
	fileprivate lazy var toggle: Bool = SettingsPrefs.getHumanWebPref()

	override func viewDidLoad() {
        super.viewDidLoad()
        // record settingsOpenTime
        settingsOpenTime = Date.getCurrentMillis()

		title = NSLocalizedString("Human Web", tableName: "Cliqz", comment: "Navigation title in settings.")
		tableView.register(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)
		tableView.separatorColor = UIConstants.TableViewSeparatorColor
		tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
		let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: HeaderFooterHeight))
		footer.showBottomBorder = false
		tableView.tableFooterView = footer
	}

    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // log telemetry signal
        if let openTime = settingsOpenTime {
            let duration = Int(Date.getCurrentMillis() - openTime)
            let settingsBackSignal = TelemetryLogEventType.settings("human_web", "click", "back", nil, duration)
            TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
            settingsOpenTime = nil
        }
    }
    
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)

		if indexPath.section == SectionToggle {
			cell.textLabel?.text = NSLocalizedString("Human Web", tableName: "Cliqz", comment: "toogle title in Human web settings.")
			let control = UISwitch()
            control.onTintColor = UIConstants.ControlTintColor
            control.addTarget(self, action: #selector(HumanWebSettingsTableViewController.switchValueChanged(_:)), for: UIControlEvents.valueChanged)
			control.isOn = toggle
			cell.accessoryView = control
			cell.selectionStyle = .none
			control.tag = indexPath.item
		} else {
			assert(indexPath.section == SectionDetails)
			cell.textLabel?.text = NSLocalizedString("What is Human Web?", tableName: "Cliqz", comment: "More details about human web")
			cell.accessoryType = .disclosureIndicator
		}
		return cell
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		guard indexPath.section == SectionDetails else { return false }
		return true
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard indexPath.section == SectionDetails else { return }
		let viewController = SettingsContentViewController()
		viewController.settingsTitle = NSAttributedString(string: NSLocalizedString("Human Web", tableName: "Cliqz", comment: "Title of navigation controller of human web"))
		viewController.url = URL(string: NSLocalizedString("Human Web URL", tableName: "Cliqz", comment: "URL for detailed info for human web"))
		navigationController?.pushViewController(viewController, animated: true)
        // log telemetry signal
        let infoSignal = TelemetryLogEventType.settings("human_web", "click", "info", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(infoSignal)
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return HeaderFooterHeight
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
	}

	@objc func switchValueChanged(_ toggle: UISwitch) {
		self.toggle = toggle.isOn
        SettingsPrefs.updateHumanWebPref(self.toggle)
        
        // log telemetry signal
        let state = toggle.isOn == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.settings("human_web", "click", "enable", state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
	}
}
