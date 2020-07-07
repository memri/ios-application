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
    var dict: [String:Any]
    var viewArguments: ViewArguments? = nil
    
    func get<T>(_ propName:String, _ type:T.Type = T.self) -> T? {
        var result:Any? = nil
        
        guard let propValue = dict[propName] else {
            if propName == "section" {
                print("ERROR")
            }
            
            return nil
        }
        
        // Execute expression to get the right value
        if let expr = propValue as? Expression {
            do {
                result = try expr.execute(viewArguments) as? T
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
        else {
            result = propValue as? T
        }
        
        if T.self == [String].self && result is String {
            return [result] as? T
        }
        
        return result as? T
    }
}

struct GeneralEditorView: View {
	@EnvironmentObject var context: MemriContext

	var name: String = "generalEditor"

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
        }
        return result
    }
    
	var body: some View {
		let item = getItem()
        let layout = getLayout()
		let renderConfig = getRenderConfig()
        let usedFields = getUsedFields(layout)
//		let groups = getGroups(item) ?? [:]
//		let sortedKeys = getSortedKeys(groups)

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

//	func getGroups(_ item: Item) -> [String: [String]]? {
//		let renderConfig = self.renderConfig
//		let groups = renderConfig?.groups ?? [:]
//		var filteredGroups: [String: [String]] = [:]
//		let objectSchema = item.objectSchema
//		var alreadyUsed: [String] = []
//
//		for (key, value) in groups {
//			if value.first != key { alreadyUsed = alreadyUsed + value }
//		}
//
//		(Array(groups.keys) + objectSchema.properties.map { $0.name }).filter {
//			return (groups[$0] != nil || objectSchema[$0]?.isArray ?? false)
//				&& !(renderConfig?.excluded.contains($0) ?? false)
//				&& !alreadyUsed.contains($0)
//		}.forEach {
//			filteredGroups[$0] = groups[$0] ?? [$0]
//		}
//
//		return filteredGroups.count > 0 ? filteredGroups : nil
//	}
//
//	func getSortedKeys(_ groups: [String: [String]]) -> [String] {
//		var keys = renderConfig?.sequence ?? []
//		for k in groups.keys {
//			if !keys.contains(k) {
//				keys.append(k)
//			}
//		}
//
//		keys = keys.filter { !(self.renderConfig?.excluded.contains($0) ?? true) }
//
//		if !keys.contains("other") {
//			keys.append("other")
//		}
//
//		return keys
//	}
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
//	var groupKey: String
//	var groups: [String: [String]]

	var body: some View {
        let renderConfig = self.renderConfig
        let editMode = context.currentSession?.isEditMode ?? false
        let fields:[String]? = layoutSection.get("fields", String.self) == "*"
            ? getProperties(item, layoutSection.get("exclude", [String].self), usedFields)
            : layoutSection.get("fields", [String].self)
        let edges:[String]? = layoutSection.get("edges", [String].self)
        let groupKey = layoutSection.get("section", String.self) ?? ""
        let showDividers = self.hasSectionTitle(groupKey)
        let listHasItems = edges?.count ?? 0 > 0 && item.edge(groupKey) != nil
        
        /*
         if group
             draw section (optional)
                 draw group
         
         if fields (or all remaining fields)
            draw section ~(optional)
                for each field
                    draw row (defaults in CVU?)
         
         else if edges
            draw section ~(optional)
                for each edge
                    draw row
         
         else
            error
         
         
         */
        

        return Section(header: self.getHeader(edges != nil, listHasItems, groupKey)) {
            if edges != nil && !listHasItems && !editMode {
                EmptyView()
            }
            // Render using a view specified renderer
            else if renderConfig.hasGroup(groupKey) {
                if showDividers { Divider() }

                if self.isDescriptionForGroup(groupKey) {
                    renderConfig.render(
                        item: item,
                        group: groupKey,
                        arguments: self._args(groupKey: groupKey,
                                              name: groupKey,
                                              item: self.item)
                    )
                } else {
                    if edges != nil {
                        item.edges(groupKey).map { edges in
                            ForEach<Results<Edge>, Edge, UIElementView>(edges, id: \.self) { edge in
                                let otherItem = edge.item()
                                return renderConfig.render(
                                    item: otherItem,
                                    group: groupKey,
                                    arguments: self._args(groupKey: groupKey,
                                                          value: otherItem,
                                                          item: otherItem,
                                                          edge: edge)
                                )
                            }
                        }
                    } else {
                        // TODO: Error handling
                        ForEach(fields ?? [], id: \.self) { groupElement in
                            renderConfig.render(
                                item: self.item,
                                group: groupKey,
                                arguments: self._args(groupKey: groupKey,
                                                      name: groupElement,
                                                      item: self.item)
                            )
                        }
                    }
                }

                if showDividers { Divider() }
            }
            // Render lists with their default renderer
            else if edges != nil {
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach<Results<Edge>, Edge, ItemCell>(item.edges(groupKey)!, id: \.self) { edge in
                            let item = edge.item()
                            return ItemCell(
                                item: item,
                                rendererNames: ["generalEditor"],
                                arguments: self._args(groupKey: groupKey,
                                                      name: groupKey,
                                                      value: item,
                                                      item: self.item,
                                                      edge: edge)
                            )
                        }
                    }
                    //                        .padding(.top, 10)
                }
                .frame(maxHeight: 1000)
                .fixedSize(horizontal: false, vertical: true)

                Divider()
            }
            // Render groups with the default render row
            else {
                Divider()
                ForEach(fields ?? [], id: \.self) { prop in

                    // TODO: Refactor: rows that are single links to an item

                    DefaultGeneralEditorRow(
                        context: self._context,
                        item: self.item,
                        prop: prop,
                        readOnly: !editMode || self.layoutSection.get("readOnly", Bool.self) ?? false,
                        isLast: fields?.last == prop,
                        renderConfig: renderConfig,
                        arguments: self._args(name: prop,
                                              value: self.item.get(prop),
                                              item: self.item)
                    )
                }
                Divider()
            }
        }
	}

	//    func getArray(_ item: Item, _ prop: String) -> [Item] {
	//        dataItemListToArray(item[prop] ?? [])
	//    }

    func getProperties(_ item: Item, _ exclude: [String]?, _ used: [String]) -> [String] {
		item.objectSchema.properties.filter {
			!(exclude?.contains($0.name) ?? false)
				&& !used.contains($0.name)
				&& !$0.isArray
		}.map { $0.name }
	}

	func _args(groupKey: String = "",
			   name: String = "",
			   value _: Any? = nil,
			   item: Item?,
			   edge: Edge? = nil) -> ViewArguments? {
		try? ViewArguments([
			"subject": item as Any,
			"readOnly": !(context.currentSession?.isEditMode ?? false),
			"sectionTitle": groupKey.camelCaseToWords().uppercased(),
			"displayName": name.camelCaseToWords().capitalizingFirst(),
			"name": name,
			"edge": edge as Any,
			".": item as Any,
		].merging(renderConfig.viewArguments?.asDict() ?? [:], uniquingKeysWith: { l, _ in l }))
	}

	func hasSectionTitle(_ groupKey: String) -> Bool {
		renderConfig.getGroupOptions(groupKey)["sectionTitle"] as? String != ""
	}

	func getSectionTitle(_ groupKey: String) -> String? {
		let title = renderConfig.getGroupOptions(groupKey)["sectionTitle"]

		if let title = title as? String {
			return title
		} else if let expr = title as? Expression {
			let args = _args(groupKey: groupKey, name: groupKey, item: item)
			do {
				return try expr.execForReturnType(args: args)
			} catch {
				debugHistory.error("\(error)")
				return nil
			}
		}

		return nil
	}

	func isDescriptionForGroup(_ groupKey: String) -> Bool {
		if !renderConfig.hasGroup(groupKey) { return false }
		return renderConfig.getGroupOptions(groupKey)["foreach"] as? Bool == false
	}

    func getHeader(_ isArray: Bool, _ listHasItems: Bool, _ groupKey:String) -> some View {
		let editMode = context.currentSession?.isEditMode ?? false
		let className = item.objectSchema[groupKey]?.objectClassName ?? ""
        let readOnly = layoutSection.get("readOnly", Bool.self) ?? false

		let action = isArray && editMode && !readOnly
			? ActionOpenViewByName(context,
								   arguments: [
								   	"name": "choose-item-by-query",
								   	"viewArguments": try? ViewArguments.fromDict([
								   		"query": className,
								   		"type": className,
								   		"subject": item,
								   		"property": groupKey,
								   		"title": "Choose a \(className)",
								   		"dataItem": item,
								   	]),
								   ],
								   values: [
								   	"icon": "plus",
								   	"renderAs": RenderType.popup,
								   ])
			: nil

		return Group {
			if isArray && !listHasItems && !editMode {
				EmptyView()
			} else if renderConfig.hasGroup(groupKey) {
				if self.hasSectionTitle(groupKey) {
					self.constructSectionHeader(
						title: self.getSectionTitle(groupKey) ?? groupKey,
						action: action
					)
				} else {
					EmptyView()
				}
			} else {
				self.constructSectionHeader(
					title: groupKey,
					action: action
				)
			}
		}
	}

	func constructSectionHeader(title: String, action: Action? = nil) -> some View {
		HStack(alignment: .bottom) {
			Text(title.camelCaseToWords().uppercased())
				.generalEditorHeader()

			if action != nil {
				Spacer()
				// NOTE: Allowed force unwrapping
				ActionButton(action: action!)
					.foregroundColor(Color(hex: "#777"))
					.font(.system(size: 18, weight: .semibold))
					.padding(.bottom, 10)
			}
		}.padding(.trailing, 20)
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

		return VStack(spacing: 0) {
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
						defaultRow(self.item.getString(self.prop))
					} else if propType == .object {
						if self.item[self.prop] is Item {
							MemriButton(context: self._context,
										item: self.item[self.prop] as! Item)
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

	func stringRow() -> some View {
		let binding = Binding<String>(
			get: { self.item.getString(self.prop) },
			set: {
				self.item.set(self.prop, $0)
			}
		)

		return MemriTextField(value: binding)
			.onEditingBegan {
				self.context.currentSession?.isEditMode = true
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
				self.context.currentSession?.isEditMode = true
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
				self.context.currentSession?.isEditMode = true
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
