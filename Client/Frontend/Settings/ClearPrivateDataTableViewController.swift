/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

private let SectionToggles = 0
private let SectionButton = 1
private let NumberOfSections = 2
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"
private let HeaderFooterHeight: CGFloat = 44
private let TogglesPrefKey = "clearprivatedata.toggles"

class ClearPrivateDataTableViewController: UITableViewController {
    private var clearButton: UITableViewCell?

    var profile: Profile!
    var tabManager: TabManager!

    private lazy var clearables: [Clearable] = {
        return [
            HistoryClearable(profile: self.profile),
            // Cliqz: Added option to clear favorite history
            FavoriteHistoryClearable(profile: self.profile),
            CacheClearable(tabManager: self.tabManager),
            CookiesClearable(tabManager: self.tabManager),
            SiteDataClearable(tabManager: self.tabManager),
        ]
    }()
    
    // Cliqz: Clear histroy and favorite items cell indexes
    let clearHistoryCellIndex = 0
    let clearFavoriteHistoryCellIndex = 1

    private lazy var toggles: [Bool] = {
        if var savedToggles = self.profile.prefs.arrayForKey(TogglesPrefKey) as? [Bool] {
            // Cliqz: Added option to include favorite history items
            if savedToggles.count == 4 {
                savedToggles.insert(false, atIndex:1)
            }
            return savedToggles
        }

        return [Bool](count: self.clearables.count, repeatedValue: true)
    }()

    private var clearButtonEnabled = true {
        didSet {
            clearButton?.textLabel?.textColor = clearButtonEnabled ? UIConstants.DestructiveRed : UIColor.lightGrayColor()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Clear Private Data", tableName: "ClearPrivateData", comment: "Navigation title in settings.")

        tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)

        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: HeaderFooterHeight))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)

        if indexPath.section == SectionToggles {
            cell.textLabel?.text = clearables[indexPath.item].label
            let control = UISwitch()
            control.onTintColor = UIConstants.ControlTintColor
            control.addTarget(self, action: "switchValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
            control.on = toggles[indexPath.item]
            cell.accessoryView = control
            cell.selectionStyle = .None
            control.tag = indexPath.item

            // Cliqz: disalble include favorite history itmes
            if indexPath.row == clearFavoriteHistoryCellIndex && toggles[clearHistoryCellIndex] == false {
                cell.userInteractionEnabled = false
                cell.textLabel?.textColor = UIColor.grayColor()
            }
        } else {
            assert(indexPath.section == SectionButton)
            cell.textLabel?.text = NSLocalizedString("Clear Private Data", tableName: "ClearPrivateData", comment: "Button in settings that clears private data for the selected items.")
            cell.textLabel?.textAlignment = NSTextAlignment.Center
            cell.textLabel?.textColor = UIConstants.DestructiveRed
            cell.accessibilityTraits = UIAccessibilityTraitButton
            clearButton = cell
        }

        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return NumberOfSections
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionToggles {
            return clearables.count
        }

        assert(section == SectionButton)
        return 1
    }

    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard indexPath.section == SectionButton else { return false }

        // Highlight the button only if it's enabled.
        return clearButtonEnabled
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == SectionButton else { return }

        clearables
            .enumerate()
            .filter { (i, _) in toggles[i] }
            .map { (_, clearable) in clearable.clear() }
            .allSucceed()
            .upon { result in
                assert(result.isSuccess, "Private data cleared successfully")

                self.profile.prefs.setObject(self.toggles, forKey: TogglesPrefKey)

                dispatch_async(dispatch_get_main_queue()) {
                    // Disable the Clear Private Data button after it's clicked.
                    self.clearButtonEnabled = false
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }
            }
        
        // Cliqz: Clear queries history
        if toggles[clearHistoryCellIndex] == true {
            clearQueries()
        }
        
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return HeaderFooterHeight
    }

    @objc func switchValueChanged(toggle: UISwitch) {
        toggles[toggle.tag] = toggle.on

        // Dim the clear button if no clearables are selected.
        clearButtonEnabled = toggles.contains(true)
        
        // Cliqz: disable include favorite history items cell in case browsing history was disabled and refresh table to adjust cells
        if toggles[clearHistoryCellIndex] == false {
           toggles[clearFavoriteHistoryCellIndex] = false
        }
        self.tableView.reloadData()
    }
    
    private func clearQueries() {
        let includeFavorites = toggles[clearFavoriteHistoryCellIndex]
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationPrivateDataClearQueries, object: includeFavorites)
    }
}
