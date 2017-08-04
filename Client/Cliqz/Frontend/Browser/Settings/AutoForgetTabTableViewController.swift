//
//  AutoForgetTabTableViewController.swift
//  Client
//
//  Created by Tim Palade on 7/24/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class AutoForgetTabTableViewController: SubSettingsTableViewController {
    
    private let toggleTitles = [
        NSLocalizedString("Automatic Forget Tab", tableName: "Cliqz", comment: " [Settings] Automatic Forget Tab")
    ]
    
    private let sectionFooters = [
        NSLocalizedString("Websites which are known to contain explicit content are automatically opened in Forget Tabs. Visits to such websites are therefore not saved to your history.", tableName: "Cliqz", comment: "[Settings -> AutoForget Tab] toogle footer")
    ]
    
    private lazy var toggles: [Bool] = {
        return [SettingsPrefs.getAutoForgetTabPref()]
    }()
    
    override func getSectionFooter(section: Int) -> String {
        guard section < sectionFooters.count else {
            return ""
        }
        return sectionFooters[section]
    }
    
    override func getViewName() -> String {
        return "auto_forget_tab"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = getUITableViewCell()
        
        cell.textLabel?.text = toggleTitles[indexPath.row]
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: #selector(switchValueChanged(_:)), for: UIControlEvents.valueChanged)
        control.isOn = toggles[indexPath.row]
        cell.accessoryView = control
        cell.selectionStyle = .none
        cell.isUserInteractionEnabled = true
        cell.textLabel?.textColor = UIColor.black
        control.isEnabled = true
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    @objc func switchValueChanged(_ toggle: UISwitch) {
        
        self.toggles[toggle.tag] = toggle.isOn
        saveToggles()
        self.tableView.reloadData()
        
        // log telemetry signal
        let state = toggle.isOn == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.Settings(getViewName(), "click", "enable", state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
    }
    
    private func saveToggles() {
        SettingsPrefs.updateAutoForgetTabPref(self.toggles[0])
    }
}

