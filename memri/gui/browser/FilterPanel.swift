//
//  FIlterpannel.swift
//  memri
//
//  Created by Koen van der Veen on 25/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import ASCollectionView
import SwiftUI

struct BrowseSetting: Identifiable {
	var id = UUID()
	var name: String
	var selected: Bool
	var color: Color { selected ? Color(hex: "#6aa84f") : Color(hex: "#434343") }
	var fontWeight: Font.Weight? { selected ? .semibold : .regular }
}

struct FilterPanel: View {
	@EnvironmentObject var context: MemriContext

	@State var browseSettings = [BrowseSetting(name: "Default", selected: true),
								 BrowseSetting(name: "Year-Month-Day view", selected: false)]

	private func allOtherFields() -> [String] {
		var list: [String] = []

		if let item = context.cascadingView?.resultSet.items.first {
			var excludeList = context.cascadingView?.sortFields
			excludeList?.append(context.cascadingView?.datasource.sortProperty ?? "")
			excludeList?.append("uid")
			excludeList?.append("deleted")

			let properties = item.objectSchema.properties
			for prop in properties {
				if !(excludeList?.contains(prop.name) ?? false), prop.type != .object, prop.type != .linkingObjects {
					list.append(prop.name)
				}
			}
		}

		return list
	}

	private func toggleAscending() {
		realmWriteIfAvailable(context.realm) {
			self.context.currentSession?.currentView?.datasource?.sortAscending.value
				= !(self.context.cascadingView?.datasource.sortAscending ?? true)
		}
		context.scheduleCascadingViewUpdate()
	}

	private func changeOrderProperty(_ fieldName: String) {
		realmWriteIfAvailable(context.realm) {
			self.context.currentSession?.currentView?.datasource?.sortProperty = fieldName
		}
		context.scheduleCascadingViewUpdate()
	}

	private func rendererCategories() -> [(String, FilterPanelRendererButton)] {
		context.renderers.tuples
			.map { ($0.0, $0.1(context)) }
			.filter { (key, renderer) -> Bool in
				!key.contains(".") && renderer.canDisplayResults(self.context.items)
			}
			.sorted(by: { $0.1.order < $1.1.order })
	}

	private func renderersAvailable() -> [(String, FilterPanelRendererButton)] {
		if let currentCategory = context.cascadingView?.activeRenderer.split(separator: ".").first {
			return context.renderers.all
				.map { (arg0) -> (String, FilterPanelRendererButton) in
					let (key, value) = arg0
					return (key, value(context))
				}
				.filter { (_, renderer) -> Bool in
					renderer.rendererName.split(separator: ".").first == currentCategory
				}
				.sorted(by: { $0.1.order < $1.1.order })
		}
		return []
	}

	private func isActive(_ renderer: FilterPanelRendererButton) -> Bool {
		context.cascadingView?.activeRenderer.split(separator: ".").first ?? "" == renderer.rendererName
	}

	var body: some View {
		let context = self.context
		let cascadingView = self.context.cascadingView

		return
			HStack(alignment: .top, spacing: 0) {
				VStack(alignment: .leading, spacing: 0) {
					HStack(alignment: .top, spacing: 3) {
						ForEach(rendererCategories(), id: \.0) { _, renderer in

							Button(action: { context.executeAction(renderer) }) {
								Image(systemName: renderer.getString("icon"))
									.fixedSize()
									.padding(.horizontal, 5)
									.padding(.vertical, 5)
									.frame(width: 40, height: 40, alignment: .center)
									.foregroundColor(self.isActive(renderer)
										? renderer.getColor("activeColor")
										: renderer.getColor("inactiveColor"))
									.background(self.isActive(renderer)
										? renderer.getColor("activeBackgroundColor")
										: renderer.getColor("inactiveBackgroundColor"))
							}
						}
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.leading, 12)
					.background(Color.white)
					.padding(.top, 1)

					ASTableView(section:
						ASSection(id: 0, data: renderersAvailable(), dataID: \.0) { (item: (key: String, renderer: FilterPanelRendererButton), _) in
							Button(action: { context.executeAction(item.renderer) }) {
								Group {
									if cascadingView?.activeRenderer == item.renderer.rendererName {
										Text(LocalizedStringKey(item.renderer.getString("title")))
											.foregroundColor(Color(hex: "#6aa84f"))
											.fontWeight(.semibold)
											.font(.system(size: 16))
									} else {
										Text(LocalizedStringKey(item.renderer.getString("title")))
											.foregroundColor(Color(hex: "#434343"))
											.fontWeight(.regular)
											.font(.system(size: 16))
									}
								}
								.padding(.horizontal)
								.padding(.vertical, 6)
							}
						}
					)
				}
				.padding(.bottom, 1)

				ASTableView(section:
					ASSection(id: 0, container: { content, _ in
						content
							.padding(.horizontal)
							.padding(.vertical, 6)
                    }) {
						cascadingView?.datasource.sortProperty.map { currentSortProperty in
							Button(action: { self.toggleAscending() }) {
								HStack {
									Text(currentSortProperty)
										.foregroundColor(Color(hex: "#6aa84f"))
										.font(.system(size: 16, weight: .semibold, design: .default))
										.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
									Spacer()
									Image(systemName: cascadingView?.datasource.sortAscending == false
										? "arrow.down"
										: "arrow.up")
										.resizable()
										.aspectRatio(contentMode: .fit)
										.foregroundColor(Color(hex: "#6aa84f"))
										.frame(minWidth: 10, maxWidth: 10)
								}
							}
						}
						cascadingView?.sortFields.filter {
							cascadingView?.datasource.sortProperty != $0
						}.map { fieldName in
							Button(action: { self.changeOrderProperty(fieldName) }) {
								Text(fieldName)
									.foregroundColor(Color(hex: "#434343"))
									.font(.system(size: 16, weight: .regular, design: .default))
									.frame(maxWidth: .infinity, alignment: .leading)
							}
						}

						allOtherFields().map { fieldName in
							Button(action: { self.changeOrderProperty(fieldName) }) {
								Text(fieldName)
									.foregroundColor(Color(hex: "#434343"))
									.font(.system(size: 16, weight: .regular, design: .default))
									.frame(maxWidth: .infinity, alignment: .leading)
							}
						}
					}
					.sectionHeader {
						Text("Sort on:")
							.padding(4)
							.frame(maxWidth: .infinity, alignment: .leading)
							.font(.system(size: 14, weight: .semibold))
							.foregroundColor(Color(hex: "#434343"))
							.background(Color(.secondarySystemBackground))
					}
				)
				.background(Color.white)
				.padding(.vertical, 1)
				.padding(.leading, 1)
			}
			.frame(maxWidth: .infinity, alignment: .topLeading)
			.frame(height: 240)
			.background(Color(hex: "#eee"))
	}
}

struct FilterPanel_Previews: PreviewProvider {
	static var previews: some View {
		FilterPanel().environmentObject(try! RootContext(name: "", key: "").mockBoot())
	}
}
