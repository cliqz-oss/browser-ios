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

private let log = Logger.browserLogger

private let HistoryClearableIndex = 0

class ClearPrivateDataTableViewController: UITableViewController {
    private var clearButton: UITableViewCell?

    var profile: Profile!
    var tabManager: TabManager!

    private typealias DefaultCheckedState = Bool

    private lazy var clearables: [(clearable: Clearable, checked: DefaultCheckedState)] = {
        return [
            (HistoryClearable(profile: self.profile), true),
            // Cliqz: Added option to clear favorite history
            (FavoriteHistoryClearable(profile: self.profile), true),
            (CacheClearable(tabManager: self.tabManager), true),
            (CookiesClearable(tabManager: self.tabManager), true),
            (SiteDataClearable(tabManager: self.tabManager), true),
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

        return self.clearables.map { $0.checked }
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
            cell.textLabel?.text = clearables[indexPath.item].clearable.label
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

        func clearPrivateData() {
            let toggles = self.toggles
            self.clearables
                .enumerate()
                .flatMap { (i, pair) in
                    guard toggles[i] else {
                        return nil
                    }
                    log.debug("Clearing \(pair.clearable).")
                    return pair.clearable.clear()
                }
                .allSucceed()
                .upon { result in
                    assert(result.isSuccess, "Private data cleared successfully")
					//Cliqz Moved updating preferences part to toggles switch handler method to save changes immedietely.
//                    self.profile.prefs.setObject(self.toggles, forKey: TogglesPrefKey)

                    dispatch_async(dispatch_get_main_queue()) {
                        // Disable the Clear Private Data button after it's clicked.
                        self.clearButtonEnabled = false
                        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    }
            }
        }

        // We have been asked to clear history and we have an account.
        // (Whether or not it's in a good state is irrelevant.)
        if self.toggles[HistoryClearableIndex] && profile.hasAccount() {
            profile.syncManager.hasSyncedHistory().uponQueue(dispatch_get_main_queue()) { yes in
                // Err on the side of warning, but this shouldn't fail.
                if yes.successValue ?? true {
                    // Our local database contains some history items that have been synced.
                    // Warn the user before clearing.
                    let alert = UIAlertController.clearSyncedHistoryAlert(clearPrivateData)
                    self.presentViewController(alert, animated: true, completion: nil)
                    return
                }

                // Otherwise, just clear directly.
                clearPrivateData()
            }
        } else {
            clearPrivateData()
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
		//Cliqz Moved updating preferences part from clear button handler to here save changes immedietely.
		self.profile.prefs.setObject(self.toggles, forKey: TogglesPrefKey)

        self.tableView.reloadData()
    }
    
    private func clearQueries() {
        let includeFavorites = toggles[clearFavoriteHistoryCellIndex]
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationPrivateDataClearQueries, object: includeFavorites)
    }
}
