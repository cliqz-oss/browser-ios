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
private let FairBlockingPrefKey = "fairBlocking"
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

public let AdBlockerPrefKey = "blockAds"

class AdBlockerSettingsTableViewController: UITableViewController {

    var profile: Profile!
    
    private let toggleTitles =
        [NSLocalizedString("Block Ads", tableName: "Cliqz", comment: "Block Ads toogle title in Block Ads settings"),
         NSLocalizedString("Fair Blocking", tableName: "Cliqz", comment: "Fair Blocking toogle title in Block Ads settings")]
    
    private lazy var toggles: [Bool] = {
        return [self.getToggleVaule(AdBlockerPrefKey, defaultValue: true),
                self.getToggleVaule(FairBlockingPrefKey, defaultValue: true)]
    }()
    
    private func getToggleVaule(preferenceKey: String, defaultValue: Bool) -> Bool {
        var toggle = defaultValue
        if let savedToggle = self.profile.prefs.boolForKey(AdBlockerPrefKey) {
            toggle = savedToggle
        }
        return toggle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Block Ads", tableName: "Cliqz", comment: "Block Ads setting")
        tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)
        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: HeaderFooterHeight))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer
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
            } else {
                cell.userInteractionEnabled = true
                cell.textLabel?.textColor = UIColor.blackColor()
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
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return HeaderFooterHeight
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
    }

    
    @objc func switchValueChanged(toggle: UISwitch) {
        
        self.toggles[toggle.tag] = toggle.on
        if toggle.on == false && toggle.tag == 0 {
            self.toggles[1] = false
        }
        
        saveToggles()
        self.tableView.reloadData()
    }
    
    private func saveToggles() {
        self.profile.prefs.setObject(self.toggles[0], forKey: AdBlockerPrefKey)
        self.profile.prefs.setObject(self.toggles[1], forKey: FairBlockingPrefKey)
        
        AntiTrackingModule.sharedInstance.setAdblockEnabled(self.toggles[0])
    }
}
