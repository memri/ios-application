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
        // Make new lookup
        let addressString = address.computedTitle
        let lookupHash = addressString.hashValue
        
        // Check if the address holds a valid location
        if let location = address.location,
           let latitude = location.latitude.value,
           let longitude = location.longitude.value {
            let clLocation = CLLocation(latitude: latitude, longitude: longitude)
            if let oldLookupHash = address.locationAutoLookupHash {
                // This was an automatic lookup - check it's still current
                if oldLookupHash == String(lookupHash) { return (clLocation, nil) }
            } else {
                // No old lookup hash, this location is user-defined
                return (clLocation, nil)
            }
        }
        
        // Check lookups in progress
        if let knownLocation = addressLookupResults[lookupHash] {
			// Successful lookup already completed
			return (knownLocation, nil)
		} else if let existingLookup = addressLookupPublishers[lookupHash] {
			// Lookup already in progress
			return (nil, existingLookup)
		}
		// Make new lookup
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
		addressLookupPublishers[lookupHash] = lookup

		// When it finishes, cache the value and remove the publisher
		lookup.sink { [weak self] location in
			if let location = location {
				// Update the address with the location (avoid future lookups)
				let safeRef = ItemReference(to: address)
				DatabaseController.writeAsync { _ in
                    guard let address = safeRef.resolve() as? Address else { return }
                    
                    let newLocation = try Cache.createItem(Location.self, values: [
                        "latitude": location.coordinate.latitude,
                        "longitude": location.coordinate.longitude
                    ])
                    address.locationAutoLookupHash = String(lookupHash)
                    
                    try address.location.map { try address.unlink($0) }
					_ = try address.link(newLocation, type: "location")
				}
			}
			self?.addressLookupResults[lookupHash] = location
			self?.addressLookupPublishers[lookupHash] = nil
		}.store(in: &cancellableBag)
		return (nil, lookup)
	}

	var cancellableBag = Set<AnyCancellable>()

	var addressLookupResults: [Int: CLLocation] = [:]
	var addressLookupPublishers: [Int: AnyPublisher<CLLocation?, Never>] = [:]
}
