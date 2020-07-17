//
//  Renderer.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import RealmSwift
import SwiftUI

// Potential solution: https://stackoverflow.com/questions/42746981/list-all-subclasses-of-one-class
var allRenderers: Renderers?

public class Renderers {
	var all: [String: (MemriContext) -> FilterPanelRendererButton] = [:]
	var allViews: [String: AnyView] = [:]
	var allConfigTypes: [String: CascadingRenderConfig.Type] = [:]

	func register(name: String, title: String, order: Int, icon: String = "",
				  view: AnyView, renderConfigType: CascadingRenderConfig.Type,
				  canDisplayResults: @escaping (_ items: [Item]) -> Bool) {
		all[name] = { context in FilterPanelRendererButton(context,
														   name: name,
														   order: order,
														   title: title,
														   icon: icon,
														   canDisplayResults: canDisplayResults) }
		allViews[name] = view
		allConfigTypes[name] = renderConfigType
	}

	class func register(name: String, title: String, order: Int, icon: String = "",
						view: AnyView, renderConfigType: CascadingRenderConfig.Type,
						canDisplayResults: @escaping (_ items: [Item]) -> Bool) {
		allRenderers?.register(name: name, title: title, order: order, icon: icon, view: view,
							   renderConfigType: renderConfigType,
							   canDisplayResults: canDisplayResults)
	}

	init() {
		if allRenderers == nil { allRenderers = self }

		registerCustomRenderer()
		registerListRenderer()
		registerGeneralEditorRenderer()
		registerThumbnailRenderer()
		registerThumbGridRenderer()
		registerThumbHorizontalGridRenderer()
		registerThumbWaterfallRenderer()
		registerMapRenderer()
		registerChartRenderer()
		registerCalendarRenderer()
		registerMessageRenderer()
	}

	var tuples: [(key: String, value: (MemriContext) -> FilterPanelRendererButton)] {
		all.sorted { $0.key < $1.key }
	}
}

class FilterPanelRendererButton: Action, ActionExec {
	private var defaults: [String: Any?] { [
		"activeColor": Color(hex: "#6aa84f"),
		"activeBackgroundColor": Color(hex: "#eee"),
		"title": "Unnamed Renderer",
	] }

	var order: Int
	var canDisplayResults: (_ items: [Item]) -> Bool
	var rendererName: String

	required init(_ context: MemriContext, name: String, order: Int, title: String, icon: String,
				  canDisplayResults: @escaping (_ items: [Item]) -> Bool) {
		rendererName = name
		self.order = order
		self.canDisplayResults = canDisplayResults

		super.init(context, "setRenderer", values: ["icon": icon, "title": title])
	}

	required init(_: MemriContext, arguments _: [String: Any?]? = nil, values _: [String: Any?] = [:]) {
		fatalError("init(arguments:values:) has not been implemented")
	}

	override func isActive() -> Bool? {
		context.cascadingView?.activeRenderer == rendererName
	}

	func exec(_: [String: Any?]) {
		context.cascadingView?.activeRenderer = rendererName
		context.scheduleUIUpdate { _ in true } // scheduleCascadingViewUpdate() // TODO why are userState not kept?
	}
}

public class RenderGroup {
	var options: [String: Any?] = [:]
	var body: UIElement?

	init(_ dict: inout [String: Any?]) {
		body = (dict["children"] as? [UIElement])?.first
		dict.removeValue(forKey: "children")
		options = dict
	}
}

protocol CascadingRendererDefaults {
	func setDefaultValues(_ element: UIElement)
}

//    private var renderDescription: [String:Any]? {
//        let rd = cascadeDict("renderDescription", sessionView.definition)
//
//        if let renderDescription:[String: UIElement] = globalInMemoryObjectCache.get(rd) {
//            return renderDescription
//        }
//        else if let renderDescription:[String: UIElement] = unserialize(rd) {
//            globalInMemoryObjectCache.set(rd, renderDescription)
//            return renderDescription
//        }
//
//        return nil
//    }

public class CascadingRenderConfig: Cascadable {
	required init(_ cascadeStack: [CVUParsedRendererDefinition] = [], _ viewArguments: ViewArguments? = nil) {
		super.init(cascadeStack, viewArguments)
	}

	func hasGroup(_ group: String) -> Bool {
		let x: Any? = cascadeProperty(group)
		return x != nil
	}

	func getGroupOptions(_ group: String) -> [String: Any?] {
		if let renderGroup = getRenderGroup(group) {
			return renderGroup.options
		}
		return [:]
	}

	private func getRenderGroup(_ group: String) -> RenderGroup? {
		if let renderGroup = localCache[group] as? RenderGroup {
			return renderGroup
		} else if group == "*", cascadeProperty("*") == nil {
			if let list: [UIElement] = cascadeProperty("children") {
				var dict = ["children": list] as [String: Any?]
				let renderGroup = RenderGroup(&dict)
				localCache[group] = renderGroup
				return renderGroup
			}
		} else if var dict: [String: Any?] = cascadeProperty(group) {
			let renderGroup = RenderGroup(&dict)
			localCache[group] = renderGroup
			return renderGroup
		}

		return nil
	}

	public func render(item: Item?, group: String = "*",
					   arguments: ViewArguments? = nil) -> UIElementView {
		func doRender(_ renderGroup: RenderGroup, _ item: Item) -> UIElementView {
			if let body = renderGroup.body {
				if let s = self as? CascadingRendererDefaults {
					s.setDefaultValues(body)
				}

				return UIElementView(body, item, arguments ?? viewArguments)
			}
			return UIElementView(UIElement(.Empty), item)
		}

		if let item = item, let renderGroup = getRenderGroup(group) {
			return doRender(renderGroup, item)
		} else {
			return UIElementView(UIElement(.Empty), item ?? Item())
		}
	}
}
