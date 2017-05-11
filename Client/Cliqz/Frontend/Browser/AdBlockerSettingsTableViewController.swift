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
    
    fileprivate let toggleTitles =
        [NSLocalizedString("Block Ads", tableName: "Cliqz", comment: "Block Ads toogle title in Block Ads settings"),
         NSLocalizedString("Fair Blocking", tableName: "Cliqz", comment: "Fair Blocking toogle title in Block Ads settings")]
    
    fileprivate lazy var toggles: [Bool] = {
		return [SettingsPrefs.getAdBlockerPref(), SettingsPrefs.getFairBlockingPref()]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // record settingsOpenTime
        settingsOpenTime = Date.getCurrentMillis()
        
        title = NSLocalizedString("Block Ads", tableName: "Cliqz", comment: "Block Ads setting")
        tableView.register(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)
        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: FooterHeight))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer
		footer.titleLabel.text = NSLocalizedString("AdBlocking settings clarification", tableName: "Cliqz", comment: "Detailed description on Adblocking settings")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // log telemetry signal
        if let openTime = settingsOpenTime {
            let duration = Int(Date.getCurrentMillis() - openTime)
            let settingsBackSignal = TelemetryLogEventType.settings("block_ads", "click", "back", nil, duration)
            TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
            settingsOpenTime = nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
        
        if indexPath.section == SectionToggle {
            cell.textLabel?.text = toggleTitles[indexPath.item]
            let control = UISwitch()
            control.onTintColor = UIConstants.ControlTintColor
            control.addTarget(self, action: #selector(AdBlockerSettingsTableViewController.switchValueChanged(_:)), for: UIControlEvents.valueChanged)
            control.isOn = toggles[indexPath.item]
            cell.accessoryView = control
            cell.selectionStyle = .none
            control.tag = indexPath.item
            
            if self.toggles[0] == false && indexPath.item == 1 {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = UIColor.gray
                control.isEnabled = false
            } else {
                cell.isUserInteractionEnabled = true
                cell.textLabel?.textColor = UIColor.black
                control.isEnabled = true
            }
            
        } else {
            assert(indexPath.section == SectionDetails)
            cell.textLabel?.text = NSLocalizedString("What is 'fair'?", tableName: "Cliqz", comment: "More details about Fair Blocking")
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == SectionDetails else { return false }
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == SectionDetails else { return }
        let viewController = SettingsContentViewController()
        viewController.settingsTitle = NSAttributedString(string: NSLocalizedString("Fair Blocking", tableName: "Cliqz", comment: "Title of navigation controller of Fair Blocking"))
        let fairBlockingDescriptionPath = Bundle.main.path(forResource: "FairBlocking", ofType: "html")
        viewController.url = URL(fileURLWithPath: fairBlockingDescriptionPath!)
        navigationController?.pushViewController(viewController, animated: true)
        
        // log telemetry signal
        let infoSignal = TelemetryLogEventType.settings("block_ads", "click", "info", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(infoSignal)

    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return HeaderFooterHeight
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
    }

    @objc func switchValueChanged(_ toggle: UISwitch) {
        
        self.toggles[toggle.tag] = toggle.isOn
        saveToggles()
        self.tableView.reloadData()
        
        // log telemetry signal
        let target = toggle.tag == 0 ? "enable" : "fair_blocking"
        let state = toggle.isOn == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.settings("block_ads", "click", target, state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
	}

    fileprivate func saveToggles() {
        SettingsPrefs.updateAdBlockerPref(self.toggles[0])
		SettingsPrefs.updateFairBlockingPref(self.toggles[1])
	}

}
