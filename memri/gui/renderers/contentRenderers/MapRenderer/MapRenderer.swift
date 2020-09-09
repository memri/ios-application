//
// MapRendererView.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift
import SwiftUI

class MapRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "map", icon: "map", makeController: MapRendererController.init, makeConfig: MapRendererController.makeConfig)
    
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? MapRendererConfig) ?? MapRendererConfig()
    }
    
    let context: MemriContext
    let config: MapRendererConfig
    
    func makeView() -> AnyView {
        MapRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        MapRendererConfig(head, tail, host)
    }
    
    func resolveExpression<T>(
        _ expression: Expression?,
        toType _: T.Type = T.self,
        forItem dataItem: Item
    ) -> T? {
        let args = ViewArguments(context.currentView?.viewArguments, dataItem)
        return try? expression?.execForReturnType(T.self, args: args)
    }
    
    var mapConfig: MapViewConfig {
        MapViewConfig(
            dataItems: context.items,
            locationResolver: {
                self.resolveExpression(self.config.location, forItem: $0)
        },
            addressResolver: {
                let addr = self.config.address
                return self.resolveExpression(addr, toType: Results<Item>.self, forItem: $0)
                    ?? self.resolveExpression(addr, toType: Address.self, forItem: $0)
        },
            labelResolver: {
                self.resolveExpression(self.config.label, forItem: $0)
        },
            moveable: config.moveable,
            onPress: onPress
        )
    }
    
    
    func onPress(_ dataItem: Item) {
        config.press.map { context.executeAction($0, with: dataItem) }
    }
}
    

class MapRendererConfig: CascadingRendererConfig, ConfigurableRenderConfig {
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
    @ObservedObject var controller: MapRendererController

    var body: some View {
        MapView(config: controller.mapConfig)
            .background(Color(.secondarySystemBackground))
    }
}

struct MapRendererView_Previews: PreviewProvider {
    static var previews: some View {
        MapRendererView(controller: MapRendererController(context: try! RootContext(name: "").mockBoot(), config: nil))
    }
}
