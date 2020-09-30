//
//  CVU_TimelineItem.swift
//  memri
//
//  Created by Toby Brennan on 30/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct CVU_TimelineItem: View {
    var nodeResolver: UINodeResolver
    
    var body: some View {
        TimelineItemView(icon: Image(systemName: nodeResolver.string(for: "icon") ?? "arrowtriangle.right"),
                         title: nodeResolver.string(for:"title") ?? "-",
                         subtitle: nodeResolver.string(for:"text"),
                         backgroundColor: nodeResolver.item.flatMap { ItemFamily(rawValue: $0.genericType) }?
                            .backgroundColor ?? .gray)
    }
}
