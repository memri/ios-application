//
//  MapRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

let registerMapRenderer = {
    Renderers.register(
        name: "map",
        title: "Default",
        order: 300,
        icon: "map",
        view: AnyView(MapRendererView()),
        renderConfigType: CascadingMapConfig.self,
        canDisplayResults: { items -> Bool in true }
    )
}

class CascadingMapConfig: CascadingRenderConfig {
    var type: String? = "map"
    
    var longPress: Action? { cascadeProperty("longPress") }
    var press: Action? { cascadeProperty("press") }
}

struct MapRendererView: View {
    @EnvironmentObject var context: MemriContext
    
    let name = "map"
    
    var renderConfig: CascadingMapConfig? {
        self.context.cascadingView.renderConfig as? CascadingMapConfig
    }
    
    var body: some View {
        #if targetEnvironment(macCatalyst)
        return Text("Map is not supported on Mac yet.")
        #else
        return MapView(locations: nil, addresses: context.items as? [Address]) // TODO Refactor: this is very not generic
        #endif
    }
}

struct MapRendererView_Previews: PreviewProvider {
    static var previews: some View {
        MapRendererView().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
