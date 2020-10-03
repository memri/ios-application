//
// MessageRenderer.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import SwiftUI

class MessageRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "messages", icon: "message", makeController: MessageRendererController.init, makeConfig: MessageRendererController.makeConfig)
    
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? MessageRendererConfig) ?? MessageRendererConfig()
    }
    
    let context: MemriContext
    let config: MessageRendererConfig
    
    func makeView() -> AnyView {
        MessageRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        MessageRendererConfig(head, tail, host)
    }
    
    
    func view(for item: Item) -> some View {
        config.render(item: item)
            .environmentObject(context)
    }
    
    func resolveExpression<T>(
        _ expression: Expression?,
        toType _: T.Type = T.self,
        forItem dataItem: Item
    ) -> T? {
        let args = ViewArguments(context.currentView?.viewArguments, dataItem)
        return try? expression?.execForReturnType(T.self, args: args)
    }
    
    var editMode: Bool {
        context.editMode
    }
    
    func onSelectSingle(_ index: Int) {
        guard let selectedItem = self.context.items[safe: index],
            let press = self.config.press
            else { return }
        self.context.executeAction(press, with: selectedItem)
    }
    
    @Published
    var composedMessage: String?
    
    func onPressSend() {
        #warning("@Ruben: we will need to decide how `sending` a message is handled")
        print(composedMessage ?? "Empty message")
        // Handle message here
        
        // Clear composer state
        composedMessage = nil
    }
    
    
    var canSend: Bool {
        !(composedMessage?.isOnlyWhitespace ?? true)
    }
}

class MessageRendererConfig: CascadingRendererConfig {
    var press: Action? { cascadeProperty("press") }
	

    var isOutgoing: Expression? { cascadeProperty("isOutgoing", type: Expression.self) }

}

struct MessageRendererView: View {
    @ObservedObject var controller: MessageRendererController



    @State var scrollPosition: ASTableViewScrollPosition? = .bottom
    

    var section: ASSection<Int> {
        ASSection<Int>(id: 0, data: controller.context.items, selectionMode: .selectMultiple(controller.context.selectedIndicesBinding) ) { item, cellContext in
            //let previousItem = context.items[safe: cellContext.index - 1])
            return self.controller.view(for: item)//, ViewArguments(["previousItem": previousItem]))
                .padding(EdgeInsets(top: cellContext.isFirstInSection ? 0 : self.controller.config.spacing.height / 2,
                                    leading: self.controller.config.edgeInset.left,
									bottom: cellContext.isLastInSection ? 0 : self.controller.config.spacing.height / 2,
									trailing: self.controller.config.edgeInset.right))
        }
    }

    
    var body: some View {
        VStack(spacing: 0) {
            ASTableView(editMode: controller.editMode, section: section)
                .separatorsEnabled(false)
                .scrollPositionSetter($scrollPosition)
                .alwaysBounce()
                .contentInsets(.init(top: controller.config.edgeInset.top, left: 0, bottom: controller.config.edgeInset.bottom, right: 0))
                .edgesIgnoringSafeArea(.all)
                .background(controller.config.backgroundColor?.color ?? Color(.systemBackground))
            Divider()
            messageComposer
        }
        .modifier(KeyboardPaddingModifier())
    }
    
    @State private var isEditingComposedMessage: Bool = false

    var messageComposer: some View {
        HStack(spacing: 6) {
            MemriFittedTextEditor(contentBinding: $controller.composedMessage, placeholder: "Type a message...", backgroundColor: CVUColor.system(.systemBackground), isEditing: $isEditingComposedMessage)
                
            Button(action: onPressSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(controller.canSend ? .blue : Color(.systemFill))
                    .font(.system(size: 30))
            }
            .disabled(!controller.canSend)
        }
        .padding(.vertical, 5)
        .padding(.leading, min(max(self.controller.config.edgeInset.left, 5), 15)) // Follow user-defined insets where within a reasonable range
        .padding(.trailing, min(max(self.controller.config.edgeInset.right, 5), 15)) // Follow user-defined insets where within a reasonable range
        .background(Color(.secondarySystemBackground))
    }
    
    func onPressSend() {
        controller.onPressSend()
        isEditingComposedMessage = false
    }
}
