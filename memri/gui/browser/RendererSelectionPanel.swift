//
//  RendererSelectionPanel.swift
//  memri
//
//  Created by Toby Brennan on 28/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import ASCollectionView

struct RendererSelectionPanel: View {
	@EnvironmentObject var context: MemriContext
    var body: some View {
        ASTableView(section:
            ASSection(
                id: 0,
                data: Renderers.rendererTypes.keys.sorted(),
                dataID: \.self
            ) { (rendererName, _) in
                Button(action: { self.activateRenderer(name: rendererName) }) {
                    Text(rendererName.titleCase())
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
        })
    }
    
    func activateRenderer(name: String)
    {
        context.currentView?.activeRenderer = name
    }
}
//
//private extension RendererSelectionPanel {
//	func getRendererCategories() -> [(String, FilterPanelRendererButton)] {
//        []
////		context.renderers.tuples
////			.map { ($0.0, $0.1(context)) }
////			.filter { (key, renderer) -> Bool in
////				!key.contains(".") && renderer.canDisplayResults(self.context.items)
////			}
////			.sorted(by: { $0.1.order < $1.1.order })
//	}
//
//	var currentRendererCategory: String? {
//		context.currentView?.activeRenderer.split(separator: ".").first.map(String.init)
//	}
//
//	func getRenderersAvailable(forCategory category: String?)
//	-> [(String, FilterPanelRendererButton)] {
//		guard let category = category else { return [] }
//        return []
////		return context.renderers.all
////			.map { (arg0) -> (String, FilterPanelRendererButton) in
////				let (key, value) = arg0
////				return (key, value(context))
////			}
////			.filter { (_, renderer) -> Bool in
////				renderer.rendererName.split(separator: ".").first.map(String.init) == category
////			}
////			.sorted(by: { $0.1.order < $1.1.order })
//	}
//
//	func isActive(_ renderer: FilterPanelRendererButton) -> Bool {
//		context.currentView?.activeRenderer.split(separator: ".").first ?? "" == renderer
//			.rendererName
//	}
//}


//
//
//func body(in geometry: GeometryProxy) -> some View {
//    let rowSize = Int(geometry.size.width / 38) // Figure out how many can fit in a row
//    let segmentedRendererCategories = getRendererCategories().segments(ofSize: rowSize).indexed()
//
//    return VStack(alignment: .leading, spacing: 0) {
//        VStack(spacing: 3) {
//            ForEach(segmentedRendererCategories, id: \.index) { categories in
//                HStack(alignment: .top, spacing: 3) {
//                    ForEach(categories.element, id: \.0) { _, renderer in
//                        Button(action: { self.context.executeAction(renderer) }) {
//                            Image(systemName: renderer.getString("icon"))
//                                .fixedSize()
//                                .padding(.horizontal, 5)
//                                .padding(.vertical, 5)
//                                .frame(width: 35, height: 40, alignment: .center)
//                                .foregroundColor(self.isActive(renderer)
//                                    ? renderer.getColor("activeColor")
//                                    : renderer.getColor("inactiveColor"))
//                                .background(self.isActive(renderer)
//                                    ? renderer.getColor("activeBackgroundColor")
//                                    : renderer.getColor("inactiveBackgroundColor"))
//                        }
//                    }
//                }
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(.leading, 12)
//        .background(Color.white)
//        .padding(.top, 1)
//
//        ASTableView(section:
//            ASSection(
//                id: 0,
//                data: getRenderersAvailable(forCategory: currentRendererCategory),
//                dataID: \.0
//            ) { (item: (key: String, renderer: FilterPanelRendererButton), _) in
//                Button(action: { self.context.executeAction(item.renderer) }) {
//                    Group {
//                        if self.context.currentView?.activeRenderer == item.renderer
//                            .rendererName {
//                            Text(LocalizedStringKey(item.renderer.getString("title")))
//                                .foregroundColor(Color(hex: "#6aa84f"))
//                                .fontWeight(.semibold)
//                                .font(.system(size: 16))
//                        }
//                        else {
//                            Text(LocalizedStringKey(item.renderer.getString("title")))
//                                .foregroundColor(Color(hex: "#434343"))
//                                .fontWeight(.regular)
//                                .font(.system(size: 16))
//                        }
//                    }
//                    .padding(.horizontal)
//                    .padding(.vertical, 6)
//                }
//        })
//    }
//}
