//
//  AdBlockerSettingsTableViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 7/20/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

private let SectionToggle = 0
private let SectionDetails = 1
private let HeaderFooterHeight: CGFloat = 44
private let FooterHeight: CGFloat = 100
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"


class AdBlockerSettingsTableViewController: UITableViewController {

    var profile: Profile!
    // added to calculate the duration spent on settings page
    var settingsOpenTime: Double?
    
    private let toggleTitles =
        [NSLocalizedString("Block Ads", tableName: "Cliqz", comment: "Block Ads toogle title in Block Ads settings"),
         NSLocalizedString("Fair Blocking", tableName: "Cliqz", comment: "Fair Blocking toogle title in Block Ads settings")]
    
    private lazy var toggles: [Bool] = {
		return [SettingsPrefs.getAdBlockerPref(), SettingsPrefs.getFairBlockingPref()]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // record settingsOpenTime
        settingsOpenTime = NSDate.getCurrentMillis()
        
        title = NSLocalizedString("Block Ads", tableName: "Cliqz", comment: "Block Ads setting")
        tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)
        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: FooterHeight))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer
		footer.titleLabel.text = NSLocalizedString("AdBlocking settings clarification", tableName: "Cliqz", comment: "Detailed description on Adblocking settings")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // log telemetry signal
        if let openTime = settingsOpenTime {
            let duration = Int(NSDate.getCurrentMillis() - openTime)
            let settingsBackSignal = TelemetryLogEventType.Settings("block_ads", "click", "back", nil, duration)
            TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
            settingsOpenTime = nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        
        if indexPath.section == SectionToggle {
            cell.textLabel?.text = toggleTitles[indexPath.item]
            let control = UISwitch()
            control.onTintColor = UIConstants.ControlTintColor
            control.addTarget(self, action: #selector(AdBlockerSettingsTableViewController.switchValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
            control.on = toggles[indexPath.item]
            cell.accessoryView = control
            cell.selectionStyle = .None
            control.tag = indexPath.item
            
            if self.toggles[0] == false && indexPath.item == 1 {
                cell.userInteractionEnabled = false
                cell.textLabel?.textColor = UIColor.grayColor()
                control.enabled = false
            } else {
                cell.userInteractionEnabled = true
                cell.textLabel?.textColor = UIColor.blackColor()
                control.enabled = true
            }
            
        } else {
            assert(indexPath.section == SectionDetails)
            cell.textLabel?.text = NSLocalizedString("What is 'fair'?", tableName: "Cliqz", comment: "More details about Fair Blocking")
            cell.accessoryType = .DisclosureIndicator
        }
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        return 1
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard indexPath.section == SectionDetails else { return false }
        return true
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == SectionDetails else { return }
        let viewController = SettingsContentViewController()
        viewController.settingsTitle = NSAttributedString(string: NSLocalizedString("Fair Blocking", tableName: "Cliqz", comment: "Title of navigation controller of Fair Blocking"))
        let fairBlockingDescriptionPath = NSBundle.mainBundle().pathForResource("FairBlocking", ofType: "html")
        viewController.url = NSURL(fileURLWithPath: fairBlockingDescriptionPath!)
        navigationController?.pushViewController(viewController, animated: true)
        
        // log telemetry signal
        let infoSignal = TelemetryLogEventType.Settings("block_ads", "click", "info", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(infoSignal)

    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return HeaderFooterHeight
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
    }

    @objc func switchValueChanged(toggle: UISwitch) {
        
        self.toggles[toggle.tag] = toggle.on
        saveToggles()
        self.tableView.reloadData()
        
        // log telemetry signal
        let target = toggle.tag == 0 ? "enable" : "fair_blocking"
        let state = toggle.on == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.Settings("block_ads", "click", target, state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
	}

    private func saveToggles() {
        SettingsPrefs.updateAdBlockerPref(self.toggles[0])
		SettingsPrefs.updateFairBlockingPref(self.toggles[1])
	}

}
