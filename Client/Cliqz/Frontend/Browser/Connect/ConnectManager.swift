//
//  ConnectManager.swift
//  Client
//
//  Created by Mahmoud Adam on 5/10/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit

let SendTabNotification = NSNotification.Name(rawValue: "mobile-pairing:openTab")
let DownloadVideoNotification = NSNotification.Name(rawValue: "mobile-pairing:downloadVideo")
let PushPairingDataNotification = NSNotification.Name(rawValue: "mobile-pairing:pushPairingData")
let NotifyPairingErrorNotification = NSNotification.Name(rawValue: "mobile-pairing:notifyPairingError")
let NotifyPairingSuccessNotification = NSNotification.Name(rawValue: "mobile-pairing:notifyPairingSuccess")
let RefreshConnectionsNotification = NSNotification.Name(rawValue: "RefreshConnections")

enum ConnectionStatus {
    case Connected
    case Pairing
    case Disconnected
    
    init(string: String) {
        switch string.lowercased() {
        case "connected": self = .Connected
        case "pairing": self = .Pairing
        case "disconnected": self = .Disconnected
        default: self = .Disconnected
        }
    }
}

class Connection: NSObject {
    var id: String!
    var name: String?
    var status: ConnectionStatus!
    
}

class ConnectManager: NSObject {
    
    static let sharedInstance = ConnectManager()
    private var connections: [Connection] = []
    private var lastScannedQrCode: String?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(updateConnections), name: PushPairingDataNotification, object: nil)
    }
    
    deinit {
        // Cliqz: removed observers for Connect features
        NotificationCenter.default.removeObserver(self, name: PushPairingDataNotification, object: nil)
        
    }
    // MARK: - Public APIs
    func refresh() {
        
    }
    
    func getConnections() -> [Connection] {
        return connections
    }
    
    func qrcodeScanned(_ qrCode: String) {
        lastScannedQrCode = qrCode
        Engine.sharedInstance.receiveQRValue(qrCode)
    }
    
    func retryLastConnection() {
        if let lastScannedQrCode = self.lastScannedQrCode {
            qrcodeScanned(lastScannedQrCode)
        }
    }
    
    func removeConnection(_ connection: Connection?) {
        if let connection = connection {
            Engine.sharedInstance.unpairDevice(connection.id)
        }
    }
    
    func renameConnection(_ connection: Connection?, newName: String) {
        if let connection = connection {
            Engine.sharedInstance.renameDevice(connection.id, newName: newName)
        }
    }
    
    func requestPairingData() {
        Engine.sharedInstance.requestPairingData()
    }
    
    func isDeviceSupported() -> Bool {
        if #available(iOS 10.0, *) {
            return true
        }
        return !UIDevice.current.modelName.contains("iPhone 5")
    }
    //MARK: - Private Helpers
    @objc private func updateConnections(notification: NSNotification) {
        guard let pairingData = notification.object as? [String: AnyObject],  let devices = pairingData["devices"] as? [[String: String]] else {
            return
        }

        connections.removeAll()
        for device in devices {
            if let id = device["id"], let status = device["status"] {
                let connection = Connection()
                connection.name = device["name"] ?? NSLocalizedString("Connecting to Desktop", tableName: "Cliqz", comment: "[Settings -> Connect] pending connection title")
                connection.id = id
                connection.status = ConnectionStatus(string: status)
                connections.append(connection)
            }
        }
        NotificationCenter.default.post(name: RefreshConnectionsNotification, object: nil)
    }
    
}
