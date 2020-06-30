//
//  SubView.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

// TODO: Refactor: optimize this for performance
public struct SubView: View {
	@EnvironmentObject var context: MemriContext

	var proxyMain: MemriContext?
	var toolbar: Bool = true
	var searchbar: Bool = true
	var showCloseButton: Bool = false

	// There is duplication here becaue proxyMain cannot be set outside of init. This can be fixed
	// By only duplicating that line and setting session later, but I am too lazy to do that.
	// TODO: Refactor
	public init(context: MemriContext, viewName: String, dataItem: Item, args: ViewArguments) {
		toolbar = args.get("toolbar") ?? toolbar
		searchbar = args.get("searchbar") ?? searchbar
		showCloseButton = args.get("showCloseButton") ?? showCloseButton

		do {
			guard let context = context as? RootContext else {
				throw "Exception: Too much nesting"
			}

			let stored = context.views.fetchDefinitions(name: viewName, type: "view").first
			var parsed = try context.views.parseDefinition(stored)

			if parsed is CVUParsedSessionDefinition {
				if let list = parsed?["views"] as? [CVUParsedViewDefinition] { parsed = list.first }
			}

			args.set(".", dataItem)

			let view = try SessionView.fromCVUDefinition(
				parsed: parsed as? CVUParsedViewDefinition,
				stored: stored,
				viewArguments: args
			)

			let session = Session()
			session.views.append(view)
			session.currentViewIndex = 0

			proxyMain = context.createSubContext(session)
			do { try proxyMain?.updateCascadingView() }
			catch {
				// TODO: Refactor error handling
				throw "Cannot update CascadingView \(self): \(error)"
			}
		} catch {
			// TODO: Refactor: error handling
			print("Error: cannot init subview: \(error)")
			debugHistory.error("Error: cannot init subview: \(error)")
		}
	}

	public init(context: MemriContext, view: SessionView, dataItem: Item, args: ViewArguments) {
		toolbar = args.get("toolbar") ?? toolbar
		searchbar = args.get("searchbar") ?? searchbar
		showCloseButton = args.get("showCloseButton") ?? showCloseButton

		do {
			guard let context = context as? RootContext else {
				throw "Exception: Too much nesting"
			}

			args.set(".", dataItem)

			view.viewArguments = args

			let session = Session()
			session.views.append(view)
			session.currentViewIndex = 0

			proxyMain = context.createSubContext(session)
			try proxyMain?.updateCascadingView()
		} catch {
			// TODO: Refactor error handling
			print("Error: cannot init subview, failed to update CascadingView: \(error)")
			debugHistory.error("Error: cannot init subview, failed to update CascadingView: \(error)")
		}
	}

	// TODO: refactor: consider inserting Browser here and adding variables instead
	public var body: some View {
		//        ZStack {
		VStack(alignment: .center, spacing: 0) {
			if self.toolbar {
				TopNavigation(inSubView: true, showCloseButton: showCloseButton)
			}
			allRenderers?.allViews[self.proxyMain?.cascadingView.activeRenderer ?? "list"]
				.fullHeight()

			if self.searchbar {
				Search()
			}
		}
		.fullHeight()
		// NOTE: Allowed force unwrap
		.environmentObject(self.proxyMain!)

		//            ContextPane()
		//        }
	}
}
