//
// Renderers.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import RealmSwift
import SwiftUI

public class RenderGroup {
    var options: [String: Any?] = [:]
    var body: UIElement?

    init(_ dict: inout [String: Any?]) {
        body = (dict["children"] as? [UIElement])?.first
        dict.removeValue(forKey: "children")
        options = dict
    }
}

public class CascadingRendererConfig: Cascadable {
    required init(
        _ head: CVUParsedDefinition? = nil,
        _ tail: [CVUParsedDefinition]? = nil,
        _ host: Cascadable? = nil
    ) {
        super.init(head, tail, host)
    }
    
    // Used for ui purposes. Random value that doesn't need to be persisted
    let ui_UUID = UUID()
    
    // Defaults (intended for renderers to override)
    var defaultEdgeInset: UIEdgeInsets { .zero }
    var defaultSpacing: CGSize { .zero }

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
        }
        else if group == "*", cascadeProperty("*") == nil {
            if let list: [UIElement] = cascadeProperty("children") {
                var dict = ["children": list] as [String: Any?]
                let renderGroup = RenderGroup(&dict)
                localCache[group] = renderGroup
                return renderGroup
            }
        }
        else if var dict: [String: Any?] = cascadeProperty(group) {
            let renderGroup = RenderGroup(&dict)
            localCache[group] = renderGroup
            return renderGroup
        }

        return nil
    }

    public func render(
        item: Item?,
        group: String = "*",
        arguments: ViewArguments? = nil
    ) -> UIElementView {
        func doRender(_ renderGroup: RenderGroup, _ item: Item) -> UIElementView {
            if let body = renderGroup.body {
                return UIElementView(body, item, arguments ?? viewArguments)
            }
            return UIElementView(UIElement(.Empty), item)
        }

        if let item = item, let renderGroup = getRenderGroup(group) {
            return doRender(renderGroup, item)
        }
        else {
            return UIElementView(UIElement(.Empty), item ?? Item())
        }
    }
}
