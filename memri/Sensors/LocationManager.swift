//
//  LocationManager.swift
//  memri
//
//  Created by Jess Taylor on 6/25/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import CoreLocation

//
// TODO - We need a user interface to manage some settings
//

//
// Note:
//
// 1. We are not requiring a device to have location service capabilitie for the app to function
//
//
public class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private var clm: CLLocationManager!
    
    public override init() {
        super.init()
        self.clm = CLLocationManager()
        self.clm.delegate = self
        self.clm.allowsBackgroundLocationUpdates = true
        self.clm.showsBackgroundLocationIndicator = true
    }
    
    //
    // MARK - Core Location Manager
    //
    
    public func startUpdates() {
        self.clm.startUpdatingLocation()
    }

    public func stopUpdates() {
        self.clm.stopUpdatingLocation()
    }

    //
    // MARK - Core Location Delegate
    //
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("LocationManager: \(locations.count) new locations found")
        for aLocation in locations {
            print(aLocation)
        }
        //
        // TODO - Log locations or last location to the database
        //
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Error = \(error.localizedDescription)")
    }
    
}
