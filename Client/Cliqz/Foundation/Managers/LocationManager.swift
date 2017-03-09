//
//  LocationManager.swift
//  Client
//
//  Created by Sahakyan on 8/28/15.
//  Copyright (c) 2015 Mozilla. All rights reserved.
//

import Foundation
import CoreLocation

public class LocationManager: NSObject, CLLocationManagerDelegate {
    static let NotificationUserLocationAvailable = "NotificationUserLocationAvailable"
    static let NotificationShowOpenLocationSettingsAlert = "NotificationShowOpenLocationSettingsAlert"

	private let manager = CLLocationManager()
    private var location: CLLocation? {
        didSet {
            if location != nil {
                NSNotificationCenter.defaultCenter().postNotificationName(LocationManager.NotificationUserLocationAvailable, object: nil)
            }
        }
    }
    private let locationStatusKey = "currentLocationStatus"

	public static let sharedInstance: LocationManager = {
		let m = LocationManager()
		m.manager.delegate = m
		m.manager.desiredAccuracy = 300
		return m
	}()

    public func getUserLocation() -> CLLocation? {
        return self.location
    }
    
    public func askForLocationAccess () {
        TelemetryLogger.sharedInstance.logEvent(.LocationServicesStatus("try_show", nil))
        self.manager.requestWhenInUseAuthorization()
    }
    
	public func shareLocation() {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus == .Denied {
            NSNotificationCenter.defaultCenter().postNotificationName(LocationManager.NotificationShowOpenLocationSettingsAlert, object: CLLocationManager.locationServicesEnabled())
        } else if authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse {
            self.startUpdatingLocation()
            
        } else if CLLocationManager.locationServicesEnabled() {
            askForLocationAccess()
        }
        
	}
    
    
    public func startUpdatingLocation() {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        guard authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse else {
            return
        }
        
        self.manager.startUpdatingLocation()
    }
    
	public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.last
	}
    
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .Denied, .NotDetermined, .Restricted:
            self.location = nil
        default:
			if let l = self.manager.location {
				self.location = l
			}
            break
        }
        
        let currentLocationStatus = LocalDataStore.objectForKey(locationStatusKey)
        if currentLocationStatus == nil || currentLocationStatus as! String != status.stringValue() {
            TelemetryLogger.sharedInstance.logEvent(.LocationServicesStatus("status_change", status.stringValue()))
            LocalDataStore.setObject(status.stringValue(), forKey: locationStatusKey)
        }
    }

}

extension CLAuthorizationStatus {
	func stringValue() -> String {
		let statuses: [Int: String] = [Int(CLAuthorizationStatus.NotDetermined.rawValue) : "NotDetermined",
			Int(CLAuthorizationStatus.Restricted.rawValue) : "Restricted",
			Int(CLAuthorizationStatus.Denied.rawValue) : "Denied",
			Int(CLAuthorizationStatus.AuthorizedAlways.rawValue) : "AuthorizedAlways",
			Int(CLAuthorizationStatus.AuthorizedWhenInUse.rawValue) : "AuthorizedWhenInUse"]
		if let s = statuses[Int(rawValue)] {
			return s
		}
		return "Unknown type"
	}
}
