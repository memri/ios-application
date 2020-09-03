//
// GeneralEditorView.swift
// Copyright © 2020 memri. All rights reserved.

import RealmSwift
import SwiftUI

class GeneralEditorRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "generalEditor", icon: "pencil.circle.fill", makeController: GeneralEditorRendererController.init, makeConfig: GeneralEditorRendererController.makeConfig)
    
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? GeneralEditorRendererConfig) ?? GeneralEditorRendererConfig()
    }
    
    let context: MemriContext
    let config: GeneralEditorRendererConfig
    
    func makeView() -> AnyView {
        GeneralEditorRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        GeneralEditorRendererConfig(head, tail, host)
    }
}


class GeneralEditorRendererConfig: CascadingRendererConfig, ConfigurableRenderConfig {
    
    var type: String? = "generalEditor"

    var layout: [GeneralEditorLayoutItem] {
        cascadeList(
            "layout",
            uniqueKey: { $0["section"] as? String ?? "" },
            merging: { old, new in
                var result = old
                for (key, value) in new {
                    if old[key] == nil { result[key] = value }
                    else if key == "exclude" {
                        if var dict = old[key] as? [String] {
                            result[key] = dict.append(contentsOf: new[key] as? [String] ?? [])
                        }
                    }
                }

                return result
            }
        )
        .map { dict -> GeneralEditorLayoutItem in
            GeneralEditorLayoutItem(dict: dict, viewArguments: self.viewArguments)
        }
    }
    
    var showSortInConfig: Bool = false
    
    var showContextualBarInEditMode: Bool = false
    
    func configItems(context: MemriContext) -> [ConfigPanelModel.ConfigItem] {
        []
    }
}

struct GeneralEditorLayoutItem {
    var id = UUID()
    var dict: [String: Any?]
    var viewArguments: ViewArguments? = nil

    func has(_ propName: String) -> Bool {
        dict[propName] != nil
    }

    func get<T>(_ propName: String, _: T.Type = T.self, _ item: Item? = nil) -> T? {
        guard let propValue = dict[propName] else {
            if propName == "section" {
                print("ERROR")
            }

            return nil
        }

        var value: Any? = propValue

        // Execute expression to get the right value
        if let expr = propValue as? Expression {
            do {
                value = try expr.execute(viewArguments)
            }
            catch {
                // TODO: Refactor error handling
                debugHistory.error("Could not compute layout property \(propName)\n"
                    + "Arguments: [\(viewArguments?.description ?? "")]\n"
                    + (expr.startInStringMode
                        ? "Expression: \"\(expr.code)\"\n"
                        : "Expression: \(expr.code)\n")
                    + "Error: \(error)")
                return nil
            }
        }

        if T.self == [Edge].self {
            if value is [Edge] {
                return value as? T
            }
            else if let value = value as? String {
                return item?.edges(value)?.edgeArray() as? T
            }
            else if let value = value as? [String] {
                return item?.edges(value)?.edgeArray() as? T
            }
        }
        else if T.self == [String].self && value is String {
            return [value] as? T
        }

        return value as? T
    }
}

struct GeneralEditorRendererView: View {
    @ObservedObject var controller: GeneralEditorRendererController
    @EnvironmentObject var context: MemriContext

    var name: String = "generalEditor"

