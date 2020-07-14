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
