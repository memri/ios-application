//
//  MapRendererModel.swift
//  MemriPlayground
//
//  Created by Toby Brennan.
//

import Combine
import CoreLocation
import Foundation

#if !targetEnvironment(macCatalyst)
	import Mapbox
#endif

class MapModel {
	var didChange = PassthroughSubject<Void, Never>()

	init() {
		updateQueue.throttle(for: .seconds(0.1), scheduler: RunLoop.main, latest: true).sink { [weak self] in
			self?._updateModel()
		}
		.store(in: &cancellableBag)
	}

	var dataItems: [Item] = [] {
		didSet {
			if dataItems != oldValue {
				updateModel()
			}
		}
	}

	private(set) var items: [MapItem] = [] {
		didSet {
			if items != oldValue {
				didChange.send()
			}
		}
	}

	var mapStyle: MapStyle = .street {
		didSet {
			if mapStyle != oldValue {
				didChange.send()
			}
		}
	}

	var locationKey: String? {
		didSet {
			if locationKey != oldValue {
				updateModel()
			}
		}
	}

	var addressKey: String? {
		didSet {
			if addressKey != oldValue {
				updateModel()
			}
		}
	}

	var labelKey: String = "name" {
		didSet {
			if labelKey != oldValue {
				updateModel()
			}
		}
	}

	func updateModel() {
		updateQueue.send()
	}

	var cancellableBag = Set<AnyCancellable>()
	let updateQueue = PassthroughSubject<Void, Never>()

	func _updateModel() {
		let newItems = dataItems.flatMap { dataItem -> [MapItem] in
			let locations: [CLLocation] = resolveItem(dataItem: dataItem)
			let label: String = dataItem.hasProperty(labelKey) ? (dataItem.get(labelKey) ?? "") : ""
			return locations.map {
				return MapItem(label: label, coordinate: $0.coordinate, dataItem: dataItem)
			}
		}
		items = newItems
	}

	func resolveItem(dataItem: Item) -> [CLLocation] {
		if let locationKey = locationKey, dataItem.hasProperty(locationKey) {
			if let location: CLLocation = dataItem.get(locationKey) {
				// Has a coordinate value
				return [location]
			}
		}

		if let addressKey = addressKey, dataItem.hasProperty(addressKey) {
			if let addresses: List<Address> = dataItem.get(addressKey) {
				let resolvedLocations = addresses.compactMap { self.lookupAddress($0) }
				if !resolvedLocations.isEmpty {
					return Array(resolvedLocations)
				}
			} else if let address: Address = dataItem.get(addressKey) {
				if let location = lookupAddress(address) {
					return [location]
				}
			}
		}
		return []
	}

	var addressLookupCancellables: [Address: AnyCancellable] = [:]

	func lookupAddress(_ address: Address) -> CLLocation? {
		if let location = address.location, let latitude = location.latitude.value, let longitude = location.longitude.value {
			return CLLocation(latitude: latitude, longitude: longitude)
		}
		let (currentResult, lookupPublisher) = MapHelper.shared.getLocationForAddress(address: address)
		if let location = currentResult { return location }

		if addressLookupCancellables[address] == nil {
			addressLookupCancellables[address] = lookupPublisher?.sink { [weak self] _ in self?.updateModel() }
		}
		return nil
	}

	struct MapItem: Equatable {
		var label: String
		var coordinate: CLLocationCoordinate2D
		var dataItem: Item?
	}
}

extension CLLocationCoordinate2D: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
	}
}
