//
//  MapView.swift
//  memri
//
//  Created by Toby Brennan on 27/6/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

struct MapView: View {
	var useMapBox = false
	var config: MapViewConfig

	var body: some View {
		#if targetEnvironment(macCatalyst)
			return MapView_AppleMaps(config: config)
		#else
			return Group {
				if useMapBox {
					MapView_Mapbox(config: config)
				} else {
					MapView_AppleMaps(config: config)
				}
			}
		#endif
	}
}

import CoreLocation

struct MapViewConfig {
	var dataItems: [Item] = []
	var locationResolver: (Item) -> CLLocation?
	var addressResolver: (Item) -> Any?
	var labelResolver: (Item) -> String?
	var maxInitialZoom: Double = 16
	var mapStyle: MapStyle = .street
	
	var onPress: ((Item) -> Void)?
	
	@Environment(\.colorScheme) var colorScheme
}
