//
// SensorManager.swift
// Copyright © 2020 memri. All rights reserved.

import CoreLocation
import Foundation
import RealmSwift

public class SensorManager: NSObject, CLLocationManagerDelegate {
    static var shared = SensorManager()

    //
    // Core Location Manager
    //
    private var coreLocationManager: CLLocationManager?
    private var usingSignificantLocationChangeMonitoring: Bool = false
    private let locationTrackingEnabledByUserKey: String = "MLocationTrackingEnabledKey"

    override public init() {}

    func onAppStart() {
        setupCoreLocationManager()
    }

    //

    // MARK: - Location user interaction lifecycle methods

    //

    // Call this method to decide whether to offer location tracking to the user
    public func locationTrackingIsAvailableToUser() -> Bool {
        CLLocationManager.locationServicesEnabled()
    }

    // Returns the current user setting
    public func locatonTrackingIsEnabledByUser() -> Bool {
        UserDefaults.standard.bool(forKey: locationTrackingEnabledByUserKey)
    }

    // Turn on tracking
    public func locationTrackingEnabledByUser() {
        if !locatonTrackingIsEnabledByUser() {
            UserDefaults.standard.set(true, forKey: locationTrackingEnabledByUserKey)
            setupCoreLocationManager()
        }
    }

    // Turn off tracking
    public func locationTrackingDisabledByUser() {
        UserDefaults.standard.set(false, forKey: locationTrackingEnabledByUserKey)
        // We keep any recorded data always
        tearDownCoreLocationManager()
    }

    private func tearDownCoreLocationManager() {
        guard coreLocationManager == nil else { return }
        stopUpdates()
        coreLocationManager?.delegate = nil
        coreLocationManager = nil
    }

    //
    // Note: we are currently implementing only location tracking, not
    // Heading, Region Monitoring or Ranging (Beacons) features
    //
    private func setupCoreLocationManager() {
        #if !targetEnvironment(macCatalyst)
            if locatonTrackingIsEnabledByUser() && CLLocationManager.locationServicesEnabled() {
                //
                // Instantiation will kick off first call to delegate ... didChangeAuthorization
                //
                coreLocationManager = CLLocationManager()
                coreLocationManager?.delegate = self

                coreLocationManager?
                    .allowsBackgroundLocationUpdates =
                    true // This could be a user setting, but it's default for now
                coreLocationManager?.showsBackgroundLocationIndicator = false
                coreLocationManager?.pausesLocationUpdatesAutomatically = false

                //
                // We choose to use the significant location change monitoring capabilities
                // by default, unless they are not available.
                //
                if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                    usingSignificantLocationChangeMonitoring =
                        true // This could be a user setting, but it's default for now
                    debugHistory.info("Significant Change Location Servics Enabled")
                }
                else {
                    coreLocationManager?
                        .desiredAccuracy = kCLLocationAccuracyBest // This could be a user setting
                    coreLocationManager?
                        .distanceFilter = kCLDistanceFilterNone // This could be a user setting
                    debugHistory.info("Location Servics Enabled")
                }
            }
            else {
                debugHistory.info("Location Services Not Available")
            }
        #endif
    }

    private func stopUpdates() {
        guard coreLocationManager == nil else { return }
        if usingSignificantLocationChangeMonitoring {
            coreLocationManager?.stopMonitoringSignificantLocationChanges()
        }
        else {
            coreLocationManager?.stopUpdatingLocation()
        }
    }

    private func persistLocation(location: CLLocation) {
        _ = try? Cache.createItem(Location.self, values: [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
        ])
        #warning("Force the UI to update when location is shown somehow")
    }

    //

    // MARK: - Core Location Delegate

    //

    public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        for aLocation in locations {
            persistLocation(location: aLocation)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugHistory.error("LocationManager: Error = \(error.localizedDescription)")
    }

    public func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        if status == .denied {
            //
            // Location services are currently denied
            //
            debugHistory.info("Location services are denied")
        }
        else if status == .restricted {
            //
            // Cannot use location services at all
            //
            debugHistory.info("Location services are restricted")
        }
        else if status == .notDetermined {
            //
            // Let's ask for full autnorization
            //
            manager.requestAlwaysAuthorization()
            debugHistory.info("Location services being requested")
        }
        else {
            //
            // The user has authorized either .authorizedAlways or .authorizedWhenInUse
            //
            if usingSignificantLocationChangeMonitoring {
                manager.startMonitoringSignificantLocationChanges()
            }
            else {
                manager.startUpdatingLocation()
            }
            debugHistory.info("Location services starting updates")
        }
    }
}
