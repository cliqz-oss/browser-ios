/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SearchEnginePicker: UITableViewController {
    weak var delegate: SearchEnginePickerDelegate?
    var engines: [OpenSearchEngine]!
    var selectedSearchEngineName: String?
    
    // Cliqz: added to calculate the duration spent on search settings view
    var settingsOpenTime : Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Cliqz: record settingsOpenTime
        settingsOpenTime = Date.getCurrentMillis()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return engines.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let engine = engines[indexPath.item]
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
        cell.textLabel?.text = engine.shortName
        cell.imageView?.image = engine.image.createScaled(CGSize(width: OpenSearchEngine.PreferredIconSize, height: OpenSearchEngine.PreferredIconSize))
        if engine.shortName == selectedSearchEngineName {
			// Cliqz: Mark selected the row of default search engine
			self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        }
		cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let engine = engines[indexPath.item]
        delegate?.searchEnginePicker(self, didSelectSearchEngine: engine)
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCellAccessoryType.checkmark
        
        // Cliqz: log telementry signal for changing default search engine
        let settingsBackSignal = TelemetryLogEventType.Settings("select_se", "click", engine.shortName, nil, nil)
        TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCellAccessoryType.none
	}

    func cancel() {
        delegate?.searchEnginePicker(self, didSelectSearchEngine: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Cliqz: log back telemetry singal for search settings view
        if let openTime = settingsOpenTime {
            let duration = Int(Date.getCurrentMillis() - openTime)
            let settingsBackSignal = TelemetryLogEventType.Settings("select_se", "click", "back", nil, duration)
            TelemetryLogger.sharedInstance.logEvent(settingsBackSignal)
            settingsOpenTime = nil
        }
    }
}
