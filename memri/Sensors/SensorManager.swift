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

    //
    // Core Location Manager
    //
    private var coreLocationManager: CLLocationManager?
    private var usingSignificantLocationChangeMonitoring: Bool = false
    private let locationTrackingEnabledByUserKey: String = "MLocationTrackingEnabledKey"
    
    public override init() {}

    func onAppStart() {
        self.setupCoreLocationManager()
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
        // We keep any recorded data always
        self.tearDownCoreLocationManager()
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
        #if !targetEnvironment(macCatalyst)
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
                    debugHistory.info("Significant Change Location Servics Enabled")
                } else {
                    self.coreLocationManager?.desiredAccuracy = kCLLocationAccuracyBest // This could be a user setting
                    self.coreLocationManager?.distanceFilter = kCLDistanceFilterNone    // This could be a user setting
                    debugHistory.info("Location Servics Enabled")
                }
            } else {
                debugHistory.info("Location Services Not Available")
            }
        #endif
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
        _ = try? Cache.createItem(Location.self, values: [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude
        ])
    }
    
    //
    // MARK - Core Location Delegate
    //
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for aLocation in locations {
            self.persistLocation(location: aLocation)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugHistory.error("LocationManager: Error = \(error.localizedDescription)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied {
            //
            // Location services are currently denied
            //
            debugHistory.info("Location services are denied")
        } else if status == .restricted {
            //
            // Cannot use location services at all
            //
            debugHistory.info("Location services are restricted")
        } else if status == . notDetermined {
            //
            // Let's ask for full autnorization
            //
            manager.requestAlwaysAuthorization()
            debugHistory.info("Location services being requested")
        } else {
            //
            // The user has authorized either .authorizedAlways or .authorizedWhenInUse
            //
            if self.usingSignificantLocationChangeMonitoring {
                manager.startMonitoringSignificantLocationChanges()
            } else {
                manager.startUpdatingLocation()
            }
            debugHistory.info("Location services starting updates")
        }
    }
    
}
