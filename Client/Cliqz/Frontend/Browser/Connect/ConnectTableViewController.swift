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
    
    //MARK: - View LifeCycle
    deinit {
        NotificationCenter.default.removeObserver(self, name: NotifyPairingErrorNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(displayConnectionFailedAlert), name: NotifyPairingErrorNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadConnections()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadConnections), name: RefreshConnectionsNotification, object: nil)
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(requestPairingData), userInfo: nil, repeats: true)
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
        //TODO: Connect Telemetry
        return "connect"
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
        } else if let connection = currentItem as? Connection  {
            let editConnectionViewController = EditConnectionViewController()
            editConnectionViewController.connection = connection
            self.navigationController?.pushViewController(editConnectionViewController, animated: true)
        }
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
    
    @objc private func displayConnectionFailedAlert() {
        let alertTitle = NSLocalizedString("Connection Failed", tableName: "Cliqz", comment: "[Connect] Connection Failed alert title")
        let alertMessage = NSLocalizedString("Sorry but devices could not be connected. Please try again.", tableName: "Cliqz", comment: "[Connect] Connection Failed alert message")
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Cliqz", comment: "Ok"), style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Retry", tableName: "Cliqz", comment: "[Connect] Retry button for Connection Failed alert"), style: .default, handler: { (_) in
            ConnectManager.sharedInstance.retryLastConnection()
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
}
