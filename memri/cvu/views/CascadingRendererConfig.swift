//
// CascadingRendererConfig.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import RealmSwift
import SwiftUI

public class RenderGroup {
    var options: [String: Any?] = [:]
    var body: UINode?

    init(_ dict: inout [String: Any?]) {
        body = (dict["children"] as? [UINode])?.first
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

    // Defaults (intended for renderers to override if they desire a different default)
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
            if let list: [UINode] = cascadeProperty("children") {
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
        arguments: ViewArguments = ViewArguments()
    ) -> AnyView {
        if let item = item, let body = getRenderGroup(group)?.body {
            let nodeResolver = UINodeResolver(node: body, viewArguments: arguments.copy(item))
            return UIElementView(nodeResolver: nodeResolver).eraseToAnyView()
        }
        else {
            return EmptyView().eraseToAnyView()
        }
    }
}
