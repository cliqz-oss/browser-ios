/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
// Cliqz: changed the section indexes due to adding clear private data on termination at the beginning
private let SectionToggles = 1
private let SectionButton = 2
private let NumberOfSections = 3
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"
private let TogglesPrefKey = "clearprivatedata.toggles"

private let log = Logger.browserLogger

private let HistoryClearableIndex = 0
// Cliqz: added for clear private data on termination
private let SectionClearOnTermination = 0

class ClearPrivateDataTableViewController: UITableViewController {
    private var clearButton: UITableViewCell?

    var profile: Profile!
    var tabManager: TabManager!
    // Cliqz: added to calculate the duration spent on settings page
    var settingsOpenTime = 0.0

    private typealias DefaultCheckedState = Bool

    private lazy var clearables: [(clearable: Clearable, checked: DefaultCheckedState)] = {
        return [
            (HistoryClearable(profile: self.profile), true),
            // Cliqz: Added option to clear bookmarks
            (BookmarksClearable(profile: self.profile), false),
            // Cliqz: changed the default value of clearables to false
            (CacheClearable(tabManager: self.tabManager), false),
            (CookiesClearable(tabManager: self.tabManager), false),
            (SiteDataClearable(tabManager: self.tabManager), false),
        ]
    }()
    
    // Cliqz: Clear histroy and favorite items cell indexes
    let clearHistoryCellIndex = 0
    let clearFavoriteHistoryCellIndex = 1
    
    private lazy var toggles: [Bool] = {
        if var savedToggles = self.profile.prefs.arrayForKey(TogglesPrefKey) as? [Bool] {
            // Cliqz: Added option to include bookmarks items
            if savedToggles.count == 4 {
                savedToggles.insert(true, atIndex:1)
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
        
        // Cliqz: record settingsOpenTime
        settingsOpenTime = NSDate.getCurrentMillis()

        title = Strings.SettingsClearPrivateDataTitle

        tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)

        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: UIConstants.TableViewHeaderFooterHeight))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer
    }
    
    // Cliqz: log telemetry signal
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        let duration = Int(NSDate.getCurrentMillis() - settingsOpenTime)
        let settingsBackSignal = TelemetryLogEventType.Settings("private_data", "click", "back", nil, duration)
        TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)

        if indexPath.section == SectionToggles {
            cell.textLabel?.text = clearables[indexPath.item].clearable.label
            let control = UISwitch()
            control.onTintColor = UIConstants.ControlTintColor
            control.addTarget(self, action: #selector(ClearPrivateDataTableViewController.switchValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
            control.on = toggles[indexPath.item]
            cell.accessoryView = control
            cell.selectionStyle = .None
            control.tag = indexPath.item
            
        } else if indexPath.section == SectionClearOnTermination {
            // Cliqz: clear private data on termination
            cell.textLabel?.text = NSLocalizedString("Clear Private data on termination", tableName: "Cliqz", comment: "Settings item for clearing private data on termination")
            let control = UISwitch()
            control.addTarget(self, action: #selector(ClearPrivateDataTableViewController.clearDataOnTerminationChangedValue(_:)), forControlEvents: UIControlEvents.ValueChanged)
            control.on = SettingsPrefs.getClearDataOnTerminatingPref()
            cell.accessoryView = control
            cell.selectionStyle = .None
            control.tag = indexPath.item
            cell.textLabel?.numberOfLines = 2

        } else {
            assert(indexPath.section == SectionButton)
            cell.textLabel?.text = Strings.SettingsClearPrivateDataClearButton
            cell.textLabel?.textAlignment = NSTextAlignment.Center
            cell.textLabel?.textColor = UIConstants.DestructiveRed
            cell.accessibilityTraits = UIAccessibilityTraitButton
            cell.accessibilityIdentifier = "ClearPrivateData"
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
        // Cliqz: check for clear private data on termination
        assert(section == SectionButton || section == SectionClearOnTermination)
        return 1
    }

    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard indexPath.section == SectionButton else { return false }

        // Highlight the button only if it's enabled.
        return clearButtonEnabled
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == SectionButton else { return }

        func clearPrivateData(action: UIAlertAction) {
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

                    // Cliqz Moved updating preferences part to toggles switch handler method to save changes immedietely.
                    //                    self.profile.prefs.setObject(self.toggles, forKey: TogglesPrefKey)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        // Disable the Clear Private Data button after it's clicked.
                        self.clearButtonEnabled = false
                        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    }
            }
            
            // Cliqz: log telemetry signal
            let confirmSignal = TelemetryLogEventType.Settings("private_data", "click", "confirm", nil, nil)
            TelemetryLogger.sharedInstance.logEvent(confirmSignal)

        }

        // We have been asked to clear history and we have an account.
        // (Whether or not it's in a good state is irrelevant.)
        if self.toggles[HistoryClearableIndex] && profile.hasAccount() {
            profile.syncManager.hasSyncedHistory().uponQueue(dispatch_get_main_queue()) { yes in
                // Err on the side of warning, but this shouldn't fail.
                let alert: UIAlertController
                if yes.successValue ?? true {
                    // Our local database contains some history items that have been synced.
                    // Warn the user before clearing.
                    alert = UIAlertController.clearSyncedHistoryAlert(clearPrivateData)
                } else {
                    alert = UIAlertController.clearPrivateDataAlert(clearPrivateData)
                }
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
        } else {
            let alert = UIAlertController.clearPrivateDataAlert(clearPrivateData)
            self.presentViewController(alert, animated: true, completion: nil)
            
            // Cliqz: log telemetry signal
            let clearSignal = TelemetryLogEventType.Settings("private_data", "click", "clear", nil, nil)
            TelemetryLogger.sharedInstance.logEvent(clearSignal)
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UIConstants.TableViewHeaderFooterHeight
    }

    @objc func switchValueChanged(toggle: UISwitch) {
        toggles[toggle.tag] = toggle.on

        // Dim the clear button if no clearables are selected.
        clearButtonEnabled = toggles.contains(true)
        
        // Cliqz Moved updating preferences part from clear button handler to here save changes immedietely.
        self.profile.prefs.setObject(self.toggles, forKey: TogglesPrefKey)
        
        self.tableView.reloadData()
        
        // Cliqz: log telemetry signal
        let target = getTelemetrySignalTarget(toggle.tag)
        let state = toggle.on == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.Settings("private_data", "click", target, state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
    }
    // Cliqz: getting getTelemetrySignalTarget for given toggle
    func getTelemetrySignalTarget(toggleIndex: Int) -> String {
        var target = ""
        switch toggleIndex {
        case 0:
            target = "clear_history"
        case 1:
            target = "clear_favorites"
        case 2:
            target = "clear_cache";
        case 3:
            target = "clear_cookies"
        case 4:
            target = "clear_offline"
        default:
            target = "UNDEFINED"
        }
        return target;
    }
    // Cliqz Moved updating preferences part from clear button handler to here save changes immedietely.
    func clearDataOnTerminationChangedValue(sender: UISwitch) {
        SettingsPrefs.updateClearDataOnTerminatingPref(sender.on)
        
        //log telemetry signal
        let state = sender.on == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.Settings("private_data", "click", "clear_on_exit", state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
    }
    
    private func clearQueries() {
        let includeFavorites = toggles[clearFavoriteHistoryCellIndex]
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationPrivateDataClearQueries, object: includeFavorites)
    }
}
