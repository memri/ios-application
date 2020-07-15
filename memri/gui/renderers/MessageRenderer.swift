//
//  MessageRenderer.swift
//  Memri
//
//  Created by Toby Brennan on 15/7/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import SwiftUI
import ASCollectionView

let registerMessageRenderer = {
	Renderers.register(
		name: "messages",
		title: "Messages",
		order: 0,
		icon: "message",
		view: AnyView(MessageRenderer()),
		renderConfigType: CascadingMessageRendererConfig.self,
		canDisplayResults: { _ -> Bool in true }
	)
}

class CascadingMessageRendererConfig: CascadingRenderConfig {
	var type: String? = "messages"
	
	var press: Action? { cascadeProperty("press") }
}

struct MessageRenderer: View {
	@EnvironmentObject var context: MemriContext
	var renderConfig: CascadingMessageRendererConfig {
		context.cascadingView?.renderConfig as? CascadingMessageRendererConfig ?? CascadingMessageRendererConfig()
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
		context.currentSession?.isEditMode ?? false
	}
    
    var dateFormatter: DateFormatter {
        let format = DateFormatter()
        format.dateStyle = .short
        format.timeStyle = .short
        format.doesRelativeDateFormatting = true
        return format
    }
    
    var messageItems: [MessageItem] {
		context.items.map { item in
            let sender = item.get("title", type: String.self)
            let date = item.get("dateModified", type: Date.self) ?? Date()
            return MessageItem(id: item.id.hashValue,
							   item: item,
                               timestamp: date,
							   sender: sender,
							   content: item.get("content", type: String.self)?.strippingHTMLtags() ?? "",
                               outgoing: sender == "To read list")
        }.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    var section: ASSection<Int> {
        ASSection<Int>(id: 0, data: messageItems, selectedItems: selectedItems) { item, cellContext in
            HStack {
                if item.outgoing {
                    Spacer(minLength: editMode ? 5 : 40)
                }
                VStack(alignment: .leading, spacing: 2) {
					if !item.outgoing {
						item.sender.map {
							Text($0)
								.lineLimit(1)
								.font(Font.body.bold())
						}
					}
					Text(dateFormatter.string(from: item.timestamp))
						.lineLimit(1)
						.font(.caption)
						.foregroundColor(Color(.secondaryLabel))
                    Text(item.content)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.all, 10)
                        .foregroundColor(
                            item.outgoing ? Color.white : Color(.label)
                        )
                        .background(
                            item.outgoing ? Color.blue : Color(.secondarySystemBackground)
                        )
                        .mask(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
                if !item.outgoing {
                    Spacer(minLength: editMode ? 5 : 40)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
        }
		.onSelectSingle { (index) in
			guard let selectedItem = self.messageItems[safe: index]?.item,
				  let press = self.renderConfig.press
			else { return }
			context.executeAction(press, with: selectedItem)
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
    
    struct MessageItem: Identifiable {
        var id: Int
		var item: Item
        var timestamp: Date
		var sender: String?
        var content: String
        var outgoing: Bool
    }
}

struct MessageRenderer_Previews: PreviewProvider {
    static var previews: some View {
        MessageRenderer()
    }
}
