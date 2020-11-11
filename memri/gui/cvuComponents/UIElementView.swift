//
// UIElementView.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift
import SwiftUI

public enum UIElementFamily: String, CaseIterable {
    // Implemented
    case VStack, HStack, ZStack, FlowStack
    case Text, SmartText, Textfield
    case Image
    case Toggle, Picker
    case MemriButton, Button, ActionButton
    case Map
    case Empty, Spacer, Divider, HorizontalLine
    case Circle, Rectangle
    case EditorSection, EditorRow
    case SubView
    case HTMLView
    case TimelineItem
    case ItemCell
    case FileThumbnail
}

public struct UIElementView: SwiftUI.View {
    @EnvironmentObject var context: MemriContext

    var nodeResolver: UINodeResolver

    var editModeBinding: Binding<Bool> { Binding<Bool>(
        get: { self.context.editMode },
        set: { self.context.editMode = $0 }
    ) }

    @ViewBuilder
    var resolvedComponent: some View {
        switch nodeResolver.node.type {
        case .HStack:
            CVU_HStack(nodeResolver: nodeResolver)
        case .VStack:
            CVU_VStack(nodeResolver: nodeResolver)
        case .ZStack:
            CVU_ZStack(nodeResolver: nodeResolver)
        case .Text:
            CVU_Text(nodeResolver: nodeResolver)
        case .SmartText:
            CVU_SmartText(nodeResolver: nodeResolver)
        case .Image:
            CVU_Image(nodeResolver: nodeResolver)
        case .Map:
            CVU_Map(nodeResolver: nodeResolver)
        case .Textfield:
            CVU_TextField(nodeResolver: nodeResolver, editModeBinding: editModeBinding)
        case .EditorSection:
            CVU_EditorSection(nodeResolver: nodeResolver)
        case .EditorRow:
            CVU_EditorRow(nodeResolver: nodeResolver)
        case .Toggle:
            CVU_Toggle(nodeResolver: nodeResolver)
        case .MemriButton:
            CVU_MemriButton(nodeResolver: nodeResolver)
        case .ActionButton:
            ActionButton(
                action: nodeResolver.resolve("press") ?? Action(context, "noop"),
                item: nodeResolver.item
            )
        case .Button:
            CVU_Button(nodeResolver: nodeResolver, context: context)
        case .Divider:
            Divider()
        case .HorizontalLine:
            HorizontalLine()
        case .Circle:
            CVU_Shape.Circle(nodeResolver: nodeResolver)
        case .Rectangle:
            CVU_Shape.Rectangle(nodeResolver: nodeResolver)
        case .HTMLView:
            CVU_HTMLView(nodeResolver: nodeResolver)
        case .Spacer:
            Spacer()
        case .Empty:
            EmptyView()
        case .SubView:
            subview
        case .FlowStack:
            flowstack
        case .Picker:
            picker
        case .ItemCell:
            ItemCell(item: nodeResolver.item,
                     rendererNames: nodeResolver
                         .resolve("rendererNames", type: [String].self) ?? [],
                     arguments: nodeResolver.viewArguments)
        case .TimelineItem:
            CVU_TimelineItem(nodeResolver: nodeResolver)
        case .FileThumbnail:
            CVU_FileThumbnail(nodeResolver: nodeResolver)
        }
    }

    var needsModifier: Bool {
        guard nodeResolver.showNode else { return false }
        switch nodeResolver.node.type {
        case .Empty, .Spacer, .Divider, .FlowStack: return false
        default: return true
        }
    }

    @ViewBuilder
    public var body: some View {
        if nodeResolver.showNode {
            resolvedComponent
                .if(needsModifier) {
                    $0.modifier(CVU_AppearanceModifier(nodeResolver: nodeResolver))
                }
        }
    }

    var flowstack: some View {
        FlowStack(
            data: nodeResolver.resolve("list", type: [Item].self) ?? [],
            spacing: nodeResolver.spacing
        ) { listItem in
            nodeResolver.childrenInForEach(usingItem: listItem)
        }
    }

    @ViewBuilder
    var picker: some View {
        let (_, propItem, propName) = nodeResolver.getType(for: "value")
        let selected = nodeResolver.resolve("value", type: Item.self) ?? nodeResolver
            .resolve("defaultValue", type: Item.self)
        let emptyValue = nodeResolver.resolve("hint") ?? "Pick a value"
        let query = nodeResolver.resolve("query", type: String.self)
        let renderer = nodeResolver.resolve("renderer", type: String.self)

        if let item = nodeResolver.item, let propItem = propItem {
            Picker(
                item: item,
                selected: selected,
                title: nodeResolver.string(for: "title") ?? "Select:",
                emptyValue: emptyValue,
                propItem: propItem,
                propName: propName,
                renderer: renderer,
                query: query ?? ""
            )
        }
    }

    @ViewBuilder
    var subview: some View {
        let subviewArguments = ViewArguments(nodeResolver
            .resolve("arguments", type: [String: Any?].self))
        if let viewName = nodeResolver.string(for: "viewName") {
            SubView(
                context: self.context,
                viewName: viewName,
                item: nodeResolver.item,
                viewArguments: subviewArguments
            )
        }
        else {
            // TODO: Carried over from the old UIElementView - this has potential to cause performance issues.
            // It is creating a new CVU at every redraw.
            // Instead architect this to only create the CVU once and have that one reload
            SubView(
                context: self.context,
                view: {
                    if let parsed: [String: Any?] = nodeResolver.resolve("view") {
                        let def = CVUParsedViewDefinition(
                            "[view]",
                            type: "view",
                            parsed: parsed
                        )
                        do {
                            return try CVUStateDefinition.fromCVUParsedDefinition(def)
                        }
                        catch {
                            debugHistory.error("\(error)")
                        }
                    }
                    else {
                        debugHistory
                            .error(
                                "Failed to make subview (not defined), creating empty one instead"
                            )
                    }
                    return CVUStateDefinition()
                }(),
                item: nodeResolver.item,
                viewArguments: subviewArguments
            )
        }
    }
}
