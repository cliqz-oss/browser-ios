//
//  RegionalSettingsTableViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 1/31/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class RegionalSettingsTableViewController: SubSettingsTableViewController {

    let regions = ["DE", "FR", "US"]
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
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regions.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let region = regions[indexPath.item]
        let cell = getUITableViewCell()
        
        cell.textLabel?.text = RegionalSettingsTableViewController.getLocalizedRegionName(region)
        
        if region == selectedRegion {
            // Cliqz: Mark selected the row of default search engine
            self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        cell.selectionStyle = .None
        return cell
    }
    
    override func getViewName() -> String {
        return telemetrySignalViewName
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let region = regions[indexPath.item]
        SettingsPrefs.updateRegionPref(region)
        
        let settingsBackSignal = TelemetryLogEventType.Settings(telemetrySignalViewName, "click", region, nil, nil)
        TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
        
        
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
        
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
    }
    
    static func getLocalizedRegionName(region: String) -> String {
        let key = "region-\(region)"
        
        return NSLocalizedString(key, tableName: "Cliqz", comment: "Localized String for specific region")
    }
    
}
