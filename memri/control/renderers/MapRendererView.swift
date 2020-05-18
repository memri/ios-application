//
//  MapRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

private var register:Void = {
    Renderers.register(
        name: "map",
        title: "Default",
        order: 3,
        icon: "map",
        view: AnyView(MapRendererView()),
        canDisplayResults: { items -> Bool in true }
    )
}()

class CascadingMapConfig: CascadingRenderConfig {
    var type: String? = "map"
    
    var longPress: ActionDescription? { cascadeProperty("longPress", nil) }
    var press: ActionDescription? { cascadeProperty("press", nil) }
}

struct MapRendererView: View {
    @EnvironmentObject var main: Main
    
    let name = "map"
    
    var renderConfig: CascadingMapConfig {
        return self.main.computedView.renderConfigs[name] as? CascadingMapConfig ?? CascadingMapConfig()
    }
    
    var body: some View {
        return VStack {
//            if main.computedView.resultSet.count == 0 {
            MapView(locations: nil, addresses: main.items as? [Address]) // TODO Refactor: this is very not generic
        }
    }
}

struct MapRendererView_Previews: PreviewProvider {
    static var previews: some View {
        MapRendererView().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
