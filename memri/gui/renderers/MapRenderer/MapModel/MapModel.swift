//
//  MapRendererModel.swift
//  MemriPlayground
//
//  Created by Toby Brennan.
//

import Combine
import CoreLocation
import Foundation
import RealmSwift

#if !targetEnvironment(macCatalyst)
//	import Mapbox
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
	
	var locationResolver: ((Item) -> Any?)?
	var addressResolver: ((Item) -> Any?)?
	var labelResolver: ((Item) -> String?)?

	func updateModel() {
		updateQueue.send()
	}

	var cancellableBag = Set<AnyCancellable>()
	let updateQueue = PassthroughSubject<Void, Never>()

	func _updateModel() {
		let newItems = dataItems.flatMap { dataItem -> [MapItem] in
			let locations: [CLLocation] = resolveItem(dataItem: dataItem)
			let labelString: String = labelResolver?(dataItem) ?? ""
			return locations.map {
				return MapItem(label: labelString, coordinate: $0.coordinate, dataItem: dataItem)
			}
		}
		items = newItems
	}

	func resolveItem(dataItem: Item) -> [CLLocation] {
		if let locItem = locationResolver?(dataItem) as? Location {
            let location = CLLocation(
                latitude: locItem.latitude.value ?? 0,
                longitude: locItem.longitude.value ?? 0
            )
            
			// Has a coordinate value
			return [location]
		}
        
        #warning("@Toby Note that the location implementation above was wrong and is also faulty for MapBOx")
		
		let addresses: [Address]
		let addressExpressionResult = addressResolver?(dataItem)
		if let addressesList = addressExpressionResult as? Results<Item> {
			addresses = Array(addressesList.compactMap { $0 as? Address })
		} else if let address = addressExpressionResult as? Address {
			addresses = [address]
		} else {
			return []
		}
		let resolvedLocations = addresses.compactMap { self.lookupAddress($0) }
		guard !resolvedLocations.isEmpty else { return [] }
		
		return resolvedLocations
	}

	var addressLookupCancellables: [Address: AnyCancellable] = [:]

	func lookupAddress(_ address: Address) -> CLLocation? {
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
