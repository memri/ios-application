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

	var longPress: Action? { cascadeProperty("longPress") }
	var press: Action? { cascadeProperty("press") }

	var location: Expression? { cascadeProperty("location", type: Expression.self) }
	var address: Expression? { cascadeProperty("address", type: Expression.self) }
	var label: Expression? { cascadeProperty("label", type: Expression.self) }

	var mapStyle: MapStyle { MapStyle(fromString: cascadeProperty("mapStyle")) }
}

struct MapRendererView: View {
	@EnvironmentObject var context: MemriContext

	let name = "map"

	var renderConfig: CascadingMapConfig {
		(context.cascadingView?.renderConfig as? CascadingMapConfig) ?? CascadingMapConfig()
	}
	
	func resolveExpression<T>(_ expression: Expression?,
							  toType _: T.Type = T.self,
							  forItem dataItem: Item) -> T? {
		let args = try? ViewArguments
			.clone(context.cascadingView?.viewArguments, [".": dataItem], managed: false)
		
		return try? expression?.execForReturnType(T.self, args: args)
	}

	var useMapBox: Bool { context.settings.get("/user/general/gui/useMapBox", type: Bool.self) ?? false }

	var body: some View {
		let config = MapViewConfig(dataItems: context.items,
								   locationResolver: {
									self.resolveExpression(renderConfig.location, forItem: $0)
								   },
								   addressResolver: {
									self.resolveExpression(renderConfig.address, toType: List<Address>.self, forItem: $0)
									?? self.resolveExpression(renderConfig.address, toType: Address.self, forItem: $0)
								   },
								   labelResolver: {
									self.resolveExpression(renderConfig.label, forItem: $0)
								   },
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