    var body: some View {
        let item = getItem()
        let layout = controller.config.layout
        let renderConfig = controller.config
        let usedFields = getUsedFields(layout)

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if layout.count > 0 {
                    ForEach(layout, id: \.id) { layoutSection in
                        GeneralEditorSection(
                            item: item,
                            renderConfig: renderConfig,
                            layoutSection: layoutSection,
                            usedFields: usedFields
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func getItem() -> Item {
        if let dataItem = context.currentView?.resultSet.singletonItem {
            return dataItem
        }
        else {
            debugHistory.warn("Could not load item from result set, creating empty item")
            return Item()
        }
    }

    func getUsedFields(_ layout: [GeneralEditorLayoutItem]) -> [String] {
        var result = [String]()
        for item in layout {
            if let list = item.get("fields", [String].self) {
                result.append(contentsOf: list)
            }
            if let list = item.get("exclude", [String].self) {
                result.append(contentsOf: list)
            }
        }
        return result
    }
}

//struct GeneralEditorView_Previews: PreviewProvider {
//    static var previews: some View {
//        let context = try! RootContext(name: "").mockBoot()
//
//        return ZStack {
//            VStack(alignment: .center, spacing: 0) {
//                TopNavigation()
//                GeneralEditorRendererView(controller: GeneralEditorRendererController(context: context, config: nil))
//                Search()
//            }.fullHeight()
//
//            ContextPane()
//        }.environmentObject(context)
//    }
//}

struct GeneralEditorSection: View {
    @EnvironmentObject var context: MemriContext

    var item: Item
    var renderConfig: GeneralEditorRendererConfig
    var layoutSection: GeneralEditorLayoutItem
    var usedFields: [String]

    var body: some View {
        let renderConfig = self.renderConfig
        let editMode = context.currentSession?.editMode ?? false
        let fields: [String] = (layoutSection.get("fields", String.self) == "*"
            ? getProperties(item, usedFields)
            : layoutSection.get("fields", [String].self)) ?? []
        let edgeNames = layoutSection.get("edges", [String].self, item) ?? []
        let edgeType = layoutSection.get("type", String.self, item)
        let edges = layoutSection.get("edges", [Edge].self, item) ?? []
        let groupKey = layoutSection.get("section", String.self) ?? ""

        let sectionStyle = self.sectionStyle(groupKey)
        let readOnly = self.layoutSection.get("readOnly", Bool.self) ?? false
        let isEmpty = self.layoutSection.has("edges") && edges.count == 0 && fields
            .count == 0 && !editMode
        let hasGroup = renderConfig.hasGroup(groupKey)

        let title = (hasGroup ? sectionStyle.title : nil) ?? groupKey.camelCaseToWords()
            .uppercased()
        let dividers = sectionStyle.dividers ?? !(sectionStyle.showTitle ?? false)
        let showTitle = sectionStyle.showTitle ?? true
        let action = editMode
            ? sectionStyle
            .action ?? (!readOnly && edgeType != nil /* TODO: support multiple / many types*/
                ? getAction(edgeType: edgeNames[0], itemType: edgeType ?? "")
                : nil)
            : nil
        let spacing = sectionStyle.spacing ?? 0
        let padding = sectionStyle.padding

        return Section(
            header: Group {
                if showTitle && !isEmpty {
                    HStack(alignment: .bottom) {
                        Text(title)
                            .generalEditorHeader()

                        if action != nil {
                            Spacer()
                            // NOTE: Allowed force unwrapping
                            ActionButton(action: action, item: item)
                                .foregroundColor(Color(hex: "#777"))
                                .font(.system(size: 18, weight: .semibold))
                                .padding(.bottom, 10)
                        }
                    }.padding(.trailing, 20)
                }
                else {
                    EmptyView()
                }
            },

            content: {
                if isEmpty {
                    EmptyView()
                }
                else {
                    if dividers { Divider() }

                    // If a render group is defined in the render config
                    if hasGroup {
                        // Add spacing between the render elements
                        VStack(alignment: .leading, spacing: spacing) {
                            // layoutSection describes a render group defined in the render config
                            if fields.count == 0 && edges.count == 0 {
                                // TODO: error when group doesnt exist?

                                renderConfig.render(
                                    item: self.item,
                                    group: groupKey,
                                    arguments: self._args(groupKey: groupKey,
                                                          name: groupKey,
                                                          item: self.item)
                                )
                            }
                            // Render boths fields and edges in the same section
                            else {
                                // Render the fields
                                if fields.count > 0 {
                                    ForEach(fields, id: \.self) { field in
                                        renderConfig.render(
                                            item: self.item,
                                            group: groupKey,
                                            arguments: self._args(groupKey: groupKey,
                                                                  name: field,
                                                                  item: self.item)
                                        )
                                    }
                                }
                                // Render the edges
                                if edges.count > 0 {
                                    ForEach<[Edge], Edge, UIElementView>(edges,
                                                                         id: \.self) { edge in
                                        let targetItem = edge.target()
                                        return renderConfig.render(
                                            item: targetItem,
                                            group: groupKey,
                                            arguments: self._args(groupKey: groupKey,
                                                                  value: targetItem,
                                                                  item: targetItem,
                                                                  edge: edge)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: padding[0],
                                            leading: padding[3],
                                            bottom: padding[2],
                                            trailing: padding[1]))
                    }

                    else if fields.count == 0 && edges.count == 0 {
                        // Error
                    }

                    // Default renderers
                    else {
                        // Render groups with the default render row
                        if fields.count > 0 {
                            ForEach(fields, id: \.self) { field in
                                DefaultGeneralEditorRow(
                                    context: self._context,
                                    item: self.item,
                                    prop: field,
                                    readOnly: !editMode || readOnly,
                                    isLast: fields.last == field,
                                    renderConfig: renderConfig,
                                    arguments: self._args(name: field,
                                                          value: self.item.get(field),
                                                          item: self.item)
                                )
                            }
                        }
                        // Render lists with their default renderer
                        if edges.count > 0 {
                            ScrollView {
                                VStack(alignment: .leading, spacing: spacing) {
                                    ForEach<[Edge], Edge, ItemCell>(edges, id: \.self) { edge in
                                        let targetItem = edge.target()
                                        return ItemCell(
                                            item: targetItem,
                                            rendererNames: ["generalEditor"],
                                            arguments: self._args(groupKey: groupKey,
                                                                  name: edge.type ?? "",
                                                                  value: targetItem,
                                                                  item: self.item,
                                                                  edge: edge)
                                        )
                                    }
                                }
                                .padding(EdgeInsets(top: padding[0],
                                                    leading: padding[3],
                                                    bottom: padding[2],
                                                    trailing: padding[1]))
                            }
                            .frame(maxHeight: 1000)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if dividers { Divider() }
                }
            }
        )
    }

    func getProperties(_ item: Item, _ used: [String]) -> [String] {
        item.objectSchema.properties.filter {
            !used.contains($0.name)
                && !$0.isArray
        }.map { $0.name }
    }

    func _args(
        groupKey: String = "",
        name: String = "",
        value _: Any? = nil,
        item: Item?,
        edge: Edge? = nil
    ) -> ViewArguments? {
        ViewArguments(
            [
                "subject": item,
                "readOnly": !(context.currentSession?.editMode ?? false),
                "title": groupKey.camelCaseToWords().uppercased(),
                "displayName": name.camelCaseToWords().capitalizingFirst(),
                "name": name,
                "edge": edge,
                ".": item,
            ],
            renderConfig.viewArguments?.cascadeStack
        )
    }

    func getAction(edgeType: String, itemType: String) -> Action {
        ActionOpenViewByName(
            context,
            values: [
                "name": "choose-item-by-query",
                "viewArguments": ViewArguments([
                    "query": itemType,
                    "type": edgeType,
                    "subject": item,
                    "renderer": "list",
                    "edgeType": edgeType,
                    "title": "Choose a \(itemType)",
                    "item": item,
                ]),
                "icon": "plus",
                "renderAs": RenderType.popup,
            ]
        )
    }

    struct SectionStyle {
        let title: String?
        let dividers: Bool?
        let showTitle: Bool?
        let action: Action?
        let spacing: CGFloat?
        let padding: [CGFloat]
    }

    func sectionStyle(_ groupKey: String) -> SectionStyle {
        let s = renderConfig.getGroupOptions(groupKey)
        let allPadding = getValue(groupKey, s["padding"] as Any?, CGFloat.self) ?? 0

        return SectionStyle(
            title: getValue(groupKey, s["title"] as Any?, String.self)?.uppercased(),
            dividers: getValue(groupKey, s["dividers"] as Any?, Bool.self),
            showTitle: getValue(groupKey, s["showTitle"] as Any?, Bool.self),
            action: getValue(groupKey, s["action"] as Any?, Action.self),
            spacing: getValue(groupKey, s["spacing"] as Any?, CGFloat.self),
            padding: getValue(groupKey, s["padding"] as Any?, [CGFloat].self)
                ?? [allPadding, allPadding, allPadding, allPadding]
        )
    }

    func getValue<T>(_ groupKey: String, _ value: Any?, _: T.Type = T.self) -> T? {
        if value == nil { return nil }

        if let expr = value as? Expression {
            let args = _args(groupKey: groupKey, name: groupKey, item: item)
            do {
                return try expr.execForReturnType(T.self, args: args)
            }
            catch {
                debugHistory.error("\(error)")
                return nil
            }
        }

        return value as? T
    }
}
