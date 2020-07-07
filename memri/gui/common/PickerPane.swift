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
	let datasource: Datasource

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
				datasource: self.datasource
			).environmentObject(self.context)
		}
		.generalEditorInput()
	}
}

struct PickerPane: View {
	@EnvironmentObject var context: MemriContext
	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

	let item: Item
	let title: String
	let propItem: Item
	let propName: String
	let selected: Item?
	let datasource: Datasource

	func getSessionView() -> SessionView {
		do {
			return try SessionView.fromCVUDefinition(
				stored: CVUStoredDefinition(value: ["definition": """
				    [view] {
				        title: "\(title)"

				        [renderer = list] {
				    try!                        press: [
				                link {
				                    arguments {
				                        subject: {{subject}}
				                        property: \(propName)
				                    }
				                }
				                closePopup
				            ]
				        }

				        [renderer = thumbnail] {
				            press: [
				                link {
				                    arguments {
				                        subject: {{subject}}
				                        property: \(propName)
				                    }
				                }
				                closePopup
				            ]
				        }
				    }
				"""]),
				userState: UserState([
					"selection": [["type": item.genericType, "uid": item.uid]],
				]),
				datasource: datasource
			)
		} catch {
			debugHistory.error("Subview: \(error)")
			return SessionView()
		}
	}

	var body: some View {
		self.context.closeStack.append {
			self.presentationMode.wrappedValue.dismiss()
		}

		// TODO: scroll selected into view? https://stackoverflow.com/questions/57121782/scroll-swiftui-list-to-new-selection
		return SubView(
			context: self.context,
			view: getSessionView(),
			dataItem: self.item,
			viewArguments: try! ViewArguments.fromDict(["showCloseButton": true, "subject": propItem])
		)
	}
}
