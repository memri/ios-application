//
//  MapHelper.swift
//  MemriPlayground
//
//  Created by Toby Brennan.
//

import Combine
import CoreLocation
import Foundation
import MapKit
import RealmSwift

class MapHelper {
	static var shared = MapHelper()

	private init() {}

	var realm: Realm?

	func onAppStart() {
		#if !targetEnvironment(macCatalyst)
			// Disable MapBox usage metrics by default to maintain user privacy
			UserDefaults.standard.set(false, forKey: "MGLMapboxMetricsEnabled")
		#endif
	}

	private func lookupAddress(string: String) -> Future<[MKMapItem], Never> {
		Future { promise in
			let request = MKLocalSearch.Request()
			request.naturalLanguageQuery = string
			MKLocalSearch(request: request).start { response, error in
				guard let locations = response?.mapItems, !locations.isEmpty else {
					if let error = error {
						// Log error
						print(error.localizedDescription)
					}
					promise(.success([])) // Rather than propogating the error we return 0 results
					return
				}
				promise(.success(locations))
			}
		}
	}

	func getLocationForAddress(address: Address) -> (currentResult: CLLocation?, lookupPublisher: AnyPublisher<CLLocation?, Never>?) {
		if let knownLocation = addressLookupResults[address] {
			// Successful lookup already completed
			return (knownLocation, nil)
		} else if let existingLookup = addressLookupPublishers[address] {
			// Lookup already in progress
			return (nil, existingLookup)
		}
		// Make new lookup
		let addressString = address.computedTitle
		let lookup = lookupAddress(string: addressString)
			.map { (mapItem) -> CLLocation? in
				// Find the first placemark that has a location value
				mapItem.first { (mapItem) -> Bool in
					mapItem.placemark.location != nil
				}?.placemark.location
			}
			.multicast(subject: PassthroughSubject())
			.autoconnect()
			.eraseToAnyPublisher()
		addressLookupPublishers[address] = lookup

		// When it finishes, cache the value and remove the publisher
		lookup.sink { [weak self] location in
			if let location = location {
				// Update the address with the location (avoid future lookups)
				realmWriteIfAvailable(self?.realm) {
                    let newLocation = try Cache.createItem(Location.self, values: [
                        "latitude": location.coordinate.latitude,
                        "longitude": location.coordinate.longitude
                    ])
					_ = try address.link(newLocation, type: "location")
				}
			}
			self?.addressLookupResults[address] = location
			self?.addressLookupPublishers[address] = nil
		}.store(in: &cancellableBag)
		return (nil, lookup)
	}

	var cancellableBag = Set<AnyCancellable>()

	// TODO: Persist the address lookups back to the dataItem
	var addressLookupResults: [Address: CLLocation] = [:]
	var addressLookupPublishers: [Address: AnyPublisher<CLLocation?, Never>] = [:]
}
