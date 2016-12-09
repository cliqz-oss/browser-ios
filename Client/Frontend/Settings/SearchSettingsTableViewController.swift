/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebImage
import Shared

protocol SearchEnginePickerDelegate: class {
    func searchEnginePicker(searchEnginePicker: SearchEnginePicker?, didSelectSearchEngine engine: OpenSearchEngine?) -> Void
}

class SearchSettingsTableViewController: UITableViewController {
    private let SectionDefault = 0
    private let SectionSearchAdd = 2
    private let ItemDefaultEngine = 0
    private let ItemDefaultSuggestions = 1
    private let NumberOfItemsInSectionDefault = 2
    private let SectionOrder = 1
    private let NumberOfSections = 2
    private let IconSize = CGSize(width: OpenSearchEngine.PreferredIconSize, height: OpenSearchEngine.PreferredIconSize)
    private let SectionHeaderIdentifier = "SectionHeaderIdentifier"

    private var showDeletion = false

    private var isEditable: Bool {
        // If the default engine is a custom one, make sure we have more than one since we can't edit the default. 
        // Otherwise, enable editing if we have at least one custom engine.
        let customEngineCount = model.orderedEngines.filter({$0.isCustomEngine}).count
        return model.defaultEngine.isCustomEngine ? customEngineCount > 1 : customEngineCount > 0
    }

    var model: SearchEngines!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Search", comment: "Navigation title for search settings.")

        // To allow re-ordering the list of search engines at all times.
        tableView.editing = true
        // So that we push the default search engine controller on selection.
        tableView.allowsSelectionDuringEditing = true

        tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderIdentifier)

        // Insert Done button if being presented outside of the Settings Nav stack
        if !(self.navigationController is SettingsNavigationController) {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.SettingsSearchDoneButton, style: .Done, target: self, action: #selector(SearchSettingsTableViewController.dismiss))
        }

        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer

        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.SettingsSearchEditButton, style: .Plain, target: self,
                                                                 action: #selector(SearchSettingsTableViewController.beginEditing))
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Only show the Edit button if custom search engines are in the list.
        // Otherwise, there is nothing to delete.
        navigationItem.rightBarButtonItem?.enabled = isEditable
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        setEditing(false, animated: false)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        var engine: OpenSearchEngine!

        if indexPath.section == SectionDefault {
            switch indexPath.item {
            case ItemDefaultEngine:
                engine = model.defaultEngine
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
                cell.editingAccessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                cell.accessibilityLabel = NSLocalizedString("Default Search Engine", comment: "Accessibility label for default search engine setting.")
                cell.accessibilityValue = engine.shortName
                cell.textLabel?.text = engine.shortName
                cell.imageView?.image = engine.image.createScaled(IconSize)
            case ItemDefaultSuggestions:
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
                cell.textLabel?.text = NSLocalizedString("Show Search Suggestions", comment: "Label for show search suggestions setting.")
                let toggle = UISwitch()
                toggle.onTintColor = UIConstants.ControlTintColor
                toggle.addTarget(self, action: #selector(SearchSettingsTableViewController.didToggleSearchSuggestions(_:)), forControlEvents: UIControlEvents.ValueChanged)
                toggle.on = model.shouldShowSearchSuggestions
                cell.editingAccessoryView = toggle
                cell.selectionStyle = .None

            default:
                // Should not happen.
                break
            }
        } else {
            // The default engine is not a quick search engine.
            let index = indexPath.item + 1
            engine = model.orderedEngines[index]

            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
            cell.showsReorderControl = true

            let toggle = UISwitch()
            toggle.onTintColor = UIConstants.ControlTintColor
            // This is an easy way to get from the toggle control to the corresponding index.
            toggle.tag = index
            toggle.addTarget(self, action: #selector(SearchSettingsTableViewController.didToggleEngine(_:)), forControlEvents: UIControlEvents.ValueChanged)
            toggle.on = model.isEngineEnabled(engine)

            cell.editingAccessoryView = toggle
            cell.textLabel?.text = engine.shortName
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            cell.textLabel?.minimumScaleFactor = 0.5
            cell.imageView?.image = engine.image.createScaled(IconSize)
            cell.selectionStyle = .None
        }

        // So that the seperator line goes all the way to the left edge.
        cell.separatorInset = UIEdgeInsetsZero

        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return NumberOfSections
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionDefault {
            return NumberOfItemsInSectionDefault
        } else if section == SectionSearchAdd {
            return 1
        } else {
            // The first engine -- the default engine -- is not shown in the quick search engine list.
            return model.orderedEngines.count - 1
        }
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == SectionDefault && indexPath.item == ItemDefaultEngine {
            let searchEnginePicker = SearchEnginePicker()
            // Order alphabetically, so that picker is always consistently ordered.
            // Every engine is a valid choice for the default engine, even the current default engine.
            searchEnginePicker.engines = model.orderedEngines.sort { e, f in e.shortName < f.shortName }
            searchEnginePicker.delegate = self
            searchEnginePicker.selectedSearchEngineName = model.defaultEngine.shortName
            navigationController?.pushViewController(searchEnginePicker, animated: true)
        }
        return nil
    }

    // Don't show delete button on the left.
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (indexPath.section == SectionDefault || indexPath.section == SectionSearchAdd) {
            return UITableViewCellEditingStyle.None
        }

        let index = indexPath.item + 1
        let engine = model.orderedEngines[index]
        return (self.showDeletion && engine.isCustomEngine) ? .Delete : .None
    }

    // Don't reserve space for the delete button on the left.
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    // Hide a thin vertical line that iOS renders between the accessoryView and the reordering control.
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if cell.editing {
            for v in cell.subviews {
                if v.frame.width == 1.0 {
                    v.backgroundColor = UIColor.clearColor()
                }
            }
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderIdentifier) as! SettingsTableSectionHeaderFooterView
        var sectionTitle: String
        if section == SectionDefault {
            sectionTitle = NSLocalizedString("Default Search Engine", comment: "Title for default search engine settings section.")
        } else {
            sectionTitle = NSLocalizedString("Quick-search Engines", comment: "Title for quick-search engines settings section.")
        }
        headerView.titleLabel.text = sectionTitle

        return headerView
    }

    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == SectionDefault || indexPath.section == SectionSearchAdd {
            return false
        } else {
            return true
        }
    }

    override func tableView(tableView: UITableView, moveRowAtIndexPath indexPath: NSIndexPath, toIndexPath newIndexPath: NSIndexPath) {
        // The first engine (default engine) is not shown in the list, so the indices are off-by-1.
        let index = indexPath.item + 1
        let newIndex = newIndexPath.item + 1
        let engine = model.orderedEngines.removeAtIndex(index)
        model.orderedEngines.insert(engine, atIndex: newIndex)
        tableView.reloadData()
    }

    // Snap to first or last row of the list of engines.
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        // You can't drag or drop on the default engine.
        if sourceIndexPath.section == SectionDefault || proposedDestinationIndexPath.section == SectionDefault {
            return sourceIndexPath
        }

        if sourceIndexPath.section == SectionSearchAdd || proposedDestinationIndexPath.section == SectionSearchAdd {
            return sourceIndexPath
        }

        if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
            var row = 0
            if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
                row = tableView.numberOfRowsInSection(sourceIndexPath.section) - 1
            }
            return NSIndexPath(forRow: row, inSection: sourceIndexPath.section)
        }
        return proposedDestinationIndexPath
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            let index = indexPath.item + 1
            let engine = model.orderedEngines[index]
            model.deleteCustomEngine(engine)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)

            // End editing if we are no longer edit since we've deleted all editable cells.
            if !isEditable {
                finishEditing()
            }
        }
    }

    override func setEditing(editing: Bool, animated: Bool) {
        showDeletion = editing
        UIView.performWithoutAnimation {
            self.navigationItem.rightBarButtonItem?.title = editing ? Strings.SettingsSearchDoneButton : Strings.SettingsSearchEditButton
        }
        navigationItem.rightBarButtonItem?.enabled = isEditable
        navigationItem.rightBarButtonItem?.action = editing ?
            #selector(SearchSettingsTableViewController.finishEditing) : #selector(SearchSettingsTableViewController.beginEditing)
        tableView.reloadData()
    }
}

// MARK: - Selectors
extension SearchSettingsTableViewController {
    func didToggleEngine(toggle: UISwitch) {
        let engine = model.orderedEngines[toggle.tag] // The tag is 1-based.
        if toggle.on {
            model.enableEngine(engine)
        } else {
            model.disableEngine(engine)
        }
    }

    func didToggleSearchSuggestions(toggle: UISwitch) {
        // Setting the value in settings dismisses any opt-in.
        model.shouldShowSearchSuggestionsOptIn = false
        model.shouldShowSearchSuggestions = toggle.on
    }

    func cancel() {
        navigationController?.popViewControllerAnimated(true)
    }

    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func beginEditing() {
        setEditing(true, animated: false)
    }

    func finishEditing() {
        setEditing(false, animated: false)
    }
}

extension SearchSettingsTableViewController: SearchEnginePickerDelegate {
    func searchEnginePicker(searchEnginePicker: SearchEnginePicker?, didSelectSearchEngine searchEngine: OpenSearchEngine?) {
        if let engine = searchEngine {
            model.defaultEngine = engine
            self.tableView.reloadData()
        }
        navigationController?.popViewControllerAnimated(true)
    }
}
