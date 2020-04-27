//
//  MapRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI


struct MapRendererView: View {
    @EnvironmentObject var main: Main
    
    let name = "map"
    
    var renderConfig: MapConfig {
        return self.main.computedView.renderConfigs[name] as? MapConfig ?? MapConfig()
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
