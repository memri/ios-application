//
// PhotoViewerRenderer.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

class PhotoViewerRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "photoViewer", icon: "camera", makeController: PhotoViewerRendererController.init, makeConfig: PhotoViewerRendererController.makeConfig)
    
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? PhotoViewerRendererConfig) ?? PhotoViewerRendererConfig()
    }
    
    let context: MemriContext
    let config: PhotoViewerRendererConfig
    
    func makeView() -> AnyView {
        PhotoViewerRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        PhotoViewerRendererConfig(head, tail, host)
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
    
    var hasItems: Bool {
        !context.items.isEmpty
    }
    
    func photoItemProvider(forIndex index: Int) -> PhotoViewerController.PhotoItem? {
        guard let item = context.items[safe: index],
            let file = resolveExpression(config.imageFile, toType: File.self, forItem: item),
            let url = file.url
            else {
                return nil
        }
        let overlay = config.render(item: item).environmentObject(context).eraseToAnyView()
        return PhotoViewerController.PhotoItem(index: index, imageURL: url, overlay: overlay)
    }

    func onToggleOverlayVisibility(_ visible: Bool) {
        withAnimation {
            self.isFullScreen = !visible
        }
    }
    
    func toggleFullscreen() {
        isFullScreen.toggle()
    }
    
    var isFullScreen: Bool {
        get { context.currentView?.fullscreen ?? false }
        set { context.currentView?.fullscreen = newValue }
    }
}

class PhotoViewerRendererConfig: CascadingRendererConfig, ConfigurableRenderConfig {
    var imageFile: Expression? { cascadeProperty("file", type: Expression.self) }
    var initialItem: Item? { cascadeProperty("initialItem", type: Item.self) }
    
    
    var showSortInConfig: Bool = true
    func configItems(context: MemriContext) -> [ConfigPanelModel.ConfigItem] {
        []
    }
    let showContextualBarInEditMode: Bool = false
}

struct PhotoViewerRendererView: View {
    @ObservedObject var controller: PhotoViewerRendererController

    var body: some View {
        Group {
            if controller.hasItems {
                ZStack(alignment: .topLeading) {
                    PhotoViewerView(
                        photoItemProvider: controller.photoItemProvider,
                        initialIndex: controller.initialIndex,
                        onToggleOverlayVisibility: controller.onToggleOverlayVisibility
                    )
                        .edgesIgnoringSafeArea(controller.isFullScreen ? .all : [])
                }
            } else {
                Text("No photos found").bold().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

}
