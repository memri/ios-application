//
//  PhotoViewerRenderer.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 21/7/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation
import SwiftUI

let registerPhotoViewerRenderer = {
	Renderers.register(
		name: "photoViewer",
		title: "Default",
		order: 10,
		icon: "camera",
		view: AnyView(PhotoViewerRenderer()),
		renderConfigType: PhotoViewerRendererConfig.self,
		canDisplayResults: { items -> Bool in !items.isEmpty }
	)
}

class PhotoViewerRendererConfig: CascadingRenderConfig {
	var type: String? = "photoViewer"
	
	var imageFile: Expression? { cascadeProperty("file", type: Expression.self) }
	var initialItem: Item? { cascadeProperty("initialItem", type: Item.self) }
}

struct PhotoViewerRenderer: View {
	@EnvironmentObject var context: MemriContext
	var renderConfig: PhotoViewerRendererConfig {
		context.currentView?.renderConfig as? PhotoViewerRendererConfig ?? PhotoViewerRendererConfig()
	}
	
	func resolveExpression<T>(_ expression: Expression?,
							  toType _: T.Type = T.self,
							  forItem dataItem: Item) -> T? {
		let args = ViewArguments(context.currentView?.viewArguments)
		args.set(".", dataItem)
		return try? expression?.execForReturnType(T.self, args: args)
	}
	
	var initialIndex: Int  {
		renderConfig.initialItem.flatMap { context.items.firstIndex(of: $0) } ?? 0
	}
	
	func photoItemProvider(forIndex index: Int) -> PhotoViewerController.PhotoItem? {
		guard let item = context.items[safe: index],
			  let file = resolveExpression(renderConfig.imageFile, toType:File.self, forItem: item),
			  let url = file.url
		else {
			return nil
		}
		let overlay = renderConfig.render(item: item).environmentObject(context).eraseToAnyView()
		return PhotoViewerController.PhotoItem(index: index, imageURL: url, overlay: overlay)
	}
	
	var body: some View {
		Group {
			if context.items.isEmpty {
				Text("No photos found")
			} else {
				ZStack(alignment: .topLeading) {
					PhotoViewerView(photoItemProvider: photoItemProvider, initialIndex: initialIndex)
						.edgesIgnoringSafeArea(isFullScreen ? .all : [])
					Button(action: toggleFullscreen) {
						Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
							.padding(12)
							.background(RoundedRectangle(cornerRadius: 4).fill(Color(.systemFill)))
					}
					.padding(.top, 20)
					.padding(.leading, 20)
				}
			}
		}
	}
	
	func toggleFullscreen() {
		isFullScreen.toggle()
	}
	
	var isFullScreen: Bool {
		get { context.currentView?.fullscreen ?? false }
		nonmutating set { context.currentView?.fullscreen = newValue }
	}
}

struct PhotoViewerRenderer_Previews: PreviewProvider {
	static var previews: some View {
		PhotoViewerRenderer()
	}
}
