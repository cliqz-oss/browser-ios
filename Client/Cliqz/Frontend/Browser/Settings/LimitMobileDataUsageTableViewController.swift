//
//  LimitMobileDataUsageTableViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 5/9/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class LimitMobileDataUsageTableViewController: SubSettingsTableViewController {
    
    private let toggleTitles = [
        NSLocalizedString("Limit Mobile Data Usage", tableName: "Cliqz", comment: "[Settings] Limit Mobile Data Usage")
    ]
    
    private let sectionFooters = [
        NSLocalizedString("Download videos on Wi-Fi Only", tableName: "Cliqz", comment: "[Settings -> Limit Mobile Data Usage] toogle footer")
    ]
    
    private lazy var toggles: [Bool] = {
        return [SettingsPrefs.getLimitMobileDataUsagePref()]
    }()
    
    override func getSectionFooter(section: Int) -> String {
        guard section < sectionFooters.count else {
            return ""
        }
        return sectionFooters[section]
    }
    
    override func getViewName() -> String {
        //TODO: Connect Telemetry
        return "limit_mobile_data_usage"
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
        let target = "limit_mobile_data_usage"
        let state = toggle.isOn == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.Settings("limit_mobile_data_usage", "click", target, state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
    }
    
    private func saveToggles() {
        SettingsPrefs.updateLimitMobileDataUsagePref(self.toggles[0])
    }
}
