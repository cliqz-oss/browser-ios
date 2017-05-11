//
//  NetworkReachability.swift
//  Client
//
//  Created by Mahmoud Adam on 11/9/15.
//  Copyright © 2015 Cliqz. All rights reserved.
//

import Foundation
import CoreTelephony

enum NetworkReachabilityStatus : CustomStringConvertible {
    case notReachable
    case reachableViaWiFi
    case reachableViaWWAN
    
    var description : String {
        switch self {
            case .notReachable: return "Disconnected";
            case .reachableViaWiFi: return "Wifi";
            case .reachableViaWWAN: return "WWAN";
        }
    }
}

class NetworkReachability : NSObject {
    let internetReachability = Reachability.forInternetConnection()
    var isReachable: Bool?
    var networkReachabilityStatus: NetworkReachabilityStatus?
    var lastRefreshDate: Date?
    
    //MARK: - Singltone
    static let sharedInstance = NetworkReachability()

    override init () {
        super.init()
        refreshStatus()
    }
    //MARK: - Reachability monitoring 
    func startMonitoring() {
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkReachability.reachabilityChanged(_:)), name: NSNotification.Name.reachabilityChanged, object: nil)
        internetReachability?.startNotifier()
    }
    func reachabilityChanged(_ notification: Notification) {
        if let currentReachability = notification.object as? Reachability {
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
                self.logNetworkStatusEvent()
                self.updateCurrentState(currentReachability)
            }
        }
    }
    
    func refreshStatus() {
        updateCurrentState(internetReachability!)
    }
    func logNetworkStatusEvent() {
        
        var duration: Int
        if let durationStart = lastRefreshDate {
            duration = Int(Date().timeIntervalSince(durationStart))
        } else {
            duration = 0
        }
        
        TelemetryLogger.sharedInstance.logEvent(.NetworkStatus(self.networkReachabilityStatus!.description, duration))
    }
    func isReachableViaWiFi() -> Bool {
        if let isReachable = isReachable,
            let networkReachabilityStatus = networkReachabilityStatus {
            return isReachable && networkReachabilityStatus == .reachableViaWiFi
        } else {
            return false
        }
        
    }
    //MARK: - Private Helper methods
    
    //MARK: update current network status    
    fileprivate func updateCurrentState(_ currentReachability: Reachability) {
        lastRefreshDate = Date()
        let networkStatus = currentReachability.currentReachabilityStatus()
        if networkStatus == NotReachable {
            DebugingLogger.log("NotReachable")
            self.isReachable = false
            self.networkReachabilityStatus = .notReachable
        } else if networkStatus == ReachableViaWiFi {
            DebugingLogger.log("ReachableViaWiFi")
            self.isReachable = true
            self.networkReachabilityStatus = .reachableViaWiFi
        } else if networkStatus == ReachableViaWWAN {
            DebugingLogger.log("ReachableViaWWAN")
            self.isReachable = true
            self.networkReachabilityStatus = .reachableViaWWAN
        }
    }

}
