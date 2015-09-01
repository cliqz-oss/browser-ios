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

	public static let sharedLocationManager: LocationManager = {
		let m = LocationManager()
		m.manager.delegate = m
		m.manager.requestWhenInUseAuthorization()
		return m
	}()

	public func startUpdateingLocation() {
		self.manager.startUpdatingLocation()
		println("Hellllloooo --- %@", self.manager.location)
	}

	public func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
		println("Hellllloooo --- %@", locations)
		if locations.count > 0 {
			self.location = locations[locations.count - 1] as? CLLocation
		}
	}
	
	

}