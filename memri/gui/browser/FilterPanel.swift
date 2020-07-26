//
// FilterPanel.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import RealmSwift
import SwiftUI

struct FilterPanel: View {
    @EnvironmentObject var context: MemriContext

    var body: some View {
        let context = self.context
        let cascadableView = self.context.currentView
        let segmentedRendererCategories = getRendererCategories().segments(ofSize: 5).indexed()

        return
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(spacing: 3) {
                        ForEach(segmentedRendererCategories, id: \.index) { categories in
                            HStack(alignment: .top, spacing: 3) {
                                ForEach(categories.element, id: \.0) { _, renderer in
                                    Button(action: { context.executeAction(renderer) }) {
                                        Image(systemName: renderer.getString("icon"))
                                            .fixedSize()
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 5)
                                            .frame(width: 35, height: 40, alignment: .center)
                                            .foregroundColor(self.isActive(renderer)
                                                ? renderer.getColor("activeColor")
                                                : renderer.getColor("inactiveColor"))
                                            .background(self.isActive(renderer)
                                                ? renderer.getColor("activeBackgroundColor")
                                                : renderer.getColor("inactiveBackgroundColor"))
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                    .background(Color.white)
                    .padding(.top, 1)

                    ASTableView(section:
                        ASSection(
                            id: 0,
                            data: getRenderersAvailable(forCategory: currentRendererCategory),
                            dataID: \.0
                        ) { (item: (key: String, renderer: FilterPanelRendererButton), _) in
                            Button(action: { context.executeAction(item.renderer) }) {
                                Group {
                                    if cascadableView?.activeRenderer == item.renderer
                                        .rendererName {
                                        Text(LocalizedStringKey(item.renderer.getString("title")))
                                            .foregroundColor(Color(hex: "#6aa84f"))
                                            .fontWeight(.semibold)
                                            .font(.system(size: 16))
                                    }
                                    else {
                                        Text(LocalizedStringKey(item.renderer.getString("title")))
                                            .foregroundColor(Color(hex: "#434343"))
                                            .fontWeight(.regular)
                                            .font(.system(size: 16))
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                            }
                        })
                }
                .padding(.bottom, 1)

                ASTableView(section:
                    ASSection(id: 0, container: { content, _ in
                        content
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                    }) {
                        cascadableView?.datasource.sortProperty.map { currentSortProperty in
                            Button(action: { self.toggleAscending() }) {
                                HStack {
                                    Text(currentSortProperty)
                                        .foregroundColor(Color(hex: "#6aa84f"))
                                        .font(.system(size: 16, weight: .semibold,
                                                      design: .default))
                                        .frame(
                                            minWidth: 0,
                                            maxWidth: .infinity,
                                            alignment: .leading
                                        )
                                    Spacer()
                                    Image(systemName: cascadableView?.datasource
                                        .sortAscending == false
                                        ? "arrow.down"
                                        : "arrow.up")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(Color(hex: "#6aa84f"))
                                        .frame(minWidth: 10, maxWidth: 10)
                                }
                            }
                        }
                        cascadableView?.sortFields.filter {
                            cascadableView?.datasource.sortProperty != $0
                        }.map { fieldName in
                            Button(action: { self.changeOrderProperty(fieldName) }) {
                                Text(fieldName)
                                    .foregroundColor(Color(hex: "#434343"))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        getRelevantFields().map { fieldName in
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
                    })
                    .background(Color.white)
                    .padding(.vertical, 1)
                    .padding(.leading, 1)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: 240)
            .background(Color(hex: "#eee"))
    }
}

private extension FilterPanel {
    func getRendererCategories() -> [(String, FilterPanelRendererButton)] {
        context.renderers.tuples
            .map { ($0.0, $0.1(context)) }
            .filter { (key, renderer) -> Bool in
                !key.contains(".") && renderer.canDisplayResults(self.context.items)
            }
            .sorted(by: { $0.1.order < $1.1.order })
    }

    var currentRendererCategory: String? {
        context.currentView?.activeRenderer.split(separator: ".").first.map(String.init)
    }

    func getRenderersAvailable(forCategory category: String?)
        -> [(String, FilterPanelRendererButton)] {
        guard let category = category else { return [] }
        return context.renderers.all
            .map { (arg0) -> (String, FilterPanelRendererButton) in
                let (key, value) = arg0
                return (key, value(context))
            }
            .filter { (_, renderer) -> Bool in
                renderer.rendererName.split(separator: ".").first.map(String.init) == category
            }
            .sorted(by: { $0.1.order < $1.1.order })
    }

    func getRelevantFields(forType type: PropertyType? = nil) -> [String] {
        guard let item = context.currentView?.resultSet.items.first else { return [] }

        var excludeList = context.currentView?.sortFields ?? []
        excludeList.append(context.currentView?.datasource.sortProperty ?? "")
        excludeList.append(contentsOf: ["uid", "deleted", "externalId"])

        let properties = item.objectSchema.properties

        return properties.compactMap { prop -> String? in
            if !excludeList.contains(prop.name), !prop.name.hasPrefix("_"), prop.type != .object,
                prop.type != .linkingObjects {
                return prop.name
            }
            else {
                return nil
            }
        }
    }

    func isActive(_ renderer: FilterPanelRendererButton) -> Bool {
        context.currentView?.activeRenderer.split(separator: ".").first ?? "" == renderer
            .rendererName
    }
}

private extension FilterPanel {
    func toggleAscending() {
        let ds = context.currentView?.datasource
        ds?.sortAscending = !(ds?.sortAscending ?? true)
        context.scheduleCascadableViewUpdate()
    }

    func changeOrderProperty(_ fieldName: String) {
        context.currentView?.datasource.sortProperty = fieldName
        context.scheduleCascadableViewUpdate()
    }
}

struct FilterPanel_Previews: PreviewProvider {
    static var previews: some View {
        FilterPanel().environmentObject(try! RootContext(name: "").mockBoot())
    }
}
