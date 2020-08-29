//
// MapRendererView.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift
import SwiftUI
//
//let registerMapRenderer = {
//    Renderers.register(
//        name: "map",
//        title: "Default",
//        order: 300,
//        icon: "map",
//        view: AnyView(MapRendererView()),
//        renderConfigType: CascadingMapConfig.self,
//        canDisplayResults: { _ -> Bool in true }
//    )
//}

class CascadingMapConfig: CascadingRenderConfig, ConfigurableRenderConfig {
    var type: String? = "map"
    
    var showSortInConfig: Bool = false
    func configItems(context: MemriContext) -> [ConfigPanelModel.ConfigItem] {
        []
    }

    var longPress: Action? {
        get { cascadeProperty("longPress") }
        set(value) { setState("longPress", value) }
    }

    var press: Action? {
        get { cascadeProperty("press") }
        set(value) { setState("press", value) }
    }

    var location: Expression? {
        get { cascadeProperty("location", type: Expression.self) }
        set(value) { setState("location", value) }
    }

    var address: Expression? {
        get { cascadeProperty("address", type: Expression.self) }
        set(value) { setState("address", value) }
    }

    var label: Expression? {
        get { cascadeProperty("label", type: Expression.self) }
        set(value) { setState("label", value) }
    }

    var moveable: Bool {
        get { cascadeProperty("moveable") ?? true }
        set(value) { setState("moveable", value) }
    }
    
    let showContextualBarInEditMode: Bool = false
}

struct MapRendererView: View {
    @EnvironmentObject var context: MemriContext

    let name = "map"

    var renderConfig: CascadingMapConfig {
        (context.currentView?.renderConfig as? CascadingMapConfig) ?? CascadingMapConfig()
    }

    func resolveExpression<T>(
        _ expression: Expression?,
        toType _: T.Type = T.self,
        forItem dataItem: Item
    ) -> T? {
        let args = ViewArguments(context.currentView?.viewArguments, dataItem)
        return try? expression?.execForReturnType(T.self, args: args)
    }

    var useMapBox: Bool {
        context.settings.get("/user/general/gui/useMapBox", type: Bool.self) ?? false
    }

    var body: some View {
        let config = MapViewConfig(
            dataItems: context.items,
            locationResolver: {
                self.resolveExpression(self.renderConfig.location, forItem: $0)
            },
            addressResolver: {
                let addr = self.renderConfig.address
                return self.resolveExpression(addr, toType: Results<Item>.self, forItem: $0)
                    ?? self.resolveExpression(addr, toType: Address.self, forItem: $0)
            },
            labelResolver: {
                self.resolveExpression(self.renderConfig.label, forItem: $0)
            },
			moveable: renderConfig.moveable,
			onPress: self.onPress
        )

        return MapView(useMapBox: useMapBox, config: config)
            .background(Color(.secondarySystemBackground))
    }

    func onPress(_ dataItem: Item) {
        renderConfig.press.map { context.executeAction($0, with: dataItem) }
    }
}

struct MapRendererView_Previews: PreviewProvider {
    static var previews: some View {
        MapRendererView().environmentObject(try! RootContext(name: "").mockBoot())
    }
}
