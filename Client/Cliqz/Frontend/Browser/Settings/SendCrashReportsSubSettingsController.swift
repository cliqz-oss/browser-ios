//
//  SendCrashReportsSubSettingsController.swift
//  Client
//
//  Created by Mahmoud Adam on 2/13/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import UIKit

class SendCrashReportsSubSettingsController: SubSettingsTableViewController {
    
    private lazy var toggle: Bool = SettingsPrefs.shared.getSendCrashReportsPref()
    
    override func getSectionFooter(section: Int) -> String {
        return NSLocalizedString("Send Crash Reports footer", tableName: "Cliqz", comment: "[Settings -> Send Crash Reports] Footer text")
    }
    
    override func getViewName() -> String {
        return "crash_reports"
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = getUITableViewCell()
        cell.textLabel?.text = self.title
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: #selector(switchValueChanged(_:)), for: UIControlEvents.valueChanged)
        control.isOn = toggle
        control.accessibilityLabel = "crash reports"
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
        SettingsPrefs.shared.updateHumanWebPref(self.toggle)
        
        // log telemetry signal
        let state = toggle.isOn == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.Settings("crash_reports", "click", "enable", state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
    }
}


