//
//  EditConnectionViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 5/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
class EditConnectionViewController: SubSettingsTableViewController {
    private let removeConnectionIndex = 0
    private let removeConnectionTitle = NSLocalizedString("Remove Connection", tableName: "Cliqz", comment: "[Settings -> Connect] remove connection")
    private let renameConnectionIndex = 1
    private let renameConnectionTitle = NSLocalizedString("Rename Connection", tableName: "Cliqz", comment: "[Settings -> Connect] rename connection")
    
    
    var connection: Connection?
    var connectionRemoved = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = connection?.name
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //MARK: - SubSettingsTableViewController implementation
    override func getSectionFooter(section: Int) -> String {
        return ""
    }
    
    override func getViewName() -> String {
        return "connection_detail"
    }
    
    //MARK: - TableVew related methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = getUITableViewCell()
        if indexPath.row == removeConnectionIndex {
            cell.textLabel?.text = removeConnectionTitle
        } else if indexPath.row == renameConnectionIndex {
            cell.textLabel?.text = renameConnectionTitle
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == removeConnectionIndex {
            removeConnection()
        } else if indexPath.row == renameConnectionIndex {
            renameConnection()
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    //MARK: - Private Helpers
    func removeConnection() {
        ConnectManager.sharedInstance.removeConnection(connection)
        connectionRemoved = true
        self.navigationController?.popViewController(animated: true)
        logAlterConnectionTelemetrySingal("remove")
    }
    
    func renameConnection() {
        let message = NSLocalizedString("Prompt description", tableName: "Cliqz", comment: "[Settings -> Connect] rename connection alert message")
        let alertController = UIAlertController(title: renameConnectionTitle, message: message, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: NSLocalizedString("Ok", tableName: "Cliqz", comment: "Ok"), style: .default) { (_) in
            guard let charCount = alertController.textFields?.count, charCount > 0 else {
                return
            }
            let textField = alertController.textFields![0]
            if let newName = textField.text, !newName.isEmpty {
                ConnectManager.sharedInstance.renameConnection(self.connection, newName: newName)
                self.title = newName
            }
            
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Cliqz", comment: "Cancel"), style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.text = self.connection?.name
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        logAlterConnectionTelemetrySingal("rename")
    }
    
    // MARK: - Telemetry
    override func logHideTelemetrySignal() {
        guard let openTime = settingsOpenTime else {
            return
        }
        var customData: [String : Any] = ["view" : getViewName(),
                                          "show_duration": Int(Date.getCurrentMillis() - openTime)]
        
        var signal: TelemetryLogEventType!
        if connectionRemoved {
            signal = .Connect("hide", customData)
        } else {
            customData["target"] = "back"
            signal = .Connect("back", customData)
        }
        TelemetryLogger.sharedInstance.logEvent(signal)
        
        settingsOpenTime = nil
    }
    
    private func logShowTelemetrySingal() {
        
        let signal = TelemetryLogEventType.Connect("show", ["view" : getViewName()])
        TelemetryLogger.sharedInstance.logEvent(signal)
        
    }
    
    private func logAlterConnectionTelemetrySingal(_ target: String) {
        
        let signal = TelemetryLogEventType.Connect("click", ["view" : getViewName(), "target" : target])
        TelemetryLogger.sharedInstance.logEvent(signal)
        
    }
    
}
