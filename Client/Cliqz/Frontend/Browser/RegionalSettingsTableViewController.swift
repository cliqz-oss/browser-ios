//
//  RegionalSettingsTableViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 1/31/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class RegionalSettingsTableViewController: UITableViewController {

    let regions = ["DE", "FR", "US"]

    var selectedRegion: String {
        get{
            if let region = SettingsPrefs.getRegionPref() {
                return region
            }
            return SettingsPrefs.getDefaultRegion()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Search Results from", tableName: "Cliqz" , comment: "Search Results from")
        
        self.tableView.separatorColor = UIConstants.TableViewSeparatorColor
        self.tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor

        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 100))
        footer.showBottomBorder = false
        self.tableView.tableFooterView = footer
        footer.titleLabel.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regions.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let region = regions[indexPath.item]
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.textLabel?.text = RegionalSettingsTableViewController.getLocalizedRegionName(region)
        
        if region == selectedRegion {
            // Cliqz: Mark selected the row of default search engine
            self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        cell.selectionStyle = .None
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let region = regions[indexPath.item]
        SettingsPrefs.updateRegionPref(region)
        
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
