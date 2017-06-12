//
//  ConnectTableViewController.swift
//  Client
//
//  Created by Mahmoud Adam on 5/9/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

class ConnectTableViewController: SubSettingsTableViewController {
    
    //MARK: - Constants
    private let addConnectionIdentifier = "AddConnectionCell"
    private let addConnectionTitle = NSLocalizedString("Add Connection", tableName: "Cliqz", comment: "[Settings -> Connect] Add Connection title")
    private let addConnectionFooter = NSLocalizedString("Add Connection footer", tableName: "Cliqz", comment: "[Settings -> Connect] Add Connection footer")
    
    //MARK: - Instance Variables
    private var connections: [Connection] = []
    private var sections: [[AnyObject]] = []
    private var sectionsHeaders = [
        NSLocalizedString("Online Connections", tableName: "Cliqz", comment: "[Settings -> Connect] Online Connections Header"),
        NSLocalizedString("Offline Connections", tableName: "Cliqz", comment: "[Settings -> Connect] Offline Connections Header"),
        ""
    ]
    private var timer: Timer?
    private var navigateToDetailView = false
    
    //MARK: - View LifeCycle
    deinit {
        NotificationCenter.default.removeObserver(self, name: NotifyPairingErrorNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NotifyPairingSuccessNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(connectionFailed), name: NotifyPairingErrorNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(connectionSucceeded), name: NotifyPairingSuccessNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadConnections()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadConnections), name: RefreshConnectionsNotification, object: nil)
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(requestPairingData), userInfo: nil, repeats: true)
        logShowTelemetrySingal()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: RefreshConnectionsNotification, object: nil)
        timer?.invalidate()
    }
    
    //MARK: - SubSettingsTableViewController implementation
    override func getSectionFooter(section: Int) -> String {
        guard connections.count == 0 && section == 2 else {
            return ""
        }
        return addConnectionFooter
    }
    
    override func getViewName() -> String {
        return "start"
    }
    
    //MARK: - TableVew related methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard sections.count > section else { return 0 }
        return sections[section].count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard sections[section].count > 0 else { return 0}
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = super.tableView(tableView, viewForHeaderInSection: section) as! SettingsTableSectionHeaderFooterView
        header.titleLabel.text = sectionsHeaders[section]
        return header
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentItem = sections[indexPath.section][indexPath.row]
        
        var cell = getUITableViewCell()
        cell.accessoryType = .disclosureIndicator
        
        if currentItem as? String == addConnectionIdentifier {
            cell.textLabel?.text = addConnectionTitle
        } else if let connection = currentItem as? Connection {
           
            if connection.status == ConnectionStatus.Pairing {
                cell = getUITableViewCell("AnimatedCell")
                let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
                cell.accessoryView = activityIndicator
                activityIndicator.startAnimating()
            }
            
            cell.textLabel?.text = connection.name
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentItem = sections[indexPath.section][indexPath.row]
        if currentItem as? String == addConnectionIdentifier {
            let addConnectionViewController = AddConnectionViewController()
            self.navigationController?.pushViewController(addConnectionViewController, animated: true)
            logAddConnectionTelemetrySignal()
        } else if let connection = currentItem as? Connection  {
            let editConnectionViewController = EditConnectionViewController()
            editConnectionViewController.connection = connection
            self.navigationController?.pushViewController(editConnectionViewController, animated: true)
            logSelectConnectionTelemetrySignal(indexPath.row)
        }
        navigateToDetailView = true
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    //MARK: - Private Helpers
    @objc private func reloadConnections() {
        connections = ConnectManager.sharedInstance.getConnections()
        
        let onlineConnections = connections.filter { (connection: Connection) -> Bool in
            return connection.status != ConnectionStatus.Disconnected
        }
        let offConnections = connections.filter { (connection: Connection) -> Bool in
            return connection.status == ConnectionStatus.Disconnected
        }
        
        sections = [onlineConnections, offConnections, [addConnectionIdentifier as AnyObject]]
        self.tableView.reloadData()

    }
    
    @objc private func requestPairingData() {
        ConnectManager.sharedInstance.requestPairingData()
    }
    
    @objc private func connectionFailed() {
        let alertTitle = NSLocalizedString("Connection Failed", tableName: "Cliqz", comment: "[Connect] Connection Failed alert title")
        let alertMessage = NSLocalizedString("Sorry but devices could not be connected. Please try again.", tableName: "Cliqz", comment: "[Connect] Connection Failed alert message")
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Cliqz", comment: "Ok"), style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Retry", tableName: "Cliqz", comment: "[Connect] Retry button for Connection Failed alert"), style: .default, handler: { (_) in
            ConnectManager.sharedInstance.retryLastConnection()
        }))
        
        self.present(alertController, animated: true, completion: nil)
        
        logConnectionStatusTelemetrySingal(false)
    }
    
    @objc private func connectionSucceeded() {
        logConnectionStatusTelemetrySingal(true)
    }
    
    // MARK: - Telemetry
    override func logHideTelemetrySignal() {
        guard let openTime = settingsOpenTime else {
            return
        }
        var customData: [String : Any] = ["view" : getViewName(),
                                          "show_duration": Int(Date.getCurrentMillis() - openTime)]
        
        var action = "hide"
        if !navigateToDetailView {
            action = "click"
            customData["target"] = "back"
        }
        
        
        let hideSignal = TelemetryLogEventType.Connect(action, customData)
        TelemetryLogger.sharedInstance.logEvent(hideSignal)
        
        
        settingsOpenTime = nil
        navigateToDetailView = false
    }
    
    private func logShowTelemetrySingal() {
        let customData: [String : Any] = ["view" : getViewName(),
                                          "device_count" : connections.count,
                                          "connection_count" : sections[0].count]
        
        
        let signal = TelemetryLogEventType.Connect("show", customData)
        TelemetryLogger.sharedInstance.logEvent(signal)
        
    }
    
    private func logAddConnectionTelemetrySignal() {
        let customData: [String : Any] = ["view" : getViewName(),
                                          "target" : "add"]
        
        
        let signal = TelemetryLogEventType.Connect("click", customData)
        TelemetryLogger.sharedInstance.logEvent(signal)
        
    }
    
    private func logSelectConnectionTelemetrySignal(_ index: Int) {
        let customData: [String : Any] = ["view" : getViewName(),
                                          "target" : "connection",
                                          "index" : index]
        
        
        let signal = TelemetryLogEventType.Connect("click", customData)
        TelemetryLogger.sharedInstance.logEvent(signal)
        
    }
    
    private func logConnectionStatusTelemetrySingal(_ isSuccess: Bool) {
        
        if let openTime = settingsOpenTime {
            let customData: [String : Any] = ["view" : getViewName(),
                                              "connect_duration" : Int(Date.getCurrentMillis() - openTime),
                                              "is_success" : isSuccess]
            let signal = TelemetryLogEventType.Connect("connect", customData)
            TelemetryLogger.sharedInstance.logEvent(signal)
        }
    }
}
