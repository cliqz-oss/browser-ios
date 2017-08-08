//
//  RegionalSettingsTableViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 1/31/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class RegionalSettingsTableViewController: SubSettingsTableViewController {

    let regions = SettingsPrefs.SearchBackendOptions
    let telemetrySignalViewName = "search_results_from"
    
    var selectedRegion: String {
        get{
            if let region = SettingsPrefs.getRegionPref() {
                return region
            }
            return SettingsPrefs.getDefaultRegion()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
	override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let region = regions[indexPath.item]
        let cell = getUITableViewCell()
        
        cell.textLabel?.text = RegionalSettingsTableViewController.getLocalizedRegionName(region)
        
        if region == selectedRegion {
            // Cliqz: Mark selected the row of default search engine
            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        }
        cell.selectionStyle = .none
        return cell
    }
    
    override func getViewName() -> String {
        return telemetrySignalViewName
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let region = regions[indexPath.item]
        SettingsPrefs.updateRegionPref(region)
        
        let settingsBackSignal = TelemetryLogEventType.Settings(telemetrySignalViewName, "click", region, nil, nil)
        TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
        
        
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCellAccessoryType.checkmark
        
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCellAccessoryType.none
    }
    
    static func getLocalizedRegionName(_ region: String) -> String {
        let key = "region-\(region)"
        
        return NSLocalizedString(key, tableName: "Cliqz", comment: "Localized String for specific region")
    }
    
}
