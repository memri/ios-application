//
//  PickerPane.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

struct Picker: View {
	@EnvironmentObject var context: MemriContext

	let item: Item
	let selected: Item?
	let title: String
	let emptyValue: String
	let propItem: Item
	let propName: String
    let renderer: String?
	let query: String

	@State var isShowing = false

	var body: some View {
		Button(action: {
			self.isShowing.toggle()
        }) {
			HStack {
				Text(selected?.computedTitle ?? emptyValue)
					.generalEditorCaption()
					.lineLimit(1)
				Spacer()
				Image(systemName: "chevron.right")
					.font(.system(size: 14, weight: .bold))
					.foregroundColor(Color.gray)
			}
		}
		.sheet(isPresented: $isShowing) {
			PickerPane(
				item: self.item,
				title: self.title,
				propItem: self.propItem,
				propName: self.propName,
				selected: self.selected,
                renderer: self.renderer,
				query: self.query
			).environmentObject(self.context)
		}
		.generalEditorInput()
	}
}

// TODO this could be merged with subview in some way
struct PickerPane: View {
	@EnvironmentObject var context: MemriContext
	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

	let item: Item
	let title: String
	let propItem: Item
	let propName: String
	let selected: Item?
    let renderer: String?
	let query: String

	var body: some View {
		// TODO: scroll selected into view? https://stackoverflow.com/questions/57121782/scroll-swiftui-list-to-new-selection
		SubView(
			context: self.context,
			viewName: "choose-item-by-query",
			dataItem: self.item,
			viewArguments: ViewArguments([
                "showCloseButton": true,
                "subject": propItem,
                "renderer": renderer ?? "list",
                "edgeType": propName,
                "title": title,
                "distinct": true,
                "selection": [item],
                "query": query
            ])
		)
        .onAppear {
            self.context.addToStack(self.presentationMode)
        }
	}
}
