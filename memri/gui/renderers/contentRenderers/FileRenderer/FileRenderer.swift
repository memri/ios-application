//
//  FileRenderer.swift
//  memri
//
//  Created by Toby Brennan on 1/8/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

class FileRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "fileViewer", icon: "doc.text", makeController: FileRendererController.init, makeConfig: FileRendererController.makeConfig)
    
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? FileRendererConfig) ?? FileRendererConfig()
    }
    
    let context: MemriContext
    let config: FileRendererConfig
    
    func makeView() -> AnyView {
        FileRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        FileRendererConfig(head, tail, host)
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
        config.initialItem.flatMap { context.items.firstIndex(of: $0) } ?? 0
    }
    
    var files: [FileViewerItem] {
        context.items.compactMap { item -> FileViewerItem? in
            guard let file = resolveExpression(config.file, toType: File.self, forItem: item) ?? (item as? File)
                else { return nil }
            return FileViewerItem(url: file.url,
                                  title: resolveExpression(config.itemTitle, toType: String.self, forItem: item))
        }
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

class FileRendererConfig: CascadingRendererConfig {
    var file: Expression? { cascadeProperty("file", type: Expression.self) }
    var itemTitle: Expression? { cascadeProperty("itemTitle", type: Expression.self) }
    var initialItem: Item? { cascadeProperty("initialItem", type: Item.self) }
}

struct FileRendererView: View {
    @ObservedObject var controller: FileRendererController
    
    var body: some View {
        MemriFileViewController(files: controller.files, initialIndex: controller.initialIndex, navBarHiddenBinding: controller.isFullScreen)
    }
    
}
