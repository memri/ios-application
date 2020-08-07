//
// ListRendererView.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import Combine
import Foundation
import SwiftUI

let registerListRenderer = {
    Renderers.register(
        name: "list",
        title: "Default",
        order: 0,
        icon: "line.horizontal.3",
        view: AnyView(ListRendererView()),
        renderConfigType: CascadingListConfig.self,
        canDisplayResults: { _ -> Bool in true }
    )

    Renderers.register(
        name: "list.alphabet",
        title: "Alphabet",
        order: 10,
        view: AnyView(ListRendererView()),
        renderConfigType: CascadingListConfig.self,
        canDisplayResults: { _ -> Bool in true }
    )
}

class CascadingListConfig: CascadingRenderConfig, CascadingRendererDefaults {
    var type: String? = "list"

    var longPress: Action? {
        get { cascadeProperty("longPress") }
        set(value) { setState("longPress", value) }
    }

    var press: Action? {
        get { cascadeProperty("press") }
        set(value) { setState("press", value) }
    }

    var slideLeftActions: [Action] {
        get { cascadeList("slideLeftActions") }
        set(value) { setState("slideLeftActions", value) }
    }

    var slideRightActions: [Action] {
        get { cascadeList("slideRightActions") }
        set(value) { setState("slideRightActions", value) }
    }

    public func setDefaultValues(_ element: UIElement) {
        if element.propertyResolver.properties["padding"] == nil {
            element.propertyResolver
                .properties["padding"] = [CGFloat(10), CGFloat(10), CGFloat(10), CGFloat(20)]
        }
    }
}

struct ListRendererView: View {
    @EnvironmentObject var context: MemriContext
    var selectedIndices: Binding<Set<Int>> {
        Binding<Set<Int>>(
            get: { [] },
            set: {
                self.context.setSelection($0.compactMap { self.context.items[safe: $0] })
            }
        )
    }

    let name = "list"

    var renderConfig: CascadingListConfig {
        context.currentView?.renderConfig as? CascadingListConfig ?? CascadingListConfig()
    }

    var body: some View {
        let context = self.context

        return VStack {
            if context.currentView?.resultSet.count == 0 {
                HStack(alignment: .top) {
                    Spacer()
                    Text(context.currentView?.emptyResultText ?? "")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .opacity(0.7)
                    Spacer()
                }
                .padding(.all, 30)
                .padding(.top, 40)
                Spacer()
            }
            else {
                ASTableView(editMode: context.currentSession?.editMode ?? false, section:
                    ASSection(id: 0,
                              data: context.items,
                              dataID: \.uid.value,
                              selectedItems: selectedIndices,
                              onSwipeToDelete: { _, item in
                                  context.executeAction(ActionDelete(context), with: item)
                                  return true
							  },
                              contextMenuProvider: contextMenuProvider
                    ) { dataItem, cellContext in
                        self.renderConfig.render(item: dataItem)
                            .frame(maxWidth: .infinity, alignment: .leading)
							.padding(EdgeInsets(top: cellContext.isFirstInSection ? 0 : self.renderConfig.spacing.height / 2,
												leading: self.renderConfig.edgeInset.left,
												bottom: cellContext.isLastInSection ? 0 : self.renderConfig.spacing.height / 2,
												trailing: self.renderConfig.edgeInset.right))
                            .environmentObject(context)
                    }
                    .onSelectSingle { index in
                        if let press = self.renderConfig.press {
                            context.executeAction(press, with: context.items[safe: index])
                        }
                    })
                    .alwaysBounce()
					.contentInsets(.init(top: renderConfig.edgeInset.top, left: 0, bottom: renderConfig.edgeInset.bottom, right: 0))
                    .background(renderConfig.backgroundColor?.color ?? Color(.systemBackground))
            }
        }
        .id(renderConfig.ui_UUID) // Fix swiftUI wrongly animating between different lists
    }
    
    func contextMenuProvider(index: Int, item: Item) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak context] (suggested) -> UIMenu? in
            let children: [UIMenuElement] = self.renderConfig.contextMenuActions.map { [weak context] action in
                UIAction(title: action.getString("title"),
                         image: nil) { [weak context] (_) in
                            context?.executeAction(action, with: item)
                }
            }
            return UIMenu(title: "", children: children)
        }
    }
}

struct ListRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ListRendererView().environmentObject(try! RootContext(name: "").mockBoot())
    }
}
