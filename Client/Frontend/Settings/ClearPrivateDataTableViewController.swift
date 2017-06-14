/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
private let SectionToggles = 0
private let SectionButton = 1
private let NumberOfSections = 2
private let TogglesPrefKey = "clearprivatedata.toggles"

private let log = Logger.browserLogger

private let HistoryClearableIndex = 0

class ClearPrivateDataTableViewController: SubSettingsTableViewController {
    private var clearButton: UITableViewCell?

    var profile: Profile!
    var tabManager: TabManager!

    fileprivate typealias DefaultCheckedState = Bool

    fileprivate lazy var clearables: [(clearable: Clearable, checked: DefaultCheckedState)] = {
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
    
    fileprivate lazy var toggles: [Bool] = {
        if var savedToggles = self.profile.prefs.arrayForKey(TogglesPrefKey) as? [Bool] {
            // Cliqz: Added option to include bookmarks items
            if savedToggles.count == 4 {
                savedToggles.insert(true, at:1)
            }
            return savedToggles
        }

        return self.clearables.map { $0.checked }
    }()

    fileprivate var clearButtonEnabled = true {
        didSet {
            clearButton?.textLabel?.textColor = clearButtonEnabled ? UIConstants.HighlightBlue : UIColor.lightGray
        }
    }
    override func getSectionFooter(section: Int) -> String {
        if section == 1 {
            return NSLocalizedString("Clear Private Data footer", tableName: "Cliqz", comment: "[Settings -> Clear Private Data] Clear Private Data footer ")
        }
        return super.getSectionFooter(section: section)
    }
    
    override func getViewName() -> String {
        return "private_data"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.SettingsClearPrivateDataTitle

    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)

        if indexPath.section == SectionToggles {
            cell.textLabel?.text = clearables[indexPath.item].clearable.label
            let control = UISwitch()
            control.onTintColor = UIConstants.ControlTintColor
            control.addTarget(self, action: #selector(ClearPrivateDataTableViewController.switchValueChanged(_:)), for: UIControlEvents.valueChanged)
            control.isOn = toggles[indexPath.item]
            cell.accessoryView = control
            cell.selectionStyle = .none
            control.tag = indexPath.item
            
        } else {
            assert(indexPath.section == SectionButton)
            cell.textLabel?.text = Strings.SettingsClearPrivateDataClearButton
            cell.textLabel?.textColor = UIConstants.HighlightBlue
            cell.accessibilityTraits = UIAccessibilityTraitButton
            cell.accessibilityIdentifier = "ClearPrivateData"
            clearButton = cell
        }

        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return NumberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionToggles {
            return clearables.count
        }
        assert(section == SectionButton)
        return 1
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == SectionButton else { return false }

        // Highlight the button only if it's enabled.
        return clearButtonEnabled
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == SectionButton else { return }

        func clearPrivateData(_ action: UIAlertAction) {
            let toggles = self.toggles
            self.clearables
                .enumerated()
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
                    
                    DispatchQueue.main.async() {
                        // Disable the Clear Private Data button after it's clicked.
                        self.clearButtonEnabled = false
                        self.tableView.deselectRow(at: indexPath, animated: true)
                    }
            }
            
            // Cliqz: log telemetry signal
            let confirmSignal = TelemetryLogEventType.Settings("private_data", "click", "confirm", nil, nil)
            TelemetryLogger.sharedInstance.logEvent(confirmSignal)

        }

        // We have been asked to clear history and we have an account.
        // (Whether or not it's in a good state is irrelevant.)
        if self.toggles[HistoryClearableIndex] && profile.hasAccount() {
            profile.syncManager.hasSyncedHistory().uponQueue(DispatchQueue.main) { yes in
                // Err on the side of warning, but this shouldn't fail.
                let alert: UIAlertController
                if yes.successValue ?? true {
                    // Our local database contains some history items that have been synced.
                    // Warn the user before clearing.
                    alert = UIAlertController.clearSyncedHistoryAlert(clearPrivateData)
                } else {
                    alert = UIAlertController.clearPrivateDataAlert(clearPrivateData)
                }
                self.present(alert, animated: true, completion: nil)
                return
            }
        } else {
            let alert = UIAlertController.clearPrivateDataAlert(clearPrivateData)
            self.present(alert, animated: true, completion: nil)
            
            // Cliqz: log telemetry signal
            let clearSignal = TelemetryLogEventType.Settings("private_data", "click", "clear", nil, nil)
            TelemetryLogger.sharedInstance.logEvent(clearSignal)
        }

        tableView.deselectRow(at: indexPath, animated: false)
    }

    @objc fileprivate func switchValueChanged(_ toggle: UISwitch) {
        toggles[toggle.tag] = toggle.isOn

        // Dim the clear button if no clearables are selected.
        clearButtonEnabled = toggles.contains(true)
        
        // Cliqz Moved updating preferences part from clear button handler to here save changes immedietely.
        self.profile.prefs.setObject(self.toggles, forKey: TogglesPrefKey)
        
        self.tableView.reloadData()
        
        // Cliqz: log telemetry signal
        let target = getTelemetrySignalTarget(toggle.tag)
        let state = toggle.isOn == true ? "off" : "on" // we log old value
        let valueChangedSignal = TelemetryLogEventType.Settings("private_data", "click", target, state, nil)
        TelemetryLogger.sharedInstance.logEvent(valueChangedSignal)
    }

    // Cliqz: getting getTelemetrySignalTarget for given toggle
    func getTelemetrySignalTarget(_ toggleIndex: Int) -> String {
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
    
    fileprivate func clearQueries() {
        let includeFavorites = toggles[clearFavoriteHistoryCellIndex]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationPrivateDataClearQueries), object: includeFavorites)
    }
}
