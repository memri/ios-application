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

	var groups: [String: [String]] {
		cascadeDict("groups", forceArray: true)
	}

	var readOnly: [String] { cascadeList("readOnly") }
	var excluded: [String] { cascadeList("excluded") }
	var sequence: [String] { cascadeList("sequence", merge: false) }

	public func allGroupValues() -> [String] {
		groups.values.flatMap { Array($0) }
	}
}

struct GeneralEditorView: View {
	@EnvironmentObject var context: MemriContext

	var name: String = "generalEditor"

	var renderConfig: CascadingGeneralEditorConfig? {
		context.cascadingView?.renderConfig as? CascadingGeneralEditorConfig
	}

	var body: some View {
		var item: Item
		if let dataItem = context.cascadingView?.resultSet.singletonItem {
			item = dataItem
		} else {
			debugHistory.warn("Could not load item from result set, creating empty item")
			item = Item()
		}

		// TODO: Error Handling
		let renderConfig = self.renderConfig
		let groups = getGroups(item) ?? [:]
		let sortedKeys = getSortedKeys(groups)

		return ScrollView {
			VStack(alignment: .leading, spacing: 0) {
				if renderConfig == nil {
					Text("Unable to render this view")
				} else if groups.count > 0 {
					ForEach(sortedKeys, id: \.self) { groupKey in
						GeneralEditorSection(
							item: item,
							renderConfig: renderConfig!,
							groupKey: groupKey,
							groups: groups
						)
					}
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}

	func getGroups(_ item: Item) -> [String: [String]]? {
		let renderConfig = self.renderConfig
		let groups = renderConfig?.groups ?? [:]
		var filteredGroups: [String: [String]] = [:]
		let objectSchema = item.objectSchema
		var alreadyUsed: [String] = []

		for (key, value) in groups {
			if value.first != key { alreadyUsed = alreadyUsed + value }
		}

		(Array(groups.keys) + objectSchema.properties.map { $0.name }).filter {
			return (groups[$0] != nil || objectSchema[$0]?.isArray ?? false)
				&& !(renderConfig?.excluded.contains($0) ?? false)
				&& !alreadyUsed.contains($0)
		}.forEach {
			filteredGroups[$0] = groups[$0] ?? [$0]
		}

		return filteredGroups.count > 0 ? filteredGroups : nil
	}

	func getSortedKeys(_ groups: [String: [String]]) -> [String] {
		var keys = renderConfig?.sequence ?? []
		for k in groups.keys {
			if !keys.contains(k) {
				keys.append(k)
			}
		}

		keys = keys.filter { !(self.renderConfig?.excluded.contains($0) ?? true) }

		if !keys.contains("other") {
			keys.append("other")
		}

		return keys
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
	var groupKey: String
	var groups: [String: [String]]

	var body: some View {
		let renderConfig = self.renderConfig
		let editMode = self.context.currentSession?.isEditMode ?? false
		let properties = groupKey == "other"
			? self.getProperties(item)
			: self.groups[self.groupKey] ?? []
		let groupIsList = self.groups[self.groupKey] == nil && item.objectSchema[groupKey] == nil
		let showDividers = self.hasSectionTitle(groupKey)
		let listHasItems = groupIsList && item.edge(groupKey) != nil

		return Section(header: self.getHeader(groupIsList, listHasItems)) {
			if groupIsList && !listHasItems && !editMode {
				EmptyView()
			}
			// Render using a view specified renderer
			else if renderConfig.hasGroup(groupKey) {
				if showDividers { Divider() }

				if self.isDescriptionForGroup(groupKey) {
					renderConfig.render(
						item: item,
						group: groupKey,
						arguments: self._args(groupKey: self.groupKey,
											  name: groupKey,
											  item: self.item)
					)
				} else {
					if groupIsList {
						item.edges(groupKey).map { edges in
							ForEach<Results<Edge>, Edge, UIElementView>(edges, id: \.self) { edge in
								let otherItem = edge.item()
								return self.renderConfig.render(
									item: otherItem,
									group: self.groupKey,
									arguments: self._args(groupKey: self.groupKey,
														  value: otherItem,
														  item: otherItem,
														  edge: edge)
								)
							}
						}
					} else {
						// TODO: Error handling
						ForEach(groups[groupKey] ?? [], id: \.self) { groupElement in
							self.renderConfig.render(
								item: self.item,
								group: self.groupKey,
								arguments: self._args(groupKey: self.groupKey,
													  name: groupElement,
													  item: self.item)
							)
						}
					}
				}

				if showDividers { Divider() }
			}
			// Render lists with their default renderer
			else if groupIsList {
				Divider()
				ScrollView {
					VStack(alignment: .leading, spacing: 0) {
						ForEach<Results<Edge>, Edge, ItemCell>(item.edges(groupKey)!, id: \.self) { edge in
							let item = edge.item()
							return ItemCell(
								item: item,
								rendererNames: ["generalEditor"],
								arguments: self._args(groupKey: self.groupKey,
													  name: self.groupKey,
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
				ForEach(properties, id: \.self) { prop in

					// TODO: Refactor: rows that are single links to an item

					DefaultGeneralEditorRow(
						context: self._context,
						item: self.item,
						prop: prop,
						readOnly: !editMode || renderConfig.readOnly.contains(prop),
						isLast: properties.last == prop,
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

	func getProperties(_ item: Item) -> [String] {
		item.objectSchema.properties.filter {
			!self.renderConfig.excluded.contains($0.name)
				&& !self.renderConfig.allGroupValues().contains($0.name)
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
			let args = _args(groupKey: self.groupKey, name: self.groupKey, item: item)
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

	//    func getType(_ groupKey:String) -> String {
	//        renderConfig.renderDescription?[groupKey]?.type ?? ""
	//    }

	func getHeader(_ isArray: Bool, _ listHasItems: Bool) -> some View {
		let editMode = context.currentSession?.isEditMode ?? false
		let className = item.objectSchema[groupKey]?.objectClassName ?? ""
		let readOnly = renderConfig.readOnly.contains(groupKey)

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
					title: (groupKey == "other" && groups.count == 0) ? "all" : groupKey,
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
