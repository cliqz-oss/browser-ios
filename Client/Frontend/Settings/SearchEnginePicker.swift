/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SearchEnginePicker: UITableViewController {
    weak var delegate: SearchEnginePickerDelegate?
    var engines: [OpenSearchEngine]!
    var selectedSearchEngineName: String?
    
    // Cliqz: added to calculate the duration spent on search settings view
    var settingsOpenTime = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Cliqz: record settingsOpenTime
        settingsOpenTime = NSDate.getCurrentMillis()

        navigationItem.title = NSLocalizedString("Default Search Engine", comment: "Title for default search engine picker.")

		// Cliqz: Removed LeftBarButton as we need just back button.
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: "Cancel title from search engine picker"), style: .Plain, target: self, action: #selector(SearchEnginePicker.cancel))
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return engines.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let engine = engines[indexPath.item]
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.textLabel?.text = engine.shortName
        cell.imageView?.image = engine.image.createScaled(CGSize(width: OpenSearchEngine.PreferredIconSize, height: OpenSearchEngine.PreferredIconSize))
        if engine.shortName == selectedSearchEngineName {
			// Cliqz: Mark selected the row of default search engine
			self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
		cell.selectionStyle = .None
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let engine = engines[indexPath.item]
        delegate?.searchEnginePicker(self, didSelectSearchEngine: engine)
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
        
        // Cliqz: log telementry signal for changing default search engine
        let settingsBackSignal = TelemetryLogEventType.Settings("select_se", "click", engine.shortName, nil, nil)
        TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
	}

    func cancel() {
        delegate?.searchEnginePicker(self, didSelectSearchEngine: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Cliqz: log back telemetry singal for search settings view
        let duration = Int(NSDate.getCurrentMillis() - settingsOpenTime)
        let settingsBackSignal = TelemetryLogEventType.Settings("select_se", "click", "back", nil, duration)
        TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
    }
}
