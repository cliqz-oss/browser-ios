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
        case .ReachableViaWWAN: return "3G";
        }
    }
}

class NetworkReachability : NSObject {
    let internetReachability = Reachability.reachabilityForInternetConnection()
    var isReachable: Bool?
    var networkReachabilityStatus: NetworkReachabilityStatus?
    
    //MARK: - Singltone
    static let sharedInstance = NetworkReachability()

    
    //MARK: - Reachability monitoring 
    func startMonitoring() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reachabilityChanged:"), name: kReachabilityChangedNotification, object: nil)
        internetReachability.startNotifier()
        updateCurrentState(internetReachability)
    }
    
    func reachabilityChanged(notification: NSNotification) {
        if let currentReachability = notification.object as? Reachability {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.updateCurrentState(currentReachability)
                TelemetryLogger.sharedInstance.logEvent(.NetworkChange("network_change", self.networkReachabilityStatus!.description))
            }

        }
    }
    
    func updateCurrentState(currentReachability: Reachability) {
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
