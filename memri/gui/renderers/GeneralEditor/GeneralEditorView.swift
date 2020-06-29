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
		context.cascadingView.renderConfig as? CascadingGeneralEditorConfig
	}

	var body: some View {
		var item: DataItem
		if let dataItem = context.cascadingView.resultSet.singletonItem {
			item = dataItem
		} else {
			print("Cannot load DataItem, creating empty")
			item = DataItem()
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

	func getGroups(_ item: DataItem) -> [String: [String]]? {
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
		let context = RootContext(name: "", key: "").mockBoot()

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
