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
    case NotReachable
    case ReachableViaWiFi
    case ReachableViaWWAN
    
    var description : String {
        switch self {
            case .NotReachable: return "Disconnected";
            case .ReachableViaWiFi: return "Wifi";
            case .ReachableViaWWAN: return "WWAN";
        }
    }
}

class NetworkReachability : NSObject {
    let internetReachability = Reachability.reachabilityForInternetConnection()
    var isReachable: Bool?
    var networkReachabilityStatus: NetworkReachabilityStatus?
    var lastRefreshDate: NSDate?
    
    //MARK: - Singltone
    static let sharedInstance = NetworkReachability()

    override init () {
        super.init()
        refreshStatus()
    }
    //MARK: - Reachability monitoring 
    func startMonitoring() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reachabilityChanged:"), name: kReachabilityChangedNotification, object: nil)
        internetReachability.startNotifier()
    }
    func reachabilityChanged(notification: NSNotification) {
        if let currentReachability = notification.object as? Reachability {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.logNetworkStatusEvent()
                self.updateCurrentState(currentReachability)
            }
        }
    }
    
    func refreshStatus() {
        updateCurrentState(internetReachability)
    }
    func logNetworkStatusEvent() {
        
        var duration: Int
        if let durationStart = lastRefreshDate {
            duration = Int(NSDate().timeIntervalSinceDate(durationStart))
        } else {
            duration = 0
        }
        
        TelemetryLogger.sharedInstance.logEvent(.NetworkStatus(self.networkReachabilityStatus!.description, duration))
    }
    
    //MARK: - Private Helper methods
    
    //MARK: update current network status    
    private func updateCurrentState(currentReachability: Reachability) {
        lastRefreshDate = NSDate()
        let networkStatus = currentReachability.currentReachabilityStatus()
        if networkStatus == NotReachable {
            DebugLogger.log("NotReachable")
            self.isReachable = false
            self.networkReachabilityStatus = .NotReachable
        } else if networkStatus == ReachableViaWiFi {
            DebugLogger.log("ReachableViaWiFi")
            self.isReachable = true
            self.networkReachabilityStatus = .ReachableViaWiFi
        } else if networkStatus == ReachableViaWWAN {
            DebugLogger.log("ReachableViaWWAN")
            self.isReachable = true
            self.networkReachabilityStatus = .ReachableViaWWAN
        }
    }

}
