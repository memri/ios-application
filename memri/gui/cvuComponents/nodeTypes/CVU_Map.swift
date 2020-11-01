//
//  CVU_Map.swift
//  memri
//
//  Created by Toby Brennan on 13/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift

struct CVU_Map: View {
    var nodeResolver: UINodeResolver
    
    var content: String? {
        nodeResolver.string(for: "text")?.nilIfBlank
    }
    
    var locationResolver: (Item) -> Any? {{ _ in
        self.nodeResolver.resolve("location",
                                  type: Location.self)
            ??
            self.nodeResolver.resolve("location",
                                      type: Results<Item>.self) as Any?
        }}
    var addressResolver: (Item) -> Any? {{_ in
        self.nodeResolver.resolve("address",
                                  type: Address.self) as Any?
            ??
            self.nodeResolver.resolve("address",
                                      type: Results<Item>.self) as Any?
        }}
    
    var labelResolver: (Item) -> String? {{ _ in
        self.nodeResolver.resolve("label")
        }}
    
    var config: MapViewConfig {
        MapViewConfig(dataItems: nodeResolver.item.map { [$0] } ?? [],
                      locationResolver: locationResolver,
                      addressResolver: addressResolver,
                      labelResolver: labelResolver,
                      moveable: nodeResolver.resolve("moveable", type: Bool.self) ?? true
        )
    }
    
    var body: some View {
        MapView(config: config)
            .background(Color(.secondarySystemBackground))
    }
}
