//
// MessageRenderer.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import SwiftUI

let registerMessageRenderer = {
    Renderers.register(
        name: "messages",
        title: "Messages",
        order: 0,
        icon: "message",
        view: AnyView(MessageRenderer()),
        renderConfigType: CascadingMessageRendererConfig.self,
        canDisplayResults: { items -> Bool in
            items.first?.genericType == "Message" ||
                items.first?.genericType == "Note"
        }
    )
}

class CascadingMessageRendererConfig: CascadingRenderConfig {
    var type: String? = "messages"

    var press: Action? { cascadeProperty("press") }
	

    var isOutgoing: Expression? { cascadeProperty("isOutgoing", type: Expression.self) }

}

struct MessageRenderer: View {
    @EnvironmentObject var context: MemriContext

    var renderConfig: CascadingMessageRendererConfig {
        context.currentView?.renderConfig as? CascadingMessageRendererConfig
            ?? CascadingMessageRendererConfig()
    }

    func resolveExpression<T>(
        _ expression: Expression?,
        toType _: T.Type = T.self,
        forItem dataItem: Item
    ) -> T? {
        let args = ViewArguments(context.currentView?.viewArguments, dataItem)
        return try? expression?.execForReturnType(T.self, args: args)
    }

    var selectedItems: Binding<Set<Int>> {
        Binding<Set<Int>>(
            get: { [] },
            set: {
                self.context.setSelection($0.compactMap { self.context.items[safe: $0] })
            }
        )
    }

    @State var scrollPosition: ASTableViewScrollPosition? = .bottom
    var editMode: Bool {
        context.currentSession?.editMode ?? false
    }

    var section: ASSection<Int> {
        ASSection<Int>(id: 0, data: context.items, selectedItems: selectedItems) { item, cellContext in
            self.renderConfig.render(item: item)
                .environmentObject(self.context)
				.padding(EdgeInsets(top: cellContext.isFirstInSection ? 0 : self.renderConfig.spacing.height / 2,
									leading: self.renderConfig.edgeInset.left,
									bottom: cellContext.isLastInSection ? 0 : self.renderConfig.spacing.height / 2,
									trailing: self.renderConfig.edgeInset.right))
        }
        .onSelectSingle { index in
            guard let selectedItem = self.context.items[safe: index],
                let press = self.renderConfig.press
            else { return }
            self.context.executeAction(press, with: selectedItem)
        }
    }

    
    var body: some View {
        VStack(spacing: 0) {
            ASTableView(editMode: editMode, section: section)
                .separatorsEnabled(false)
                .scrollPositionSetter($scrollPosition)
                .alwaysBounce()
                .contentInsets(.init(top: renderConfig.edgeInset.top, left: 0, bottom: renderConfig.edgeInset.bottom, right: 0))
                .edgesIgnoringSafeArea(.all)
                .background(renderConfig.backgroundColor?.color ?? Color(.systemBackground))
            Divider()
            messageComposer
        }
        .modifier(KeyboardPaddingModifier())
    }
    
    @State private var isEditingComposedMessage: Bool = false
    @State private var composedMessage: String?
    
    var messageComposer: some View {
        HStack(spacing: 6) {
            MemriFittedTextEditor(contentBinding: $composedMessage, placeholder: "Type a message...", backgroundColor: ColorDefinition.system(.systemBackground), isEditing: $isEditingComposedMessage)
                
            Button(action: onPressSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(canSend ? .blue : Color(.systemFill))
                    .font(.system(size: 30))
            }
            .disabled(!canSend)
        }
        .padding(.vertical, 5)
        .padding(.leading, min(max(self.renderConfig.edgeInset.left, 5), 15)) // Follow user-defined insets where within a reasonable range
        .padding(.trailing, min(max(self.renderConfig.edgeInset.right, 5), 15)) // Follow user-defined insets where within a reasonable range
        .background(Color(.secondarySystemBackground))
    }
    
    var canSend: Bool {
        !(composedMessage?.isOnlyWhitespace ?? true)
    }
    
    func onPressSend() {
        #warning("@Ruben: we will need to decide how `sending` a message is handled")
        print(composedMessage ?? "Empty message")
        composedMessage = nil
        isEditingComposedMessage = false
    }
}

struct MessageBubbleView: View {
    var timestamp: Date?
    var sender: String?
    var content: String
    var outgoing: Bool
	var font: FontDefinition?

    var dateFormatter: DateFormatter {
        // TODO: If there is a user setting for a *short* date format, we should use that
        #warning("@Toby lets discuss this")
        let format = DateFormatter()
        format.dateStyle = .short
        format.timeStyle = .short
        format.doesRelativeDateFormatting = true
        return format
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if !outgoing {
                    sender.map {
                        Text($0)
                            .lineLimit(1)
                            .font(Font.body.bold())
                    }
                }
                timestamp.map {
                    Text(dateFormatter.string(from: $0))
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                MemriSmartTextView(string: content, detectLinks: true,
								   font: font ?? FontDefinition(size: 18),
								   color: outgoing ? ColorDefinition.system(.white) : ColorDefinition.system(.label),
								   maxLines: nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.all, 10)
                    .background(
                        outgoing ? Color.blue : Color(.secondarySystemBackground)
                    )
                    .mask(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: outgoing ? .trailing : .leading)
        .padding(outgoing ? .leading : .trailing, 20)
    }
}

struct MessageRenderer_Previews: PreviewProvider {
    static var previews: some View {
        MessageRenderer()
    }
}
