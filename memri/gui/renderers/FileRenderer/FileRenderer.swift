//
//  FileRenderer.swift
//  memri
//
//  Created by Toby Brennan on 1/8/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI


let registerFileViewerRenderer = {
    Renderers.register(
        name: "fileViewer",
        title: "Default",
        order: 10,
        icon: "doc.text",
        view: AnyView(FileViewerRenderer()),
        renderConfigType: FileViewerRendererConfig.self,
        canDisplayResults: { items -> Bool in items.first?.genericType == "Photo" }
    )
}

class FileViewerRendererConfig: CascadingRenderConfig {
    var type: String? = "fileViewer"
    
    var file: Expression? { cascadeProperty("file", type: Expression.self) }
    var itemTitle: Expression? { cascadeProperty("itemTitle", type: Expression.self) }
    var initialItem: Item? { cascadeProperty("initialItem", type: Item.self) }
}

struct FileViewerRenderer: View {
    @EnvironmentObject var context: MemriContext
    var renderConfig: FileViewerRendererConfig {
        context.currentView?
            .renderConfig as? FileViewerRendererConfig ?? FileViewerRendererConfig()
    }
    
    func resolveExpression<T>(
        _ expression: Expression?,
        toType _: T.Type = T.self,
        forItem dataItem: Item
    ) -> T? {
        let args = ViewArguments(context.currentView?.viewArguments)
        args.set(".", dataItem)
        return try? expression?.execForReturnType(T.self, args: args)
    }
    
    var initialIndex: Int {
        renderConfig.initialItem.flatMap { context.items.firstIndex(of: $0) } ?? 0
    }
    
    var files: [FileViewerItem] {
        context.items.compactMap { item -> FileViewerItem? in
            guard let file = resolveExpression(renderConfig.file, toType: File.self, forItem: item) ?? (item as? File),
                let url = file.url
            else { return nil }
            return FileViewerItem(url: url,
                                  title: resolveExpression(renderConfig.itemTitle, toType: String.self, forItem: item))
        }
    }
    
    var body: some View {
        MemriFileViewController(files: files, initialIndex: initialIndex, navBarHiddenBinding: isFullScreen)
    }
    
    var isFullScreen: Binding<Bool> {
        Binding<Bool>(
            get: { [weak context] in
                context?.currentView?.fullscreen ?? false
        }, set: { [weak context] in
            context?.currentView?.fullscreen = $0
        })
    }
}
