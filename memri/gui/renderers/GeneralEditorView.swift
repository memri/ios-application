//
//  GeneralEditorView.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import RealmSwift
import SwiftUI

let registerGeneralEditorRenderer = {
	Renderers.register(
		name: "generalEditor",
		title: "Default",
		order: 0,
		icon: "pencil.circle.fill",
		view: AnyView(GeneralEditorView()),
		renderConfigType: CascadingGeneralEditorConfig.self,
		canDisplayResults: { items -> Bool in items.count == 1 }
	)
}

class CascadingGeneralEditorConfig: CascadingRenderConfig {
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
            GeneralEditorLayoutItem(dict:dict, viewArguments: self.viewArguments)
        }
	}
}

struct GeneralEditorLayoutItem {
    var id = UUID()
    var dict: [String:Any?]
    var viewArguments: ViewArguments? = nil
    
    func has(_ propName: String) -> Bool {
        return dict[propName] != nil
    }
    
    func get<T>(_ propName:String, _ type:T.Type = T.self, _ item:Item? = nil) -> T? {
        guard let propValue = dict[propName] else {
            if propName == "section" {
                print("ERROR")
            }
            
            return nil
        }
        
        var value:Any? = propValue
        
        // Execute expression to get the right value
        if let expr = propValue as? Expression {
            do {
                value = try expr.execute(viewArguments)
            } catch {
                // TODO: Refactor error handling
                debugHistory.error("Could note compute layout property \(propName)\n"
                    + "Arguments: [\(viewArguments?.asDict().keys.description ?? "")]\n"
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

struct GeneralEditorView: View {
	@EnvironmentObject var context: MemriContext

	var name: String = "generalEditor"

    var body: some View {
        let item = getItem()
        let layout = getLayout()
        let renderConfig = getRenderConfig()
        let usedFields = getUsedFields(layout)

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if renderConfig == nil {
                    Text("Unable to render this view")
                } else if layout.count > 0 {
                    ForEach(layout, id: \.id) { layoutSection in
                        GeneralEditorSection(
                            item: item,
                            renderConfig: renderConfig!,
                            layoutSection: layoutSection,
                            usedFields: usedFields
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func getLayout() -> [GeneralEditorLayoutItem] {
        if let l = getRenderConfig()?.layout {
            return l
        }
        else {
            return [GeneralEditorLayoutItem(dict: ["section": "other", "fields": "*"])]
        }
    }
    
    func getItem() -> Item {
        if let dataItem = context.cascadingView?.resultSet.singletonItem {
            return dataItem
        } else {
            debugHistory.warn("Could not load item from result set, creating empty item")
            return Item()
        }
    }
    
    func getRenderConfig() -> CascadingGeneralEditorConfig? {
        context.cascadingView?.renderConfig as? CascadingGeneralEditorConfig
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

struct GeneralEditorView_Previews: PreviewProvider {
	static var previews: some View {
		let context = try! RootContext(name: "", key: "").mockBoot()

		return ZStack {
			VStack(alignment: .center, spacing: 0) {
				TopNavigation()
				GeneralEditorView()
				Search()
			}.fullHeight()

			ContextPane()
		}.environmentObject(context)
	}
}

struct GeneralEditorSection: View {
	@EnvironmentObject var context: MemriContext

	var item: Item
	var renderConfig: CascadingGeneralEditorConfig
    var layoutSection: GeneralEditorLayoutItem
    var usedFields: [String]

	var body: some View {
        let renderConfig = self.renderConfig
        let editMode = context.currentSession?.editMode ?? false
        let fields:[String] = (layoutSection.get("fields", String.self) == "*"
            ? getProperties(item, usedFields)
            : layoutSection.get("fields", [String].self)) ?? []
        let edgeNames = layoutSection.get("edges", [String].self, item) ?? []
        let edgeType = layoutSection.get("type", String.self, item)
        let edges = layoutSection.get("edges", [Edge].self, item) ?? []
        let groupKey = layoutSection.get("section", String.self) ?? ""
        
        let sectionStyle = self.sectionStyle(groupKey)
        let readOnly = self.layoutSection.get("readOnly", Bool.self) ?? false
        let isEmpty = self.layoutSection.has("edges") && edges.count == 0 && fields.count == 0 && !editMode
        let hasGroup = renderConfig.hasGroup(groupKey)
        
        let title = (hasGroup ? sectionStyle.title : nil) ?? groupKey.camelCaseToWords().uppercased()
        let dividers = sectionStyle.dividers ?? !(sectionStyle.showTitle ?? false)
        let showTitle = sectionStyle.showTitle ?? true
        let action = editMode
            ? sectionStyle.action ?? (!readOnly && edgeType != nil /* TODO support multiple / many types*/
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
                                // TODO error when group doesnt exist?
                                
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
                                    ForEach<[Edge], Edge, UIElementView>(edges, id: \.self) { edge in
                                        let targetItem = edge.item()
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
                                        let targetItem = edge.item()
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

	func _args(groupKey: String = "",
			   name: String = "",
			   value _: Any? = nil,
			   item: Item?,
			   edge: Edge? = nil) -> ViewArguments? {
		try? ViewArguments([
			"subject": item,
			"readOnly": !(context.currentSession?.editMode ?? false),
			"title": groupKey.camelCaseToWords().uppercased(),
			"displayName": name.camelCaseToWords().capitalizingFirst(),
			"name": name,
			"edge": edge,
			".": item,
		].merging(renderConfig.viewArguments?.asDict() ?? [:], uniquingKeysWith: { l, _ in l }))
	}
    
    func getAction(edgeType:String, itemType:String) -> Action {
        return ActionOpenViewByName(
            context,
            arguments: [
                "name": "choose-item-by-query",
                "viewArguments": try? ViewArguments.fromDict([
                    "query": itemType,
                    "type": edgeType,
                    "subject": item,
                    "renderer": "list",
                    "edgeType": edgeType,
                    "title": "Choose a \(itemType)",
                    "dataItem": item,
                ]),
            ],
            values: [
                "icon": "plus",
                "renderAs": RenderType.popup,
            ]
        )
    }
    
    struct SectionStyle {
        let title: String?
        let dividers: Bool?
        let showTitle:Bool?
        let action:Action?
        let spacing:CGFloat?
        let padding:[CGFloat]
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

    func getValue<T>(_ groupKey:String, _ value: Any?, _:T.Type = T.self) -> T? {
        if value == nil { return nil }
        
		if let expr = value as? Expression {
			let args = _args(groupKey: groupKey, name: groupKey, item: item)
			do {
                return try expr.execForReturnType(T.self, args: args)
			} catch {
				debugHistory.error("\(error)")
				return nil
			}
		}

		return value as? T
	}
}

struct DefaultGeneralEditorRow: View {
	@EnvironmentObject var context: MemriContext

	var item: Item
	var prop: String
	var readOnly: Bool
	var isLast: Bool
	var renderConfig: CascadingRenderConfig
	var arguments: ViewArguments?

	var body: some View {
		// Get the type from the schema, because when the value is nil the type cannot be determined
		let propType = item.objectSchema[prop]?.type
        let propValue:Any? = self.item.get(self.prop)

		return VStack(spacing: 0) {
            if propValue == nil && readOnly {
                EmptyView()
            }
            else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prop
                        .camelCaseToWords()
                        .lowercased()
                        .capitalizingFirst()
                    )
                    .generalEditorLabel()

                    if renderConfig.hasGroup(prop) {
                        renderConfig.render(item: item, group: prop, arguments: arguments)
                    } else if readOnly {
                        if [.string, .bool, .date, .int, .double].contains(propType) {
                            defaultRow(ExprInterpreter.evaluateString(propValue, ""))
                        } else if propType == .object {
                            if propValue is Item {
                                MemriButton(context: self._context, item: propValue as! Item)
                            } else {
                                defaultRow()
                            }
                        } else { defaultRow() }
                    } else {
                        if propType == .string { stringRow() }
                        else if propType == .bool { boolRow() }
                        else if propType == .date { dateRow() }
                        else if propType == .int { intRow() }
                        else if propType == .double { doubleRow() }
                        else if propType == .object { defaultRow() }
                        else { defaultRow() }
                    }
                }
                .fullWidth()
                .padding(.bottom, 10)
                .padding(.horizontal, 36)
                .background(readOnly ? Color(hex: "#f9f9f9") : Color(hex: "#f7fcf5"))

                if !isLast {
                    Divider().padding(.leading, 35)
                }
            }
		}
	}

	func stringRow() -> some View {
		let binding = Binding<String>(
			get: { self.item.getString(self.prop) },
			set: {
				self.item.set(self.prop, $0)
			}
		)

		return MemriTextField(value: binding)
			.onEditingBegan {
				self.context.currentSession?.editMode = true
			}
			.generalEditorCaption()
	}

	func boolRow() -> some View {
		let binding = Binding<Bool>(
			get: { self.item[self.prop] as? Bool ?? false },
			set: { _ in
				self.item.toggle(self.prop)
				self.context.objectWillChange.send()
			}
		)

		return Toggle(isOn: binding) {
			Text(prop
				.camelCaseToWords()
				.lowercased()
				.capitalizingFirst())
		}
		.toggleStyle(MemriToggleStyle())
		.generalEditorCaption()
	}

	func intRow() -> some View {
		let binding = Binding<Int>(
			get: { self.item[self.prop] as? Int ?? 0 },
			set: {
				self.item.set(self.prop, $0)
				self.context.objectWillChange.send()
			}
		)

		return MemriTextField(value: binding)
			.onEditingBegan {
				self.context.currentSession?.editMode = true
			}
			.generalEditorCaption()
	}

	func doubleRow() -> some View {
		let binding = Binding<Double>(
			get: { self.item[self.prop] as? Double ?? 0 },
			set: {
				self.item.set(self.prop, $0)
				self.context.objectWillChange.send()
			}
		)

		return MemriTextField(value: binding)
			.onEditingBegan {
				self.context.currentSession?.editMode = true
			}
			.generalEditorCaption()
	}

	func dateRow() -> some View {
		let binding = Binding<Date>(
			get: { self.item[self.prop] as? Date ?? Date() },
			set: {
				self.item.set(self.prop, $0)
				self.context.objectWillChange.send()
			}
		)

		return DatePicker("", selection: binding, displayedComponents: .date)
			.frame(width: 300, height: 80, alignment: .center)
			.clipped()
			.padding(8)
	}

	func defaultRow(_ caption: String? = nil) -> some View {
		Text(caption ?? prop.camelCaseToWords().lowercased().capitalizingFirst())
			.generalEditorCaption()
	}
}

public extension View {
	func generalEditorLabel() -> some View { modifier(GeneralEditorLabel()) }
	func generalEditorCaption() -> some View { modifier(GeneralEditorCaption()) }
	func generalEditorHeader() -> some View { modifier(GeneralEditorHeader()) }
	func generalEditorInput() -> some View { modifier(GeneralEditorInput()) }
}

private struct GeneralEditorInput: ViewModifier {
	func body(content: Content) -> some View {
		content
			.fullHeight()
			.font(.system(size: 16, weight: .regular))
			.padding(10)
			.border(width: [0, 0, 1, 1], color: Color(hex: "#eee"))
			.generalEditorCaption()
	}
}

private struct GeneralEditorLabel: ViewModifier {
	func body(content: Content) -> some View {
		content
			.foregroundColor(Color(hex: "#38761d"))
			.font(.system(size: 14, weight: .regular))
			.padding(.top, 10)
	}
}

private struct GeneralEditorCaption: ViewModifier {
	func body(content: Content) -> some View {
		content
			.font(.system(size: 18, weight: .regular))
			.foregroundColor(Color(hex: "#223322"))
	}
}

private struct GeneralEditorHeader: ViewModifier {
	func body(content: Content) -> some View {
		content
			.font(Font.system(size: 15, weight: .regular))
			.foregroundColor(Color(hex: "#434343"))
			.padding(.bottom, 5)
			.padding(.top, 24)
			.padding(.horizontal, 36)
			.foregroundColor(Color(hex: "#333"))
	}
}
