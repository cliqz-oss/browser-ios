//
//  SubSettingsTableViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 4/25/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class SubSettingsTableViewController : UITableViewController {
    
    private let HeaderHeight: CGFloat = 40
    private let FooterMargin: CGFloat = 44
    private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"
    let CellIdentifier = "CellIdentifier"
    
    // added to calculate the duration spent on settings page
    var settingsOpenTime: Double?
    
    func getSectionFooter(section: Int) -> String {
        return ""
    }
    
    func getViewName() -> String {
        return ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // log telemetry signal
        if let openTime = settingsOpenTime {
            let duration = Int(NSDate.getCurrentMillis() - openTime)
            let settingsBackSignal = TelemetryLogEventType.Settings(getViewName(), "click", "back", nil, duration)
            TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
            settingsOpenTime = nil
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return HeaderHeight
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let footer = getSectionFooter(section)
        if footer.isEmpty {
           return 1
        }
        return footer.height(withConstrainedWidth: tableView.bounds.width, font: UIFont.systemFontOfSize(12.0, weight: UIFontWeightRegular)) + FooterMargin
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
        header.showTopBorder = false
        return header
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
        footer.showBottomBorder = false
        footer.showTopBorder = false
        footer.titleAlignment = .Top
        footer.titleLabel.text = getSectionFooter(section)
        return footer
    }
    
    func getUITableViewCell() -> UITableViewCell {
        var cell: UITableViewCell!
        cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: CellIdentifier)
        }
        return cell
    }
}
