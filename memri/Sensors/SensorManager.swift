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

    private var realm: Realm?
    
    //
    // Core Location Manager
    //
    private var coreLocationManager: CLLocationManager?
    private var usingSignificantLocationChangeMonitoring: Bool = false
    private let locationTrackingEnabledByUserKey: String = "MLocationTrackingEnabledKey"
    
    public override init() {}

    func onAppStart() {
        #if !targetEnvironment(macCatalyst)
            self.setupCoreLocationManager()
        #endif
    }
    
    //
    // MARK - Location user interaction lifecycle methods
    //

    // Call this method to decide whether to offer location tracking to the user
    public func locationTrackingIsAvailableToUser() -> Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    // Returns the current user setting
    public func locatonTrackingIsEnabledByUser() -> Bool {
        UserDefaults.standard.bool(forKey: self.locationTrackingEnabledByUserKey)
    }
    
    // Turn on tracking
    public func locationTrackingEnabledByUser() {
        if !self.locatonTrackingIsEnabledByUser() {
            UserDefaults.standard.set(true, forKey: self.locationTrackingEnabledByUserKey)
            self.setupCoreLocationManager()
        }
    }

    // Turn off tracking
    public func locationTrackingDisabledByUser() {
        UserDefaults.standard.set(false, forKey: self.locationTrackingEnabledByUserKey)
        self.tearDownCoreLocationManager()
        //
        // TODO - what to do about any collected data?
        //
    }

    private func tearDownCoreLocationManager() {
        guard self.coreLocationManager == nil else { return }
        self.stopUpdates()
        self.coreLocationManager?.delegate = nil
        self.coreLocationManager = nil
    }
    
    //
    // Note: we are currently implementing only location tracking, not
    // Heading, Region Monitoring or Ranging (Beacons) features
    //
    private func setupCoreLocationManager() {
        if self.locatonTrackingIsEnabledByUser() && CLLocationManager.locationServicesEnabled()  {
            //
            // Instantiation will kick off first call to delegate ... didChangeAuthorization
            //
            self.coreLocationManager = CLLocationManager()
            self.coreLocationManager?.delegate = self

            self.coreLocationManager?.allowsBackgroundLocationUpdates = true        // This could be a user setting, but it's default for now
            self.coreLocationManager?.showsBackgroundLocationIndicator = false
            self.coreLocationManager?.pausesLocationUpdatesAutomatically = false

            //
            // We choose to use the significant location change monitoring capabilities
            // by default, unless they are not available.
            //
            if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                self.usingSignificantLocationChangeMonitoring = true                // This could be a user setting, but it's default for now
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

    private func stopUpdates() {
        guard self.coreLocationManager == nil else { return }
        if self.usingSignificantLocationChangeMonitoring {
            self.coreLocationManager?.stopMonitoringSignificantLocationChanges()
        } else {
            self.coreLocationManager?.stopUpdatingLocation()
        }
    }
    
    private func persistLocation(location: CLLocation) {
        // TODO - Implement
        //        do {
        //            try realm?.add("TODO")
        //        } catch {
        //            print(error.localizedDescription)
        //        }
        //
        // Need to create the location "table" if it does not exist
        // Need to save the location
        // It may be convenient to create a managed object that mapped easily to a CLLocation object?
        //
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
