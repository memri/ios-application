//
//  SensorManager.swift
//  memri
//
//  Created by Jess Taylor on 6/25/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import CoreLocation
import RealmSwift

public class SensorManager: NSObject, CLLocationManagerDelegate {
    
    static var shared = SensorManager()

    public var usingSignificantLocationChangeMonitoring: Bool = false // TODO: This needs to be persisted as a user default?!

    private var realm: Realm?
    private var coreLocationManager: CLLocationManager?

    func onAppStart() {
        #if !targetEnvironment(macCatalyst)
            self.setupCoreLocationManager()
        #endif
    }

    public override init() {}
        
    //
    // MARK - Core Location Manager
    //
    
    private func setupCoreLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            //
            // Instantiation will kick off first call to delegate ... didChangeAuthorization
            //
            self.coreLocationManager = CLLocationManager()
            self.coreLocationManager?.delegate = self

            self.coreLocationManager?.allowsBackgroundLocationUpdates = true
            self.coreLocationManager?.showsBackgroundLocationIndicator = false
            self.coreLocationManager?.pausesLocationUpdatesAutomatically = false

            //
            // We choose to use the significant location change monitoring capabilities
            // by default, unless they are not available.
            //
            if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                self.usingSignificantLocationChangeMonitoring = true
                print("Significant Change Location Servics Enabled")
            } else {
                self.coreLocationManager?.desiredAccuracy = kCLLocationAccuracyBest // This could be a user setting
                self.coreLocationManager?.distanceFilter = kCLDistanceFilterNone    // This could be a user setting
                print("Location Servics Enabled")
            }
        } else {
            print("Location Services Not Available")
        }
    }
    
    public func stopUpdates() -> Bool {
        guard self.coreLocationManager == nil else {
            return false
        }
        if self.usingSignificantLocationChangeMonitoring {
            self.coreLocationManager?.stopMonitoringSignificantLocationChanges()
        } else {
            self.coreLocationManager?.stopUpdatingLocation()
        }
        return true
    }
    
    public func persistLocation(location: CLLocation) {
// TODO - Implement
//        do {
//            try realm?.add("TODO")
//        } catch {
//            print(error.localizedDescription)
//        }
        print(location)
    }
    
    //
    // MARK - Core Location Delegate
    //
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("LocationManager Did Update: \(locations.count) new locations found")
        for aLocation in locations {
            self.persistLocation(location: aLocation)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Error = \(error.localizedDescription)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied {
            //
            // Location services are currently denied
            //
            print("Location services are denied")
        } else if status == .restricted {
            //
            // Cannot use location services at all
            //
            print("Location services are restricted")
        } else if status == . notDetermined {
            //
            // Let's ask for full autnorization
            //
            manager.requestAlwaysAuthorization()
            print("Location services being requested")
        } else {
            //
            // The user has authorized either .authorizedAlways or .authorizedWhenInUse
            //
            if self.usingSignificantLocationChangeMonitoring {
                manager.startMonitoringSignificantLocationChanges()
            } else {
                manager.startUpdatingLocation()
            }
            print("Location services starting updates")
        }
    }
    
}
