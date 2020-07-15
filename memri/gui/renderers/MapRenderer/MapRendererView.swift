//
//  MapRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

let registerMapRenderer = {
	Renderers.register(
		name: "map",
		title: "Default",
		order: 300,
		icon: "map",
		view: AnyView(MapRendererView()),
		renderConfigType: CascadingMapConfig.self,
		canDisplayResults: { _ -> Bool in true }
	)
}

class CascadingMapConfig: CascadingRenderConfig {
	var type: String? = "map"

	var longPress: Action? {
        get { cascadeProperty("longPress") }
        set (value) { setState("longPress", value) }
    }
	var press: Action? {
        get { cascadeProperty("press") }
        set (value) { setState("press", value) }
    }

	var locationKey: String {
        get { cascadeProperty("locationKey") ?? "coordinate" }
        set (value) { setState("locationKey", value) }
    }
	var addressKey: String {
        get { cascadeProperty("addressKey") ?? "address" }
        set (value) { setState("addressKey", value) }
    }
	var labelKey: String {
        get { cascadeProperty("labelKey") ?? "name" } // Ideally we can actually hold an expression here to be resolved against each data item
        set (value) { setState("labelKey", value) }
    }
    
    var mapStyle: MapStyle {
        get { MapStyle(fromString: cascadeProperty("mapStyle")) }
        set (value) { setState("mapStyle", value) }
    }
}

struct MapRendererView: View {
	@EnvironmentObject var context: MemriContext

	let name = "map"

	var renderConfig: CascadingMapConfig {
		(context.cascadingView?.renderConfig as? CascadingMapConfig) ?? CascadingMapConfig()
	}

	var useMapBox: Bool { context.settings.get("/user/general/gui/useMapBox", type: Bool.self) ?? false }

	var body: some View {
		let config = MapViewConfig(dataItems: context.items,
								   locationKey: renderConfig.locationKey,
								   addressKey: renderConfig.addressKey,
								   labelKey: renderConfig.labelKey,
								   mapStyle: renderConfig.mapStyle,
								   onPress: self.onPress)

		return MapView(useMapBox: useMapBox, config: config)
			.background(Color(.secondarySystemBackground))
	}

	func onPress(_ dataItem: Item) {
		renderConfig.press.map { context.executeAction($0, with: dataItem) }
	}
}

struct MapRendererView_Previews: PreviewProvider {
	static var previews: some View {
		MapRendererView().environmentObject(try! RootContext(name: "", key: "").mockBoot())
	}
}
