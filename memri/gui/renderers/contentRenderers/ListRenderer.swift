//
// ListRendererView.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import Combine
import Foundation
import SwiftUI


class ListRendererConfig: CascadingRendererConfig {
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
    
    override var defaultEdgeInset: UIEdgeInsets { UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15) }
    override var defaultSpacing: CGSize { CGSize(width: 0, height: 10) }
}


class ListRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "list", icon: "line.horizontal.3", makeController: ListRendererController.init, makeConfig: ListRendererController.makeConfig)
    
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? ListRendererConfig) ?? ListRendererConfig()
    }
    
    let context: MemriContext
    let config: ListRendererConfig
    
    func makeView() -> AnyView {
        ListRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        ListRendererConfig(head, tail, host)
    }
    
    func view(for item: Item) -> some View {
        config.render(item: item)
            .environmentObject(context)
    }
    
    var selectedIndices: Binding<Set<Int>> {
        Binding<Set<Int>>(
            get: { [] },
            set: {
                self.context.setSelection($0.compactMap { self.context.items[safe: $0] })
        }
        )
    }
    
    var hasItems: Bool {
        !context.items.isEmpty
    }
    
    var emptyText: String? {
        context.currentView?.emptyResultText
    }
}

struct ListRendererView: View {
    @ObservedObject var controller: ListRendererController

    var body: some View {
        return VStack {
            if controller.hasItems {
                ASTableView(editMode: controller.context.currentSession?.editMode ?? false, section:
                    ASSection(id: 0,
                              data: controller.context.items,
                              dataID: \.uid.value,
                              selectedItems: controller.selectedIndices,
                              onSwipeToDelete: { _, item in
                                self.controller.context.executeAction(ActionDelete(self.controller.context), with: item)
                                  return true
							  },
                              contextMenuProvider: contextMenuProvider
                    ) { dataItem, cellContext in
                        self.controller.view(for: dataItem)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(EdgeInsets(top: cellContext.isFirstInSection ? 0 : self.controller.config.spacing.height / 2,
												leading: self.controller.config.edgeInset.left,
                                                bottom: cellContext.isLastInSection ? 0 : self.controller.config.spacing.height / 2,
												trailing: self.controller.config.edgeInset.right))
                    }
                    .onSelectSingle { index in
                        if let press = self.controller.config.press {
                            self.controller.context.executeAction(press, with: self.controller.context.items[safe: index])
                        }
                    })
                    .alwaysBounce()
					.contentInsets(.init(top: controller.config.edgeInset.top, left: 0, bottom: controller.config.edgeInset.bottom, right: 0))
                    .background(controller.config.backgroundColor?.color ?? Color(.systemBackground))
            
            }
            else {
                controller.emptyText.map { text in
                    Text(text)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .opacity(0.7)
                }
                .padding(30)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
        }
            .id(controller.config.ui_UUID) // Fix swiftUI wrongly animating between different lists
    }
    
    func contextMenuProvider(index: Int, item: Item) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak controller] (suggested) -> UIMenu? in
            let children: [UIMenuElement] = controller?.config.contextMenuActions.map { [weak controller] action in
                UIAction(title: action.getString("title"),
                         image: nil) { [weak controller] (_) in
                            controller?.context.executeAction(action, with: item)
                }
            } ?? []
            return UIMenu(title: "", children: children)
        }
    }
}
