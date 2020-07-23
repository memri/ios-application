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
        ASSection<Int>(id: 0, data: context.items, selectedItems: selectedItems) { item, _ in
            self.renderConfig.render(item: item)
                .environmentObject(self.context)
        }
        .onSelectSingle { index in
            guard let selectedItem = self.context.items[safe: index],
                let press = self.renderConfig.press
            else { return }
            self.context.executeAction(press, with: selectedItem)
        }
    }

    var body: some View {
        ASTableView(editMode: editMode, section: section)
            .separatorsEnabled(false)
            .scrollPositionSetter($scrollPosition)
            .alwaysBounce()
            .contentInsets(.init(top: 5, left: 0, bottom: 5, right: 0))
            .edgesIgnoringSafeArea(.all)
    }
}

struct MessageBubbleView: View {
    var timestamp: Date?
    var sender: String?
    var content: String
    var outgoing: Bool

    var dateFormatter: DateFormatter {
        // TODO: If there is a user setting for a *short* date format, we should use that
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
                Text(content)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.all, 10)
                    .foregroundColor(
                        outgoing ? Color.white : Color(.label)
                    )
                    .background(
                        outgoing ? Color.blue : Color(.secondarySystemBackground)
                    )
                    .mask(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: outgoing ? .trailing : .leading)
        .padding(outgoing ? .leading : .trailing, 20)
    }
}

struct MessageRenderer_Previews: PreviewProvider {
    static var previews: some View {
        MessageRenderer()
    }
}
