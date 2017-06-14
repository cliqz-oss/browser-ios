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
    private static let DefaultCellIdentifier = "DefaultCellIdentifier"
    
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: SubSettingsTableViewController.DefaultCellIdentifier)
        tableView.register(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: SubSettingsTableViewController.DefaultCellIdentifier)
        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.settingsOpenTime = Date.getCurrentMillis()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        logHideTelemetrySignal()
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
    
    func getUITableViewCell(_ cellIdentifier: String? = SubSettingsTableViewController.DefaultCellIdentifier) -> UITableViewCell {
        var cell: UITableViewCell!
        cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier!)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier)
        }
        return cell
    }
    
    func logHideTelemetrySignal() {
        // Hide here mean that the user clicked back button to go to settings
        if let openTime = settingsOpenTime {
            let duration = Int(Date.getCurrentMillis() - openTime)
            let settingsBackSignal = TelemetryLogEventType.Settings(getViewName(), "click", "back", nil, duration)
            TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
            settingsOpenTime = nil
        }
    }
}
