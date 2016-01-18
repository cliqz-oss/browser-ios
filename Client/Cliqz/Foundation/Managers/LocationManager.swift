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

	public static let sharedInstance: LocationManager = {
		let m = LocationManager()
		m.manager.delegate = m
		m.manager.desiredAccuracy = 300
		return m
	}()

	public func startUpdateingLocation() {
		if !CLLocationManager.locationServicesEnabled() || CLLocationManager.authorizationStatus() == .NotDetermined {
			self.manager.requestWhenInUseAuthorization()
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
    }

}