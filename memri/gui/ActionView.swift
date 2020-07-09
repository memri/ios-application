//
//  Action.swift
//  memri
//
//  Created by Koen van der Veen on 30/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct ActionButton: View {
	@EnvironmentObject var context: MemriContext

	var action: Action?
    var item: Item? = nil

	// TODO: Refactor: can this be created more efficiently?
	var body: some View {
		VStack {
			if action != nil {
				getAction()
			} else {
				EmptyView()
			}
		}
	}

	func getAction() -> AnyView {
		let action = self.action ?? ActionNoop(context)

		// NOTE: Allowed force unwrappings (logic)
		switch action.getRenderAs(context.cascadingView?.viewArguments) {
		case .popup:
            return AnyView(ActionPopupButton(action: action, item: item))
		case .button:
			return AnyView(ActionButtonView(action: action) {
				self.context.executeAction(action)
            })
		default:
			return AnyView(ActionButtonView(action: action))
		}
	}
}

struct ActionView_Previews: PreviewProvider {
	static var previews: some View {
		let context = try! RootContext(name: "", key: "").mockBoot()
		return ActionButton(action: ActionBack(context))
			.environmentObject(context)
	}
}

struct ActionButtonView: View {
	@EnvironmentObject var context: MemriContext

	var action: Action
	var execute: (() -> Void)? = nil

	var body: some View {
		let icon = action.getString("icon")
		let title: String? = action.get("title")

		return Button(action: {
			withAnimation {
				self.execute?()
			}
        }) {
			if icon != "" || title == nil {
                Image(systemName: icon == "" ? "exclamationmark.triangle" : icon)
					.fixedSize()
					.padding(.horizontal, 5)
					.padding(.vertical, 5)
					.foregroundColor(action.color)
					.background(action.backgroundColor)
				//                    .border(Color.red, width: 1)
			}

			if title != nil && (icon == "" || action.getBool("showTitle")) {
				// NOTE: Allowed force unwrapping (logic)
				Text(title ?? "")
					.font(.subheadline)
					.foregroundColor(.black)
			}
		}
	}
}

struct ActionPopupButton: View {
	@EnvironmentObject var context: MemriContext

	var action: Action
    var item: Item? = nil

	@State var isShowing = false

	var body: some View {
		ActionButtonView(action: self.action, execute: {
			self.isShowing = true
        })
        .sheet(isPresented: $isShowing) {
            ActionPopup(action: self.action, item: self.item).environmentObject(self.context)
        }
	}
}

struct ActionPopup: View {
	@EnvironmentObject var context: MemriContext
	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

	var action: Action
    var item: Item? = nil

	var body: some View {
		// TODO: refactor: this list item needs to be removed when we close the popup in any way
		self.context.closeStack.append {
			self.presentationMode.wrappedValue.dismiss()
		}

        let viewArguments = action.arguments["viewArguments"] as? ViewArguments
        let args = try! ViewArguments.clone(viewArguments, item: item)

		args.set("showCloseButton", true)

		// TODO: is this still needed? Need test cases
		// TODO: this is now set back on variables["."] there is something wrong in the architecture
		//      that is causing this
//		let dataItem = args.get(".") ?? Item() // TODO: Refactor: Error handling

		// TODO: scroll selected into view? https://stackoverflow.com/questions/57121782/scroll-swiftui-list-to-new-selection
		if action.name == .openView {
			if let view = action.arguments["view"] as? SessionView {
				return SubView(
					context: self.context,
					view: view, // TODO: refactor: consider adding .closePopup to all press actions
					dataItem: item,
					viewArguments: args
				)
			} else {
				// TODO: ERror logging
			}
		} else if action.name == .openViewByName {
			if let viewName = action.arguments["name"] as? String {
				return SubView(
					context: self.context,
					viewName: viewName,
					dataItem: item,
					viewArguments: args
				)
			} else {
				// TODO: Error logging
			}
		}

		// We should never get here. This is just to ease the compiler
		return SubView(
			context: self.context,
			viewName: "catch-all-view",
			dataItem: item,
			viewArguments: args
		)
	}
}
