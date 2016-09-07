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
    var settingsOpenTime = 0.0
	
	private lazy var toggle: Bool = SettingsPrefs.getHumanWebPref()

	override func viewDidLoad() {
        super.viewDidLoad()
        // record settingsOpenTime
        settingsOpenTime = NSDate.getCurrentMillis()

		title = NSLocalizedString("Human Web", tableName: "Cliqz", comment: "Navigation title in settings.")
		tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)
		tableView.separatorColor = UIConstants.TableViewSeparatorColor
		tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
		let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: HeaderFooterHeight))
		footer.showBottomBorder = false
		tableView.tableFooterView = footer
	}

    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // log telemetry signal
        let duration = Int(NSDate.getCurrentMillis() - settingsOpenTime)
        let settingsBackSignal = TelemetryLogEventType.Settings("human_web", "click", "back", nil, duration)
        TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
    }
    
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)

		if indexPath.section == SectionToggle {
			cell.textLabel?.text = NSLocalizedString("Human Web", tableName: "Cliqz", comment: "toogle title in Human web settings.")
			let control = UISwitch()
            control.onTintColor = UIConstants.ControlTintColor
            control.addTarget(self, action: #selector(HumanWebSettingsTableViewController.switchValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
			control.on = toggle
			cell.accessoryView = control
			cell.selectionStyle = .None
			control.tag = indexPath.item
		} else {
			assert(indexPath.section == SectionDetails)
			cell.textLabel?.text = NSLocalizedString("What is Human Web?", tableName: "Cliqz", comment: "More details about human web")
			cell.accessoryType = .DisclosureIndicator
		}
		return cell
	}
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		guard indexPath.section == SectionDetails else { return false }
		return true
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard indexPath.section == SectionDetails else { return }
		let viewController = SettingsContentViewController()
		viewController.settingsTitle = NSAttributedString(string: NSLocalizedString("Human Web", tableName: "Cliqz", comment: "Title of navigation controller of human web"))
		viewController.url = NSURL(string: NSLocalizedString("Human Web URL", tableName: "Cliqz", comment: "URL for detailed info for human web"))
		navigationController?.pushViewController(viewController, animated: true)
        // log telemetry signal
        let infoSignal = TelemetryLogEventType.Settings("human_web", "click", "info", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(infoSignal)
	}

	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return HeaderFooterHeight
	}

	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
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
