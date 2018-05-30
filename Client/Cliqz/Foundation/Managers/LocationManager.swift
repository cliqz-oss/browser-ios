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

	let manager = CLLocationManager()
	var location: CLLocation?
    let locationStatusKey = "currentLocationStatus"

	public static let sharedInstance: LocationManager = {
		let m = LocationManager()
		m.manager.delegate = m
		m.manager.desiredAccuracy = 300
		return m
	}()

    public func askForLocationAccess () {
        TelemetryLogger.sharedInstance.logEvent(.LocationServicesStatus("try_show", nil))
        self.manager.requestWhenInUseAuthorization()
    }
    
	public func startUpdateingLocation() {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
		if CLLocationManager.locationServicesEnabled() &&  authorizationStatus == .NotDetermined {
			askForLocationAccess()
		} else if authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse {
            self.manager.startUpdatingLocation()
        }
	}

	public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if locations.count > 0 {
			self.location = locations[locations.count - 1]
		}
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