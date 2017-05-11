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
        
        tableView.register(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // log telemetry signal
        if let openTime = settingsOpenTime {
            let duration = Int(Date.getCurrentMillis() - openTime)
            let settingsBackSignal = TelemetryLogEventType.Settings(getViewName(), "click", "back", nil, duration)
            TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
            settingsOpenTime = nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return HeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let footer = getSectionFooter(section: section)
        if footer.isEmpty {
           return 1
        }
        return footer.height(withConstrainedWidth: tableView.bounds.width, font: UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)) + FooterMargin
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
        header.showTopBorder = false
        return header
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
        footer.showBottomBorder = false
        footer.showTopBorder = false
        footer.titleAlignment = .top
        footer.titleLabel.text = getSectionFooter(section: section)
        return footer
    }
    
    func getUITableViewCell() -> UITableViewCell {
        var cell: UITableViewCell!
        cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: CellIdentifier)
        }
        return cell
    }
}
